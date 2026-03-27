# AI Integration Documentation

This document provides comprehensive details about the AI integration in the productivity application, including Gemini API usage, function calling, prompt engineering, and AI response handling.

## Table of Contents

1. [AI Architecture Overview](#ai-architecture-overview)
2. [Gemini API Integration](#gemini-api-integration)
3. [Function Calling Implementation](#function-calling-implementation)
4. [Prompt Engineering](#prompt-engineering)
5. [Context Management](#context-management)
6. [Response Processing](#response-processing)
7. [Error Handling](#error-handling)
8. [Performance Optimization](#performance-optimization)
9. [Security Considerations](#security-considerations)

## AI Architecture Overview

### AI Integration Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   User Input    │  │   Timer Prompts │  │   Reminders     │  │
│  │                 │  │                 │  │                 │  │
│  │ - Chat Messages │  │ - Scheduled     │  │ - AI Prompts    │  │
│  │ - Voice Input   │  │ - Recurring     │  │ - Function Calls│  │
│  │ - Text Input    │  │ - Contextual    │  │ - Responses     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│                    Service Layer                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   AI Service    │  │   Context Mgmt  │  │   Response Proc │  │
│  │                 │  │                 │  │                 │  │
│  │ - API Calls     │  │ - User Data     │  │ - Function Call │  │
│  │ - Error Handling│  │ - Preferences   │  │ - Data Updates  │  │
│  │ - Rate Limiting │  │ - History       │  │ - Validation    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│                    External AI Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Gemini API    │  │   Function Call │  │   Context Mgmt  │  │
│  │                 │  │                 │  │                 │  │
│  │ - LLM Model     │  │ - Tool Calls    │  │ - Memory        │  │
│  │ - Generation    │  │ - Validation    │  │ - Personalization│  │
│  │ - Safety Filters│  │ - Execution     │  │ - Learning      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### AI Integration Points

1. **Chat Interface**: Direct user-AI conversations
2. **Timer Prompts**: Scheduled AI interactions
3. **Smart Reminders**: AI-driven reminder responses
4. **Contextual Suggestions**: AI-powered task and goal suggestions
5. **Automated Actions**: AI-triggered data modifications

## Gemini API Integration

### API Configuration

```dart
class SupabaseGeminiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Ensure we have a valid session with fresh tokens
  static Future<void> _ensureValidSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('No active session');
    }

    try {
      final refreshed = await _supabase.auth.refreshSession();
      if (refreshed.session == null) {
        throw Exception('Session refresh failed - no session returned');
      }
    } catch (e) {
      print('[GeminiService] Session refresh failed: $e');
      throw Exception('Session expired. Please sign in again.');
    }
  }
}
```

### API Call Implementation

```dart
/// Send a chat message to the Supabase Gemini Edge Function
static Future<String> sendChatMessage(
  String userId,
  String message, {
  List<Chat>? chatHistory,
  int maxRetries = 5
}) async {
  int attempt = 0;
  int retryDelay = 1000; // Start with 1 second delay

  while (attempt <= maxRetries) {
    try {
      // Ensure valid session
      if (attempt == 0) {
        await _ensureValidSession();
      }

      // Verify user authentication
      final user = await _supabase.auth.getUser();
      if (user.user == null) {
        throw Exception('User not authenticated');
      }

      // Convert chat history to expected format
      final history = chatHistory?.map((chat) {
        return {
          'role': chat.isUser ? 'user' : 'model',
          'content': chat.text
        };
      }).toList();

      // Make API call with timeout
      final response = await _supabase.functions.invoke(
        'process-prompt',
        body: {
          'userInput': message,
          'chatHistory': history,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['response'] as String? ?? 'No response from AI';
      } else if (response.status == 401 && attempt < maxRetries) {
        // Auth error - refresh session and retry
        try {
          await _supabase.auth.refreshSession();
        } catch (e) {
          throw Exception('Authentication failed. Please sign in again.');
        }
        attempt++;
        await Future.delayed(Duration(milliseconds: retryDelay));
        retryDelay = min(retryDelay * 2, 15000); // Exponential backoff
        continue;
      } else if (response.status >= 400 && response.status < 600) {
        if (response.status >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Request error: ${response.status}');
        }
      } else {
        throw Exception('Unexpected response: ${response.status}');
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      // Check for retryable network errors
      final isRetryableError = errorMessage.contains('timeout') ||
                              errorMessage.contains('connection') ||
                              errorMessage.contains('network') ||
                              errorMessage.contains('socket') ||
                              errorMessage.contains('dns') ||
                              errorMessage.contains('internet') ||
                              errorMessage.contains('failed host lookup') ||
                              errorMessage.contains('connection refused') ||
                              errorMessage.contains('connection reset') ||
                              errorMessage.contains('connection closed');

      if (isRetryableError && attempt < maxRetries) {
        print('[GeminiService] Retrying network error (attempt ${attempt + 1}/$maxRetries)');
        attempt++;
        await Future.delayed(Duration(milliseconds: retryDelay));
        retryDelay = min(retryDelay * 2, 15000);
        continue;
      } else {
        // Handle specific error types
        if (errorMessage.contains('session') || errorMessage.contains('auth') ||
            errorMessage.contains('jwt') || errorMessage.contains('unauthorized')) {
          throw Exception('Session expired. Please sign in again.');
        } else if (isRetryableError) {
          throw Exception('Network connection issue. Please check your internet connection and try again.');
        } else if (errorMessage.contains('timeout')) {
          throw Exception('Request timed out. Please try again.');
        } else if (errorMessage.contains('server error') || errorMessage.contains('internal server')) {
          throw Exception('Server temporarily unavailable. Please try again later.');
        } else if (errorMessage.contains('json') || errorMessage.contains('parsing') ||
                   errorMessage.contains('format')) {
          throw Exception('Data processing error. Please try again.');
        } else if (errorMessage.contains('rate limit') || errorMessage.contains('quota')) {
          throw Exception('Service temporarily busy. Please wait a moment and try again.');
        } else {
          throw Exception('An unexpected error occurred: ${e.toString()}. Please try again.');
        }
      }
    }
  }

  throw Exception('Network connection issue. Please check your internet connection and try again.');
}
```

## Function Calling Implementation

### Function Definition Structure

```typescript
// Supabase Edge Function - Function Definitions
const todoTool = {
  functionDeclarations: [{
    name: 'addTodo',
    description: 'Adds a new to-do item. IMPORTANT and URGENCY are different! importance=how valuable, urgency=how time-sensitive.',
    parameters: {
      type: 'object',
      properties: {
        task: { type: 'string', description: 'The task to be done.' },
        importance: { type: 'string', description: 'How valuable/meaningful: IMPORTANT or NOT IMPORTANT', enum: ['IMPORTANT','NOT IMPORTANT'] },
        urgency: { type: 'string', description: 'How time-sensitive: URGENT or NOT URGENT', enum: ['URGENT', 'NOT URGENT'] },
        description: { type: 'string', description: 'Task description.' },
        dueDate: { type: 'string', description: 'Due date in ISO format.' },
        isCompleted: { type: 'boolean', description: 'Whether the task is completed.' }
      },
      required: ['task', 'importance', 'urgency']
    }
  }, {
    name: 'deleteTodo',
    description: 'Deletes a to-do item.',
    parameters: {
      type: 'object',
      properties: {
        taskId: { type: 'string', description: 'The ID of the task to delete.' }
      },
      required: ['taskId']
    }
  }, {
    name: 'modifyTodo',
    description: 'Modifies a to-do item. IMPORTANT and URGENCY are different!',
    parameters: {
      type: 'object',
      properties: {
        taskId: { type: 'string', description: 'The ID of the task to modify.' },
        newTask: { type: 'string', description: 'The updated task.' },
        newImportance: { type: 'string', description: 'IMPORTANT or NOT IMPORTANT', enum: ['IMPORTANT','NOT IMPORTANT'] },
        newUrgency: { type: 'string', description: 'URGENT or NOT URGENT', enum: ['URGENT', 'NOT URGENT'] },
        newDescription: { type: 'string' },
        newDueDate: { type: 'string' },
        newIsCompleted: { type: 'boolean' }
      },
      required: ['taskId', 'newTask']
    }
  }]
};
```

### Function Call Processing

```dart
class AIResponseProcessor {
  final TodoSyncService todoService;
  final GoalSyncService goalService;
  final TimerPromptSyncService timerPromptService;
  final ReminderSyncService reminderService;

  AIResponseProcessor({
    required this.todoService,
    required this.goalService,
    required this.timerPromptService,
    required this.reminderService,
  });

  Future<void> processFunctionCall(FunctionCall call) async {
    switch (call.name) {
      case 'addTodo':
        await processAddTodo(call.args);
        break;
      case 'deleteTodo':
        await processDeleteTodo(call.args);
        break;
      case 'modifyTodo':
        await processModifyTodo(call.args);
        break;
      case 'addGoal':
        await processAddGoal(call.args);
        break;
      case 'deleteGoal':
        await processDeleteGoal(call.args);
        break;
      case 'modifyGoal':
        await processModifyGoal(call.args);
        break;
      case 'addTimerPrompt':
        await processAddTimerPrompt(call.args);
        break;
      case 'deleteTimerPrompt':
        await processDeleteTimerPrompt(call.args);
        break;
      case 'modifyTimerPrompt':
        await processModifyTimerPrompt(call.args);
        break;
      case 'addReminder':
        await processAddReminder(call.args);
        break;
      case 'deleteReminder':
        await processDeleteReminder(call.args);
        break;
      case 'modifyReminder':
        await processModifyReminder(call.args);
        break;
      default:
        throw Exception('Unknown function: ${call.name}');
    }
  }

  Future<void> processAddTodo(Map<String, dynamic> args) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskName: args['task'] ?? 'Untitled Task',
      importance: args['importance'] ?? 'NOT IMPORTANT',
      urgency: args['urgency'] ?? 'NOT URGENT',
      description: args['description'] ?? '',
      dueDate: args['dueDate'] != null ? DateTime.parse(args['dueDate']) : null,
      isCompleted: args['isCompleted'] ?? false,
    );

    await todoService.createTodo(todo);
  }

  Future<void> processDeleteTodo(Map<String, dynamic> args) async {
    final taskId = args['taskId'] as String;
    await todoService.deleteTodo(taskId);
  }

  Future<void> processModifyTodo(Map<String, dynamic> args) async {
    final taskId = args['taskId'] as String;
    final updatedTodo = Todo(
      id: taskId,
      taskName: args['newTask'] ?? '',
      importance: args['newImportance'] ?? 'NOT IMPORTANT',
      urgency: args['newUrgency'] ?? 'NOT URGENT',
      description: args['newDescription'],
      dueDate: args['newDueDate'] != null ? DateTime.parse(args['newDueDate']) : null,
      isCompleted: args['newIsCompleted'] ?? false,
    );

    await todoService.updateTodo(taskId, updatedTodo);
  }

  // Similar methods for other function types...
}
```

### Function Call Validation

```dart
class FunctionCallValidator {
  static bool validateTodoFunction(FunctionCall call) {
    switch (call.name) {
      case 'addTodo':
        return validateAddTodoArgs(call.args);
      case 'deleteTodo':
        return validateDeleteTodoArgs(call.args);
      case 'modifyTodo':
        return validateModifyTodoArgs(call.args);
      default:
        return false;
    }
  }

  static bool validateAddTodoArgs(Map<String, dynamic> args) {
    final task = args['task'] as String?;
    final importance = args['importance'] as String?;
    final urgency = args['urgency'] as String?;

    return task != null && task.isNotEmpty &&
           importance != null && ['IMPORTANT', 'NOT IMPORTANT'].contains(importance) &&
           urgency != null && ['URGENT', 'NOT URGENT'].contains(urgency);
  }

  static bool validateDeleteTodoArgs(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String?;
    return taskId != null && taskId.isNotEmpty;
  }

  static bool validateModifyTodoArgs(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String?;
    final newTask = args['newTask'] as String?;

    return taskId != null && taskId.isNotEmpty &&
           newTask != null && newTask.isNotEmpty;
  }
}
```

## Prompt Engineering

### System Prompt Structure

```dart
class PromptBuilder {
  /// Build system prompt with user context
  static String buildSystemPrompt(UserData userData) {
    final todoSummary = summarizeTodos(userData.todos);
    final goalsSummary = summarizeGoals(userData.goals);
    final personalitySummary = summarizePersonality(userData.personality);
    final additionalInfoSummary = summarizeAdditionalInfo(userData.additionalInfo);

    return '''
You are a personal productivity assistant for a user who wants to optimize their daily routine and achieve their goals. Your responses should be helpful, concise, and actionable.

User Context:
- User's todos: $todoSummary
- User's goals: $goalsSummary
- User's personality traits: $personalitySummary
- User's additional information: $additionalInfoSummary

Guidelines:
1. Always consider the user's current workload and priorities
2. Suggest realistic and achievable actions
3. Use the Eisenhower Matrix (IMPORTANT/URGENCY) for task classification
4. Provide specific, actionable recommendations
5. Adapt your communication style to the user's personality traits
6. Respect the user's time and energy levels
7. Focus on high-impact activities that align with their goals

Response Format:
- Keep responses concise (2-3 sentences maximum)
- Use clear, direct language
- Provide specific recommendations when applicable
- Ask clarifying questions only when necessary for providing better assistance

Available Actions:
- Add, modify, or delete todos
- Add, modify, or delete goals
- Add, modify, or delete timer prompts
- Add, modify, or delete reminders
- Provide productivity suggestions
- Analyze task prioritization
- Suggest goal breakdowns
- Recommend habit improvements
''';
  }

  static String summarizeTodos(List<Todo> todos) {
    if (todos.isEmpty) return 'No current todos';
    
    final importantUrgent = todos.where((t) => t.importance == 'IMPORTANT' && t.urgency == 'URGENT').length;
    final importantNotUrgent = todos.where((t) => t.importance == 'IMPORTANT' && t.urgency == 'NOT URGENT').length;
    final notImportantUrgent = todos.where((t) => t.importance == 'NOT IMPORTANT' && t.urgency == 'URGENT').length;
    final notImportantNotUrgent = todos.where((t) => t.importance == 'NOT IMPORTANT' && t.urgency == 'NOT URGENT').length;
    
    return '''
    Total: ${todos.length} todos
    - Important & Urgent: $importantUrgent
    - Important & Not Urgent: $importantNotUrgent
    - Not Important & Urgent: $notImportantUrgent
    - Not Important & Not Urgent: $notImportantNotUrgent
    ''';
  }

  static String summarizeGoals(List<Goal> goals) {
    if (goals.isEmpty) return 'No current goals';
    
    return goals.map((g) => '- ${g.title} (${g.isCompleted ? 'Completed' : 'In Progress'})').join('\n');
  }

  static String summarizePersonality(List<PersonalityTrait> traits) {
    if (traits.isEmpty) return 'No personality traits defined';
    
    return traits.map((t) => '- ${t.trait}').join('\n');
  }

  static String summarizeAdditionalInfo(List<AdditionalInfo> info) {
    if (info.isEmpty) return 'No additional information';
    
    return info.map((i) => '- ${i.info}').join('\n');
  }
}
```

### Dynamic Prompt Generation

```dart
class DynamicPromptGenerator {
  /// Generate context-aware prompts based on time and user state
  static String generateMorningPrompt(UserData userData) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final timeOfDay = now.hour < 12 ? 'morning' : now.hour < 17 ? 'afternoon' : 'evening';
    
    return '''
It's $dayOfWeek $timeOfDay. Review your priorities for today:

Current State:
- Active todos: ${userData.todos.where((t) => !t.isCompleted).length}
- Urgent tasks: ${userData.todos.where((t) => t.urgency == 'URGENT' && !t.isCompleted).length}
- Goals in progress: ${userData.goals.where((g) => !g.isCompleted).length}

What would you like to focus on today? Consider:
1. Most important tasks that need attention
2. Progress toward your goals
3. Energy levels and time available
4. Any new priorities or changes
''';
  }

  /// Generate end-of-day reflection prompt
  static String generateEveningPrompt(UserData userData) {
    final completedToday = userData.todos.where((t) => t.isCompleted && 
      t.updatedAt?.day == DateTime.now().day).length;
    
    return '''
Time to reflect on your day:

Today's Accomplishments:
- Completed tasks: $completedToday
- Progress on goals: ${userData.goals.where((g) => g.updatedAt?.day == DateTime.now().day).length}

Reflection Questions:
1. What went well today?
2. What could have been done better?
3. Are there any unfinished tasks that need attention tomorrow?
4. How do you feel about your progress toward your goals?

Based on your answers, I can help you:
- Adjust tomorrow's priorities
- Modify your goals or tasks
- Suggest improvements to your routine
''';
  }

  /// Generate goal-specific prompts
  static String generateGoalProgressPrompt(Goal goal, List<GoalStep> steps) {
    final completedSteps = steps.where((s) => s.isCompleted).length;
    final totalSteps = steps.length;
    final progress = totalSteps > 0 ? (completedSteps / totalSteps * 100).round() : 0;
    
    return '''
Goal: ${goal.title}
Progress: $progress% ($completedSteps/$totalSteps steps completed)

Current Status:
${goal.description}

Recent Activity:
${steps.map((s) => '- ${s.stepText} ${s.isCompleted ? '✓' : '○'}').join('\n')}

What would you like to focus on next?
1. Complete remaining steps
2. Add new steps to the goal
3. Modify the goal or timeline
4. Review overall progress and adjust strategy
''';
  }
}
```

## Context Management

### Context Building

```dart
class ContextManager {
  final UserDataRepository userDataRepository;
  final ChatHistoryRepository chatHistoryRepository;

  ContextManager({
    required this.userDataRepository,
    required this.chatHistoryRepository,
  });

  /// Build comprehensive context for AI interactions
  Future<AIContext> buildContext(String userId) async {
    final userData = await userDataRepository.getUserData(userId);
    final recentChats = await chatHistoryRepository.getRecentChats(userId, limit: 10);
    final currentDateTime = DateTime.now();

    return AIContext(
      userData: userData,
      chatHistory: recentChats,
      currentDateTime: currentDateTime,
      contextSummary: buildContextSummary(userData, currentDateTime),
    );
  }

  String buildContextSummary(UserData userData, DateTime currentDateTime) {
    final todoSummary = buildTodoSummary(userData.todos);
    final goalSummary = buildGoalSummary(userData.goals);
    final habitSummary = buildHabitSummary(userData.habits);
    final timeContext = buildTimeContext(currentDateTime);

    return '''
User Context Summary:
$todoSummary
$goalSummary
$habitSummary
$timeContext

Key Insights:
- User has ${userData.todos.length} total todos
- ${userData.goals.length} active goals
- ${userData.personality.length} defined personality traits
- Last interaction: ${userData.lastInteraction?.toIso8601String() ?? 'Unknown'}
''';
  }

  String buildTodoSummary(List<Todo> todos) {
    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final urgent = todos.where((t) => t.urgency == 'URGENT').length;
    final important = todos.where((t) => t.importance == 'IMPORTANT').length;

    return '''
Todos: $completed/$total completed
- Urgent tasks: $urgent
- Important tasks: $important
- Eisenhower Matrix distribution available
''';
  }

  String buildGoalSummary(List<Goal> goals) {
    final total = goals.length;
    final completed = goals.where((g) => g.isCompleted).length;
    final inProgress = goals.where((g) => !g.isCompleted).length;

    return '''
Goals: $completed/$total completed
- In progress: $inProgress
- Completed: $completed
- Average goal completion rate: ${total > 0 ? ((completed / total) * 100).round() : 0}%
''';
  }

  String buildHabitSummary(List<Habit> habits) {
    if (habits.isEmpty) return 'No habits tracked';

    final active = habits.where((h) => h.isActive).length;
    final streak = habits.fold(0, (sum, h) => sum + h.currentStreak);

    return '''
Habits: $active active habits
- Total streak days: $streak
- Average habit consistency: ${habits.isNotEmpty ? (habits.map((h) => h.consistency).reduce((a, b) => a + b) / habits.length).round() : 0}%
''';
  }

  String buildTimeContext(DateTime currentDateTime) {
    final dayOfWeek = DateFormat('EEEE').format(currentDateTime);
    final timeOfDay = currentDateTime.hour < 12 ? 'morning' : 
                      currentDateTime.hour < 17 ? 'afternoon' : 'evening';
    final isWeekend = currentDateTime.weekday >= 6;

    return '''
Time Context:
- Day: $dayOfWeek
- Time of day: $timeOfDay
- Weekend: ${isWeekend ? 'Yes' : 'No'}
- Hour: ${currentDateTime.hour}:00
''';
  }
}
```

### Context Caching

```dart
class ContextCache {
  static const _cacheDuration = Duration(minutes: 5);
  final Map<String, _CachedContext> _cache = {};

  Future<AIContext> getContext(String userId) async {
    final cached = _cache[userId];
    
    if (cached != null && cached.timestamp.isAfter(DateTime.now().subtract(_cacheDuration))) {
      return cached.context;
    }

    // Context expired or not found, rebuild
    final contextManager = ContextManager(
      userDataRepository: UserDataRepository(),
      chatHistoryRepository: ChatHistoryRepository(),
    );
    
    final context = await contextManager.buildContext(userId);
    _cache[userId] = _CachedContext(context, DateTime.now());
    
    return context;
  }

  void invalidateContext(String userId) {
    _cache.remove(userId);
  }

  void clearCache() {
    _cache.clear();
  }
}

class _CachedContext {
  final AIContext context;
  final DateTime timestamp;

  _CachedContext(this.context, this.timestamp);
}
```

## Response Processing

### Response Parsing

```dart
class AIResponseParser {
  /// Parse AI response and extract structured information
  static AIResponse parseResponse(String responseText) {
    final lines = responseText.split('\n');
    final actions = <Action>[];
    final insights = <Insight>[];
    final suggestions = <Suggestion>[];

    for (final line in lines) {
      if (line.contains('I added') || line.contains('I created')) {
        actions.add(parseAction(line));
      } else if (line.contains('Based on') || line.contains('Considering')) {
        insights.add(parseInsight(line));
      } else if (line.contains('Consider') || line.contains('Try') || line.contains('You should')) {
        suggestions.add(parseSuggestion(line));
      }
    }

    return AIResponse(
      originalText: responseText,
      actions: actions,
      insights: insights,
      suggestions: suggestions,
      summary: generateSummary(responseText),
    );
  }

  static Action parseAction(String line) {
    // Extract action type and details from text
    if (line.contains('added a todo')) {
      return Action(type: ActionType.addTodo, description: line);
    } else if (line.contains('created a goal')) {
      return Action(type: ActionType.addGoal, description: line);
    } else if (line.contains('scheduled a reminder')) {
      return Action(type: ActionType.addReminder, description: line);
    }
    
    return Action(type: ActionType.unknown, description: line);
  }

  static Insight parseInsight(String line) {
    return Insight(
      category: InsightCategory.behavioral,
      description: line,
      confidence: 0.8,
    );
  }

  static Suggestion parseSuggestion(String line) {
    return Suggestion(
      type: SuggestionType.productivity,
      description: line,
      priority: SuggestionPriority.medium,
    );
  }

  static String generateSummary(String responseText) {
    // Generate a concise summary of the response
    final sentences = responseText.split('. ');
    if (sentences.length > 3) {
      return sentences.take(3).join('. ') + '...';
    }
    return responseText;
  }
}
```

### Response Validation

```dart
class ResponseValidator {
  /// Validate AI response for safety and appropriateness
  static bool isValidResponse(String response) {
    // Check for profanity
    if (containsProfanity(response)) {
      return false;
    }

    // Check for harmful content
    if (containsHarmfulContent(response)) {
      return false;
    }

    // Check for personal data leakage
    if (containsPersonalDataLeakage(response)) {
      return false;
    }

    // Check response length
    if (response.length > 5000) {
      return false;
    }

    return true;
  }

  static bool containsProfanity(String text) {
    final profanityList = [
      'badword1', 'badword2', // Add actual profanity detection
    ];
    
    return profanityList.any((word) => text.toLowerCase().contains(word));
  }

  static bool containsHarmfulContent(String text) {
    final harmfulPatterns = [
      RegExp(r'self-harm', caseSensitive: false),
      RegExp(r'suicide', caseSensitive: false),
      RegExp(r'violence', caseSensitive: false),
    ];
    
    return harmfulPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool containsPersonalDataLeakage(String text) {
    // Check for potential PII leakage
    final emailPattern = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    
    return emailPattern.hasMatch(text) || phonePattern.hasMatch(text);
  }
}
```

## Error Handling

### AI Service Error Handling

```dart
class AIServiceErrorHandler {
  /// Handle different types of AI service errors
  static AIError handleServiceError(Object error, StackTrace stack) {
    if (error is TimeoutException) {
      return AIError(
        type: AIErrorType.timeout,
        message: 'The AI service is taking too long to respond. Please try again.',
        retryable: true,
        suggestedAction: 'Wait a moment and try again',
      );
    } else if (error is NetworkException) {
      return AIError(
        type: AIErrorType.network,
        message: 'Unable to connect to the AI service. Please check your internet connection.',
        retryable: true,
        suggestedAction: 'Check your internet connection and try again',
      );
    } else if (error is AuthException) {
      return AIError(
        type: AIErrorType.authentication,
        message: 'Authentication failed. Please sign in again.',
        retryable: false,
        suggestedAction: 'Sign out and sign back in',
      );
    } else if (error is RateLimitException) {
      return AIError(
        type: AIErrorType.rateLimit,
        message: 'You have exceeded the AI service usage limit. Please try again later.',
        retryable: true,
        suggestedAction: 'Wait a few minutes and try again',
      );
    } else if (error is InvalidInputException) {
      return AIError(
        type: AIErrorType.invalidInput,
        message: 'The input provided is not valid. Please check your input and try again.',
        retryable: false,
        suggestedAction: 'Review and correct your input',
      );
    } else {
      return AIError(
        type: AIErrorType.unknown,
        message: 'An unexpected error occurred. Please try again.',
        retryable: true,
        suggestedAction: 'Try again or contact support',
      );
    }
  }

  /// Log AI errors for monitoring and debugging
  static void logError(AIError error, String userId, String context) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'errorType': error.type.toString(),
      'errorMessage': error.message,
      'context': context,
      'retryable': error.retryable,
      'suggestedAction': error.suggestedAction,
    };

    // Log to console
    print('[AI Error] $logEntry');

    // Log to monitoring service (e.g., Firebase Crashlytics)
    // FirebaseCrashlytics.recordError(error, stack, reason: context);
  }
}
```

### Fallback Strategies

```dart
class AIFallbackStrategy {
  /// Provide fallback responses when AI service is unavailable
  static String getFallbackResponse(AIError error, String originalInput) {
    switch (error.type) {
      case AIErrorType.timeout:
        return '''
I'm currently experiencing high demand and couldn't process your request in time. 

In the meantime, here are some general suggestions:
- Review your current todos and prioritize based on importance and urgency
- Check your goals and identify any immediate steps you can take
- Consider scheduling a reminder for important tasks

Please try again in a moment.
''';

      case AIErrorType.network:
        return '''
I'm unable to connect to the AI service right now. 

Here are some offline productivity tips:
- Use the Eisenhower Matrix to prioritize your tasks
- Break large goals into smaller, actionable steps
- Set specific, measurable objectives for each task

Try again when you have a stable internet connection.
''';

      case AIErrorType.authentication:
        return '''
Authentication is required to access the AI assistant.

Please sign in to continue using the AI features. Once authenticated, you'll be able to:
- Get personalized productivity suggestions
- Have conversations with your AI assistant
- Receive context-aware recommendations

If you continue to experience authentication issues, please contact support.
''';

      case AIErrorType.rateLimit:
        return '''
You've reached the usage limit for the AI assistant.

Don't worry, you can still use all the regular features:
- Add and manage todos
- Track your goals
- Set reminders
- Review your progress

The AI features will be available again shortly. In the meantime, consider reviewing your current tasks and priorities.
''';

      case AIErrorType.invalidInput:
        return '''
I couldn't understand your input. 

Here are some examples of what you can ask me:
- "Help me prioritize my todos"
- "Suggest ways to improve my productivity"
- "Review my progress on goals"
- "Create a reminder for an important task"

Please try rephrasing your request.
''';

      default:
        return '''
I'm experiencing technical difficulties at the moment.

You can still use the app's core features:
- Manage your todos and goals
- Set reminders and timers
- Track your progress
- Review your productivity metrics

The AI assistant should be back online shortly. Thank you for your patience.
''';
    }
  }
}
```

## Performance Optimization

### Response Caching

```dart
class AIResponseCache {
  static const _cacheDuration = Duration(minutes: 10);
  final Map<String, _CachedResponse> _cache = {};

  /// Cache AI responses to avoid redundant API calls
  Future<String> getCachedResponse(String prompt, String userId) async {
    final cacheKey = _generateCacheKey(prompt, userId);
    final cached = _cache[cacheKey];

    if (cached != null && cached.timestamp.isAfter(DateTime.now().subtract(_cacheDuration))) {
      return cached.response;
    }

    return null;
  }

  /// Store AI response in cache
  void cacheResponse(String prompt, String userId, String response) {
    final cacheKey = _generateCacheKey(prompt, userId);
    _cache[cacheKey] = _CachedResponse(response, DateTime.now());
  }

  String _generateCacheKey(String prompt, String userId) {
    final promptHash = prompt.hashCode;
    return '$userId:$promptHash';
  }

  /// Clear expired cache entries
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => 
      value.timestamp.isBefore(now.subtract(_cacheDuration))
    );
  }
}

class _CachedResponse {
  final String response;
  final DateTime timestamp;

  _CachedResponse(this.response, this.timestamp);
}
```

### Request Optimization

```dart
class AIRequestOptimizer {
  static const _maxConcurrentRequests = 3;
  static const _requestTimeout = Duration(seconds: 30);
  static const _retryDelay = Duration(seconds: 2);

  final Queue<_PendingRequest> _requestQueue = Queue();
  final Set<String> _activeRequests = {};

  /// Queue and optimize AI requests
  Future<String> queueRequest(String userId, String prompt, {String? context}) async {
    final request = _PendingRequest(
      userId: userId,
      prompt: prompt,
      context: context,
      completer: Completer<String>(),
    );

    _requestQueue.addLast(request);

    // Process queue if not at capacity
    if (_activeRequests.length < _maxConcurrentRequests) {
      _processQueue();
    }

    return request.completer.future;
  }

  void _processQueue() {
    while (_requestQueue.isNotEmpty && _activeRequests.length < _maxConcurrentRequests) {
      final request = _requestQueue.removeFirst();
      _activeRequests.add(request.userId);

      _executeRequest(request).then((response) {
        request.completer.complete(response);
      }).catchError((error) {
        request.completer.completeError(error);
      }).whenComplete(() {
        _activeRequests.remove(request.userId);
        _processQueue();
      });
    }
  }

  Future<String> _executeRequest(_PendingRequest request) async {
    try {
      return await SupabaseGeminiService.sendChatMessage(
        request.userId,
        request.prompt,
        chatHistory: request.context != null ? [Chat(text: request.context!, isUser: true)] : null,
      ).timeout(_requestTimeout);
    } on TimeoutException {
      // Retry once on timeout
      await Future.delayed(_retryDelay);
      return await SupabaseGeminiService.sendChatMessage(
        request.userId,
        request.prompt,
      );
    }
  }
}

class _PendingRequest {
  final String userId;
  final String prompt;
  final String? context;
  final Completer<String> completer;

  _PendingRequest({
    required this.userId,
    required this.prompt,
    this.context,
    required this.completer,
  });
}
```

## Security Considerations

### Input Sanitization

```dart
class AISecurityValidator {
  /// Sanitize user input before sending to AI
  static String sanitizeInput(String input) {
    // Remove potentially harmful content
    return input
      .replaceAll(RegExp(r'<script.*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
      .replaceAll(RegExp(r'data:', caseSensitive: false), '')
      .trim();
  }

  /// Validate input length and content
  static bool isValidInput(String input) {
    if (input.length > 2000) {
      return false;
    }

    if (input.isEmpty) {
      return false;
    }

    // Check for excessive special characters
    final specialCharCount = input.split('').where((char) => 
      '!@#$%^&*()_+-=[]{}|;:,.<>?'.contains(char)).length;
    
    if (specialCharCount > input.length * 0.3) {
      return false;
    }

    return true;
  }

  /// Detect and prevent prompt injection attacks
  static bool containsPromptInjection(String input) {
    final injectionPatterns = [
      RegExp(r'ignore.*previous.*instructions', caseSensitive: false),
      RegExp(r'forget.*rules', caseSensitive: false),
      RegExp(r'system.*prompt', caseSensitive: false),
      RegExp(r'you.*are.*now', caseSensitive: false),
    ];

    return injectionPatterns.any((pattern) => pattern.hasMatch(input));
  }
}
```

### Data Privacy

```dart
class AIPrivacyManager {
  /// Anonymize sensitive data before sending to AI
  static String anonymizeUserData(UserData userData) {
    return '''
User Profile (Anonymized):
- Role: Productivity User
- Preferences: Standard
- Usage Pattern: Regular
- Data Summary: ${userData.todos.length} todos, ${userData.goals.length} goals

Note: Personal identifiers have been removed for privacy protection.
''';
  }

  /// Ensure compliance with data protection regulations
  static bool isCompliantWithDataPolicy(String prompt, UserData userData) {
    // Check for PII in prompt
    if (containsPersonalInformation(prompt)) {
      return false;
    }

    // Check for sensitive data in user context
    if (containsSensitiveData(userData)) {
      return false;
    }

    return true;
  }

  static bool containsPersonalInformation(String text) {
    // Check for email addresses
    final emailPattern = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    if (emailPattern.hasMatch(text)) return true;

    // Check for phone numbers
    final phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    if (phonePattern.hasMatch(text)) return true;

    // Check for addresses
    final addressPattern = RegExp(r'\d{1,5}\s\w+\s\w+');
    if (addressPattern.hasMatch(text)) return true;

    return false;
  }

  static bool containsSensitiveData(UserData userData) {
    // Check for sensitive information in user data
    final sensitiveKeywords = [
      'password', 'ssn', 'credit card', 'bank account',
      'medical', 'health', 'financial', 'legal'
    ];

    final userDataText = userData.additionalInfo
        .map((info) => info.info.toLowerCase())
        .join(' ');

    return sensitiveKeywords.any((keyword) => userDataText.contains(keyword));
  }
}
```

This AI integration documentation provides comprehensive coverage of how the application integrates with AI services, handles function calls, manages context, and ensures security and performance. The implementation demonstrates best practices for building AI-powered features in a productivity application.
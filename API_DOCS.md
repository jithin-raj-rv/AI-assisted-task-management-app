# API Documentation

This document provides comprehensive documentation for all APIs used in the AI-powered productivity application.

## Table of Contents

1. [Supabase Edge Functions](#supabase-edge-functions)
2. [REST API Endpoints](#rest-api-endpoints)
3. [Function Calling Specifications](#function-calling-specifications)
4. [Authentication API](#authentication-api)
5. [Real-time API](#real-time-api)
6. [Error Handling](#error-handling)

## Supabase Edge Functions

### execute-timer-prompt

Executes a timer prompt using AI and updates the prompt with the response.

**Endpoint**: `POST /functions/execute-timer-prompt`

**Request Body**:
```json
{
  "timerPromptId": "string"
}
```

**Response**:
```json
{
  "success": true,
  "response": "string"
}
```

**Example**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/execute-timer-prompt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-jwt-token" \
  -d '{"timerPromptId": "12345"}'
```

**Function Tools Available**:
- `addTodo`: Adds a new todo item
- `deleteTodo`: Deletes a todo item
- `modifyTodo`: Modifies an existing todo item
- `addGoal`: Adds a new goal
- `deleteGoal`: Deletes a goal
- `modifyGoal`: Modifies an existing goal
- `addTimerPrompt`: Adds a new timer prompt
- `deleteTimerPrompt`: Deletes a timer prompt
- `modifyTimerPrompt`: Modifies an existing timer prompt
- `addFeedback`: Adds user feedback
- `deleteFeedback`: Deletes user feedback
- `modifyFeedback`: Modifies existing feedback
- `addGoalStep`: Adds a new goal step
- `deleteGoalStep`: Deletes a goal step
- `modifyGoalStep`: Modifies an existing goal step
- `addPersonalityTrait`: Adds a personality trait
- `deletePersonalityTrait`: Deletes a personality trait
- `modifyPersonalityTrait`: Modifies an existing personality trait
- `addAdditionalInfo`: Adds additional user information
- `deleteAdditionalInfo`: Deletes additional information
- `modifyAdditionalInfo`: Modifies existing additional information
- `addReminder`: Adds a new reminder
- `deleteReminder`: Deletes a reminder
- `modifyReminder`: Modifies an existing reminder

### process-prompt

Processes a user prompt with AI and returns the response.

**Endpoint**: `POST /functions/process-prompt`

**Request Body**:
```json
{
  "userInput": "string",
  "chatHistory": [
    {
      "role": "user|model",
      "content": "string"
    }
  ]
}
```

**Response**:
```json
{
  "response": "string"
}
```

**Example**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/process-prompt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-jwt-token" \
  -d '{
    "userInput": "Help me organize my tasks",
    "chatHistory": []
  }'
```

## REST API Endpoints

### Authentication Endpoints

#### Sign In
```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**:
```json
{
  "access_token": "string",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "string",
  "user": {
    "id": "string",
    "email": "user@example.com",
    "created_at": "2023-01-01T00:00:00.000Z"
  }
}
```

#### Sign Out
```http
POST /auth/v1/logout
Authorization: Bearer your-access-token
```

### Todo Management Endpoints

#### Get All Todos
```http
GET /rest/v1/todos?user_id=eq.your-user-id
Authorization: Bearer your-access-token
Prefer: count=exact
```

**Response**:
```json
[
  {
    "id": "todo-id",
    "user_id": "user-id",
    "task_name": "Complete project",
    "description": "Finish the project documentation",
    "due_date": "2023-12-31T00:00:00.000Z",
    "is_completed": false,
    "importance": "IMPORTANT",
    "urgency": "URGENT",
    "created_at": "2023-01-01T00:00:00.000Z",
    "updated_at": "2023-01-01T00:00:00.000Z",
    "is_synced": true
  }
]
```

#### Create Todo
```http
POST /rest/v1/todos
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "user_id": "user-id",
  "task_name": "New task",
  "description": "Task description",
  "due_date": "2023-12-31T00:00:00.000Z",
  "is_completed": false,
  "importance": "IMPORTANT",
  "urgency": "URGENT"
}
```

#### Update Todo
```http
PATCH /rest/v1/todos?id=eq.todo-id&user_id=eq.user-id
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "is_completed": true,
  "updated_at": "2023-01-01T00:00:00.000Z"
}
```

#### Delete Todo
```http
DELETE /rest/v1/todos?id=eq.todo-id&user_id=eq.user-id
Authorization: Bearer your-access-token
```

### Goal Management Endpoints

#### Get All Goals
```http
GET /rest/v1/goals?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Create Goal
```http
POST /rest/v1/goals
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "user_id": "user-id",
  "title": "Learn Flutter",
  "description": "Become proficient in Flutter development",
  "target_date": "2024-06-01T00:00:00.000Z",
  "is_completed": false
}
```

#### Update Goal
```http
PATCH /rest/v1/goals?id=eq.goal-id&user_id=eq.user-id
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "is_completed": true,
  "updated_at": "2023-01-01T00:00:00.000Z"
}
```

### Goal Steps Endpoints

#### Get Goal Steps
```http
GET /rest/v1/goal_steps?goal_id=eq.goal-id&user_id=eq.user-id
Authorization: Bearer your-access-token
```

#### Create Goal Step
```http
POST /rest/v1/goal_steps
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "user_id": "user-id",
  "goal_id": "goal-id",
  "step_text": "Research Flutter basics",
  "is_completed": false,
  "sort_order": 1
}
```

### Timer Prompts Endpoints

#### Get Timer Prompts
```http
GET /rest/v1/timer_prompts?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Create Timer Prompt
```http
POST /rest/v1/timer_prompts
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "user_id": "user-id",
  "prompt": "Review your progress today",
  "scheduled_time": "2023-12-31T09:00:00.000Z",
  "recurring_type": "daily",
  "weekdays": [1, 2, 3, 4, 5],
  "sent": false
}
```

### Reminders Endpoints

#### Get Reminders
```http
GET /rest/v1/reminders?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Create Reminder
```http
POST /rest/v1/reminders
Authorization: Bearer your-access-token
Content-Type: application/json
Prefer: return=representation

{
  "user_id": "user-id",
  "title": "Take medication",
  "body": "Remember to take your vitamins",
  "scheduled_date": "2023-12-31T08:00:00.000Z",
  "reminder_type": "basic",
  "payload": "Take medication"
}
```

### User Data Endpoints

#### Get Personality Traits
```http
GET /rest/v1/personality_traits?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Get Additional Info
```http
GET /rest/v1/additional_info?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Get User Feedback
```http
GET /rest/v1/user_feedback?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

#### Get System Prompts
```http
GET /rest/v1/system_prompts?user_id=eq.your-user-id
Authorization: Bearer your-access-token
```

## Function Calling Specifications

### Function Call Structure

All function calls follow this structure:

```typescript
interface FunctionCall {
  name: string;
  args: Record<string, any>;
}
```

### Available Functions

#### Todo Functions

##### addTodo
Adds a new todo item to the user's list.

**Parameters**:
```typescript
{
  task: string;           // The task to be done
  importance: 'IMPORTANT' | 'NOT IMPORTANT';  // How valuable/meaningful
  urgency: 'URGENT' | 'NOT URGENT';           // How time-sensitive
  description?: string;   // Task description
  dueDate?: string;       // Due date in ISO format
  isCompleted?: boolean;  // Whether the task is completed
}
```

**Example**:
```typescript
{
  name: 'addTodo',
  args: {
    task: 'Complete project documentation',
    importance: 'IMPORTANT',
    urgency: 'URGENT',
    description: 'Write comprehensive documentation for the project',
    dueDate: '2023-12-31T00:00:00.000Z'
  }
}
```

##### deleteTodo
Deletes a todo item from the user's list.

**Parameters**:
```typescript
{
  taskId: string;  // The ID of the task to delete
}
```

##### modifyTodo
Modifies an existing todo item.

**Parameters**:
```typescript
{
  taskId: string;           // The ID of the task to modify
  newTask: string;          // The updated task
  newImportance: 'IMPORTANT' | 'NOT IMPORTANT';
  newUrgency: 'URGENT' | 'NOT URGENT';
  newDescription?: string;
  newDueDate?: string;
  newIsCompleted?: boolean;
}
```

#### Goal Functions

##### addGoal
Adds a new goal to the user's list.

**Parameters**:
```typescript
{
  title: string;            // The goal title
  description?: string;     // Goal description
  targetDate?: string;      // Target date in ISO format
  isCompleted?: boolean;    // Whether the goal is completed
}
```

##### deleteGoal
Deletes a goal from the user's list.

**Parameters**:
```typescript
{
  goalId: string;  // The ID of the goal to delete
}
```

##### modifyGoal
Modifies an existing goal.

**Parameters**:
```typescript
{
  goalId: string;           // The ID of the goal to modify
  newTitle: string;         // The updated title
  newDescription?: string;
  newTargetDate?: string;
  newIsCompleted?: boolean;
}
```

#### Timer Prompt Functions

##### addTimerPrompt
Adds a new timer prompt.

**Parameters**:
```typescript
{
  prompt: string;           // The prompt text
  scheduledTime: string;    // Scheduled time in ISO format
  recurring_type?: 'never' | 'daily' | 'weekly';
  weekdays?: number[];      // Array of weekday numbers (1-7)
  response?: string;        // The response text
  sent?: boolean;           // Whether it has been sent
}
```

##### deleteTimerPrompt
Deletes a timer prompt.

**Parameters**:
```typescript
{
  promptId: string;  // The ID of the prompt to delete
}
```

##### modifyTimerPrompt
Modifies an existing timer prompt.

**Parameters**:
```typescript
{
  promptId: string;         // The ID of the prompt to modify
  newPrompt: string;        // The updated prompt
  newScheduledTime?: string;
  newRecurringType?: 'never' | 'daily' | 'weekly';
  newWeekdays?: number[];
  newResponse?: string;
  newSent?: boolean;
}
```

#### Reminder Functions

##### addReminder
Adds a new reminder.

**Parameters**:
```typescript
{
  title: string;            // The reminder title
  body?: string;            // The reminder body text
  scheduledDate: string;    // Scheduled date in ISO format
  reminderType: 'basic' | 'option' | 'answer_back' | 'ai_prompt';
  options?: string[];       // Options for option-type reminders
  expectedAnswer?: string;  // Expected answer for answer_back reminders
  aiPrompt?: string;        // AI prompt for ai_prompt reminders
}
```

##### deleteReminder
Deletes a reminder.

**Parameters**:
```typescript
{
  reminderId: string;  // The ID of the reminder to delete
}
```

##### modifyReminder
Modifies an existing reminder.

**Parameters**:
```typescript
{
  reminderId: string;       // The ID of the reminder to modify
  newTitle: string;         // The updated title
  newBody?: string;
  newScheduledDate?: string;
  newReminderType?: 'basic' | 'option' | 'answer_back' | 'ai_prompt';
  newOptions?: string[];
  newExpectedAnswer?: string;
  newAiPrompt?: string;
}
```

## Authentication API

### JWT Token Structure

```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "exp": 1640995200,
  "iat": 1640991600,
  "role": "authenticated",
  "iss": "supabase",
  "aud": "authenticated"
}
```

### Token Refresh

```http
POST /auth/v1/token?grant_type=refresh_token
Content-Type: application/json

{
  "refresh_token": "your-refresh-token"
}
```

### Session Management

```dart
class SessionManager {
  // Check if session is valid
  bool isSessionValid(AuthSession? session) {
    if (session == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    return session.expiresAt! > now;
  }
  
  // Refresh session
  Future<AuthSession> refreshSession() async {
    return await supabase.auth.refreshSession();
  }
}
```

## Real-time API

### Subscriptions

#### Subscribe to Todo Changes
```dart
final subscription = supabase
  .from('todos')
  .on(SupabaseEventTypes.all, (payload) {
    // Handle insert, update, delete
    print('Todo changed: ${payload.newRecord}');
  })
  .execute();
```

#### Subscribe to Goal Changes
```dart
final subscription = supabase
  .from('goals')
  .on(SupabaseEventTypes.all, (payload) {
    print('Goal changed: ${payload.newRecord}');
  })
  .execute();
```

#### Subscribe to User-specific Changes
```dart
final subscription = supabase
  .from('todos')
  .eq('user_id', userId)
  .on(SupabaseEventTypes.all, (payload) {
    print('User todo changed: ${payload.newRecord}');
  })
  .execute();
```

### Real-time Channels

```dart
class RealtimeManager {
  Stream<SupabaseRealtimePayload> subscribeToTable(String tableName, String userId) {
    return supabase
      .from(tableName)
      .eq('user_id', userId)
      .on(SupabaseEventTypes.all, (payload) => payload)
      .stream();
  }
  
  void unsubscribe(StreamSubscription subscription) {
    subscription.cancel();
  }
}
```

## Error Handling

### Error Response Format

```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE",
    "details": "Additional error details"
  }
}
```

### Common Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `UNAUTHORIZED` | Authentication required | 401 |
| `FORBIDDEN` | Access denied | 403 |
| `NOT_FOUND` | Resource not found | 404 |
| `CONFLICT` | Resource conflict | 409 |
| `TOO_MANY_REQUESTS` | Rate limit exceeded | 429 |
| `INTERNAL_SERVER_ERROR` | Server error | 500 |
| `NETWORK_ERROR` | Network connectivity issue | - |
| `TIMEOUT` | Request timeout | - |

### Error Handling in Dart

```dart
class ApiErrorHandler {
  static void handleApiError(Object error, StackTrace stack) {
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PGRST106':
          // No rows returned
          print('Resource not found');
          break;
        case 'PGRST116':
          // Row level security violation
          print('Access denied');
          break;
        default:
          print('Database error: ${error.message}');
      }
    } else if (error is AuthException) {
      print('Authentication error: ${error.message}');
    } else {
      print('Unknown error: $error');
    }
  }
  
  static Future<T> safeApiCall<T>(Future<T> apiCall) async {
    try {
      return await apiCall;
    } catch (error, stack) {
      handleApiError(error, stack);
      rethrow;
    }
  }
}
```

### Retry Logic

```dart
class RetryManager {
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation,
    {int maxAttempts = 5, Duration initialDelay = const Duration(seconds: 1)}
  ) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          throw error;
        }
        
        final delay = initialDelay * Duration(seconds: pow(2, attempts).toInt());
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Max retry attempts exceeded');
  }
}
```

This API documentation provides comprehensive coverage of all endpoints, function calls, and error handling patterns used in the application. Developers can use this as a reference for integrating with the backend services and understanding the available functionality.
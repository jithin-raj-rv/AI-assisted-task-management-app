// AI/gemini.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/View%20Model/goalspagevm.dart';
import 'package:to_do_list/View%20Model/homepagevm.dart';
import 'package:to_do_list/View%20Model/settingspagevm.dart';
import 'package:to_do_list/todo_repository.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/theme.dart'; // Ensure this points to your theme provider
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/models/chat_model.dart';
import 'package:to_do_list/models/todo_model.dart';


final themeTool = Tool(functionDeclarations: [
  FunctionDeclaration(
    'updateAppColors',
    'Updates the app theme colors based on user preferences.',
    Schema.object(
      properties: {
        'primaryHex': Schema.string(description: 'Hex code for the primary Text and Icon color.'),
        'backgroundHex': Schema.string(description: 'Hex code for the background color.'),
        'secondaryHex': Schema.string(description: 'Hex code for the secondary color.'),
        'tertiaryHex': Schema.string(description: 'Hex code for the tertiary color.'),
        'primaryGradient1Hex': Schema.string(description: 'Hex code for the first primary gradient color.'),
        'primaryGradient2Hex': Schema.string(description: 'Hex code for the second primary gradient color.'),
        'secondaryGradient1Hex': Schema.string(description: 'Hex code for the first secondary gradient color.'),
        'secondaryGradient2Hex': Schema.string(description: 'Hex code for the second secondary gradient color.'),
        'tertiaryGradient1Hex': Schema.string(description: 'Hex code for the first tertiary gradient color.'),
        'tertiaryGradient2Hex': Schema.string(description: 'Hex code for the second tertiary gradient color.'),
        'backgroundGradient1Hex': Schema.string(description: 'Hex code for the first background gradient color.'),
        'backgroundGradient2Hex': Schema.string(description: 'Hex code for the second background gradient color.'),
      },
      requiredProperties: [
        'primaryHex',
        'backgroundHex',
        'secondaryHex',
        'tertiaryHex',
        'primaryGradient1Hex',
        'primaryGradient2Hex',
        'secondaryGradient1Hex',
        'secondaryGradient2Hex',
        'tertiaryGradient1Hex',
        'tertiaryGradient2Hex',
        'backgroundGradient1Hex',
        'backgroundGradient2Hex',
      ],
    ),
  ),
]);

final todoTool = Tool(functionDeclarations: [
  FunctionDeclaration(
    'addTodo',
    'Adds a new to-do item to the list.',
    Schema.object(
      properties: {
        'task': Schema.string(description: 'The task to be done.'),
        'importance': Schema.string(description: 'The importance of the task. Can be "IMPORTANT" or "NOT IMPORTANT".'),
        'urgency': Schema.string(description: 'The urgency of the task. Can be "URGENT" or "NOT URGENT".'),
        'description': Schema.string(description: 'A detailed description of the task.', nullable: true),
        'dueDate': Schema.string(description: 'The due date and time of the task in ISO 8601 format (e.g., "2024-12-31T15:30:00").', nullable: true),
      },
      requiredProperties: ['task', 'importance', 'urgency','description','dueDate'],
    ),
  ),
  FunctionDeclaration(
    'deleteTodo', 
    'Deletes a to-do item from the list ',
   Schema.object(
    properties: {
      'taskId': Schema.integer(description: 'The index of the to-do item to be deleted from the todoList.'),
    },
    requiredProperties: ['taskId'],
  ),
  ),

  FunctionDeclaration(
    'modifyTodo', 
    'Modify a to-do item in the list', 
    Schema.object(
    properties: {
      'taskId': Schema.integer(description: 'The index of the to-do item to be modified from the todoList.'),
      'newTask': Schema.string(description: 'The updated task description.'),
      'newImportance': Schema.string(description: 'The updated importance of the task. Can be "IMPORTANT" or "NOT IMPORTANT".', nullable: true),
      'newUrgency': Schema.string(description: 'The updated urgency of the task. Can be "URGENT" or "NOT URGENT".', nullable: true),
      'newDescription': Schema.string(description: 'A detailed description of the task.', nullable: true),
      'newDueDate': Schema.string(description: 'The new due date and time of the task in ISO 8601 format (e.g., "2024-12-31T15:30:00").', nullable: true),
    },
    requiredProperties: ['taskId', 'newTask'],
  )
  )
]);

final goalTool = Tool(functionDeclarations: [
  FunctionDeclaration(
    'addGoal',
    'Adds a new goal to the list.',
    Schema.object(
      properties: {
        'title': Schema.string(description: 'The title of the goal.'),
        'description': Schema.string(description: 'A detailed description of the goal.'),
        'targetDate': Schema.string(description: 'The target date for the goal in ISO 8601 format (e.g., "2025-12-31").'),
      },
      requiredProperties: ['title', 'description', 'targetDate'],
    ),
  ),
  FunctionDeclaration(
    'deleteGoal',
    'Deletes a goal from the list.',
    Schema.object(
      properties: {
        'goalId': Schema.integer(description: 'The index of the goal to be deleted from the goals list.'),
      },
      requiredProperties: ['goalId'],
    ),
  ),
  FunctionDeclaration(
    'modifyGoal',
    'Modifies a goal in the list.',
    Schema.object(
      properties: {
        'goalId': Schema.integer(description: 'The index of the goal to be modified from the goals list.'),
        'newTitle': Schema.string(description: 'The updated title of the goal.'),
        'newDescription': Schema.string(description: 'The updated description of the goal.', nullable: true),
        'newTargetDate': Schema.string(description: 'The new target date for the goal in ISO 8601 format (e.g., "2025-12-31").', nullable: true),
      },
      requiredProperties: ['goalId', 'newTitle'],
    ),
  ),
]);
      final personalityTool = Tool(functionDeclarations: [
        FunctionDeclaration(
          'addPersonality',
          'Adds a personality trait to the user profile.',
          Schema.object(
            properties: {
              'item': Schema.string(description: 'Personality trait to add.'),
            },
            requiredProperties: ['item'],
          ),
        ),
        FunctionDeclaration(
          'deletePersonality',
          'Deletes a personality trait by index.',
          Schema.object(
            properties: {
              'index': Schema.integer(description: 'Index of the personality trait to delete.'),
            },
            requiredProperties: ['index'],
          ),
        ),
        FunctionDeclaration(
          'modifyPersonality',
          'Modifies a personality trait by index.',
          Schema.object(
            properties: {
              'index': Schema.integer(description: 'Index of the personality trait to modify.'),
              'newItem': Schema.string(description: 'New personality trait value.'),
            },
            requiredProperties: ['index', 'newItem'],
          ),
        ),
      ]);

      final additionalInfoTool = Tool(functionDeclarations: [
        FunctionDeclaration(
          'addAdditionalInfo',
          'Adds an additional info item to the user profile.',
          Schema.object(
            properties: {
              'item': Schema.string(description: 'Additional info to add.'),
            },
            requiredProperties: ['item'],
          ),
        ),
        FunctionDeclaration(
          'deleteAdditionalInfo',
          'Deletes an additional info item by index.',
          Schema.object(
            properties: {
              'index': Schema.integer(description: 'Index of the additional info to delete.'),
            },
            requiredProperties: ['index'],
          ),
        ),
        FunctionDeclaration(
          'modifyAdditionalInfo',
          'Modifies an additional info item by index.',
          Schema.object(
            properties: {
              'index': Schema.integer(description: 'Index of the additional info to modify.'),
              'newItem': Schema.string(description: 'New additional info value.'),
            },
            requiredProperties: ['index', 'newItem'],
          ),
        ),
      ]);

Future<String> sendChatMessage(WidgetRef ref, String userInput, {List<Content>? chatHistoryOverride}) async {
  print("AI Agent: Starting request for '$userInput'");
  final todosAsync = ref.watch(todosProvider);
  final todolList = todosAsync.maybeWhen(data: (data) => data, orElse: () => <Todo>[]);
  final additionalInfo = ref.read(settingsPageViewModelProvider).additionalinfo;
  final personality = ref.read(settingsPageViewModelProvider).personality;
  final goals = ref.read(goalsPageViewModelProvider).goals;

  // --- Start: Chat history integration ---
  // Load persistent chat storage so we can save this conversation when
  // appropriate (but don't auto-persist when a `chatHistoryOverride` is
  // supplied by a caller like `GeminiDialog`).
  final ChatData _chatData = ChatData();
  _chatData.loadData();

  // Build history to send to the model. If an override was provided, use it;
  // otherwise build from stored messages and persist the current user
  // message to the session (avoids duplicates when `override` is used).
  final List<Content> chatHistory;
  if (chatHistoryOverride != null) {
    chatHistory = chatHistoryOverride;
  } else {
    // Persist the user's message unless it's already the last saved user message.
    if (_chatData.currentChatMessages.isEmpty || !(_chatData.currentChatMessages.last.isUser && _chatData.currentChatMessages.last.text.trim() == userInput.trim())) {
      _chatData.addMessage(Chat(text: userInput, isUser: true));
    }

    final List<Content> tempChatHistory = [];
    final messages = _chatData.currentChatMessages;
    int excludeIndex = -1;
    if (messages.isNotEmpty) {
      final last = messages.last;
      if (last.isUser && last.text.trim() == userInput.trim()) {
        excludeIndex = messages.length - 1;
      }
    }
    for (int i = 0; i < messages.length; i++) {
      if (i == excludeIndex) continue;
      final chatMessage = messages[i];
      tempChatHistory.add(
        Content(
          (chatMessage.isUser ? 'user' : 'model'),
          [TextPart(chatMessage.text)],
        ),
      );
          }
    chatHistory = tempChatHistory;
  }
  // --- End: Chat history integration ---

  try {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: 'AIzaSyDk8YrUKQMIGn2AXpokeF33L3IgjzEqjFI', // Double check this key!
      tools: [themeTool, todoTool, goalTool, personalityTool, additionalInfoTool],
      requestOptions: const RequestOptions(apiVersion: 'v1beta'),
      systemInstruction: Content.system(
        "You have access to User todoList: $todolList."
        "User additional info: $additionalInfo."
        "User personality: $personality."
        "User goals: $goals."
        "You are a professional Personal manager, managing user tasks,goals,personalities,additionaluserinfo"
        "You also have access to app colors"
        "When a user mentions colors, moods, or themes, you MUST NOT ask for hex codes. "
        "Instead, you must immediately call the 'updateAppColors' tool with your best "
        "professional choice of Hex codes for those colors. "
        "Always pick high-contrast, beautiful colors. "
        "When a user wants to add a to-do, you must call the 'addTodo' tool with the extracted task, importance, and urgency.If the user doesn't specify task, add based on the available information. "
        "When a user wants to delete a to-do, you must analyse todoList call the 'deleteTodo' tool with the extracted index, based on the details the user has given, never ask for ID."
        "Default importance is 'NOT IMPORTANT' and default urgency is 'NOT URGENT' if not specified."
        "When a user wants to modify a to-do, you must analyse todoList call the 'modifyTodo' tool with the extracted index and new details, based on the details the user has given, never ask for ID."
        "When a user wants to add a goal, you must call the 'addGoal' tool with the extracted title, description, and targetDate. If the user does not provide all the necessary information, you must ask for it."
        "When a user wants to delete a goal, you must analyse goals list and call the 'deleteGoal' tool with the extracted index, based on the details the user has given. You must not ask for the ID of the goal."
        "When a user wants to modify a goal, you must analyse goals list and call the 'modifyGoal' tool with the extracted index and new details, based on the details the user has given. You must not ask for the ID of the goal. If the user does not provide all the necessary information, you must ask for it."
        "When a user wants to add a personality trait, you must call the 'addPersonality' tool with the extracted item."
        "When a user wants to delete a personality trait, you must call the 'deletePersonality' tool with the extracted index."
        "When a user wants to modify a personality trait, you must call the 'modifyPersonality' tool with the extracted index and new details, based on the details the user has given."
        "When a user wants to add an additional info item, you must call the 'addAdditionalInfo' tool with the extracted item."
        "When a user wants to delete an additional info item, you must call the 'deleteAdditionalInfo' tool with the extracted index."
        "When a user wants to modify an additional info item, you must call the 'modifyAdditionalInfo' tool with the extracted index and new details, based on the details the user has given"
      ),
    );

    final chat = model.startChat(history: chatHistory); // Pass history here
    final response = await chat.sendMessage(Content.text(userInput));

    final functionCalls = response.functionCalls.toList();

    if (functionCalls.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      for (final call in functionCalls) {
        if (call.name == 'updateAppColors') {
          final primary = call.args['primaryHex'] as String;
          final background = call.args['backgroundHex'] as String;
          final secondary = call.args['secondaryHex'] as String;
          final tertiary = call.args['tertiaryHex'] as String;
          final primaryGradient1 = call.args['primaryGradient1Hex'] as String;
          final primaryGradient2 = call.args['primaryGradient2Hex'] as String;
          final secondaryGradient1 = call.args['secondaryGradient1Hex'] as String;
          final secondaryGradient2 = call.args['secondaryGradient2Hex'] as String;
          final tertiaryGradient1 = call.args['tertiaryGradient1Hex'] as String;
          final tertiaryGradient2 = call.args['tertiaryGradient2Hex'] as String;
          final backgroundGradient1 = call.args['backgroundGradient1Hex'] as String;
          final backgroundGradient2 = call.args['backgroundGradient2Hex'] as String;


          ref.read(themeProvider.notifier).setTheme(AppThemeState(
            primary: _fromHex(primary),
            background: _fromHex(background),
            secondary: _fromHex(secondary),
            tertiary: _fromHex(tertiary),
            primaryGradient1: _fromHex(primaryGradient1),
            primaryGradient2: _fromHex(primaryGradient2),
            secondaryGradient1: _fromHex(secondaryGradient1),
            secondaryGradient2: _fromHex(secondaryGradient2),
            tertiaryGradient1: _fromHex(tertiaryGradient1),
            tertiaryGradient2: _fromHex(tertiaryGradient2),
            backgroundGradient1: _fromHex(backgroundGradient1),
            backgroundGradient2: _fromHex(backgroundGradient2),

          ));
          final message = "Successfully changed colors to $primary and $background and $secondary";
          print("AI Agent: $message");
          buffer.writeln(message);

        } else if (call.name == 'addTodo') {
          final task = call.args['task'] as String;
          final importance = call.args['importance'] as String;
          final urgency = call.args['urgency'] as String;
          final description = call.args['description'] as String? ?? ''; // Handle optional description
          final dueDateString = call.args['dueDate'] as String?; // Get dueDate as string

          DateTime? dueDate;
          if (dueDateString != null && dueDateString.isNotEmpty) {
            try {
              dueDate = DateTime.parse(dueDateString);
            } catch (e) {
              print("AI Agent: Error parsing dueDate string '$dueDateString': $e");
              // Handle parsing error, maybe set a default or notify the user
            }
          }
          dueDate ??= DateTime.now(); // Default to now if parsing fails or not provided

          final repo = ref.read(todoRepositoryProvider);
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final todo = Todo(
            id: id,
            taskName: task,
            importance: importance,
            urgency: urgency,
            description: description,
            dueDate: dueDate,
          );
          repo.addTodo(todo);
          final message = "Successfully added to-do: '$task'";
          print("AI Agent: $message");
          buffer.writeln(message);
        }
        else if (call.name == 'deleteTodo') {
          final taskId = call.args['taskId'] as int;
          print(taskId);

          if (taskId >= 0 && taskId < todolList.length) {
            final todo = todolList[taskId];
            final repo = ref.read(todoRepositoryProvider);
            repo.deleteTodo(todo.id!);
            final message = "Successfully deleted to-do with ID: '$taskId'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete to-do: Invalid taskId '$taskId'.";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        }
        else if (call.name == 'modifyTodo') {
          final taskId = call.args['taskId'] as int;
          final newTask = call.args['newTask'] as String;
          final newImportance = call.args['newImportance'] as String?;
          final newUrgency = call.args['newUrgency'] as String?;
          final newDescription = call.args['newDescription'] as String?;
          final newDueDateString = call.args['newDueDate'] as String?;

          DateTime? newDueDate;
          if (newDueDateString != null && newDueDateString.isNotEmpty) {
            try {
              newDueDate = DateTime.parse(newDueDateString);
            } catch (e) {
              print("AI Agent: Error parsing newDueDate string '$newDueDateString': $e");
            }
          }

          if (taskId >= 0 && taskId < todolList.length) {
            final existingTodo = todolList[taskId];

            final updatedTodo = existingTodo.clone()
              ..taskName = newTask
              ..importance = newImportance ?? existingTodo.importance
              ..urgency = newUrgency ?? existingTodo.urgency
              ..description = newDescription ?? existingTodo.description
              ..dueDate = newDueDate ?? existingTodo.dueDate;

            final repo = ref.read(todoRepositoryProvider);
            repo.updateTodo(existingTodo.id!, updatedTodo);

            final message = "Successfully modified to-do with ID: '$taskId'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to modify to-do: Invalid taskId '$taskId'.";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'addGoal') {
          final title = call.args['title'] as String;
          final description = call.args['description'] as String;
          final targetDateString = call.args['targetDate'] as String;

          DateTime? targetDate;
          if (targetDateString.isNotEmpty) {
            try {
              targetDate = DateTime.parse(targetDateString);
            } catch (e) {
              print("AI Agent: Error parsing targetDate string '$targetDateString': $e");
            }
          }
          targetDate ??= DateTime.now();

          ref.read(goalsPageViewModelProvider.notifier).addGoal(title, description, targetDate);
          final message = "Successfully added goal: '$title'";
          print("AI Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deleteGoal') {
          final goalId = call.args['goalId'] as int;
          final currentGoals = ref.read(goalsPageViewModelProvider).goals;
          if (goalId >= 0 && goalId < currentGoals.length) {
            ref.read(goalsPageViewModelProvider.notifier).deleteGoal(currentGoals[goalId].title);
            final message = "Successfully deleted goal with ID: '$goalId'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete goal: Invalid goalId '$goalId'.";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'modifyGoal') {
          final goalId = call.args['goalId'] as int;
          final newTitle = call.args['newTitle'] as String;
          final newDescription = call.args['newDescription'] as String?;
          final newTargetDateString = call.args['newTargetDate'] as String?;

          DateTime? newTargetDate;
          if (newTargetDateString != null && newTargetDateString.isNotEmpty) {
            try {
              newTargetDate = DateTime.parse(newTargetDateString);
            } catch (e) {
              print("AI Agent: Error parsing newTargetDate string '$newTargetDateString': $e");
            }
          }

          final currentGoals = ref.read(goalsPageViewModelProvider).goals;
          if (goalId >= 0 && goalId < currentGoals.length) {
            final existingGoal = currentGoals[goalId];
            ref.read(goalsPageViewModelProvider.notifier).updateGoal(
              existingGoal.title,
              newTitle,
              newDescription ?? existingGoal.description,
              newTargetDate ?? existingGoal.targetDate,
            );
            final message = "Successfully modified goal with ID: '$goalId'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to modify goal: Invalid goalId '$goalId'.";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'addPersonality') {
          final item = call.args['item'] as String;
          ref.read(settingsPageViewModelProvider.notifier).addPersonality(item);
          final message = "Successfully added personality: '$item'";
          print("AI Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deletePersonality') {
          final index = call.args['index'] as int;
          final current = ref.read(settingsPageViewModelProvider).personality;
          if (index >= 0 && index < current.length) {
            ref.read(settingsPageViewModelProvider.notifier).deletePersonality(index);
            final message = "Successfully deleted personality at index: '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete personality: invalid index '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'modifyPersonality') {
          final index = call.args['index'] as int;
          final newItem = call.args['newItem'] as String;
          final current = ref.read(settingsPageViewModelProvider).personality;
          if (index >= 0 && index < current.length) {
            ref.read(settingsPageViewModelProvider.notifier).updatePersonality(index, newItem);
            final message = "Successfully updated personality at index $index to '$newItem'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to update personality: invalid index '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'addAdditionalInfo') {
          final item = call.args['item'] as String;
          ref.read(settingsPageViewModelProvider.notifier).addAdditionalInfo(item);
          final message = "Successfully added additional info: '$item'";
          print("AI Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deleteAdditionalInfo') {
          final index = call.args['index'] as int;
          final current = ref.read(settingsPageViewModelProvider).additionalinfo;
          if (index >= 0 && index < current.length) {
            ref.read(settingsPageViewModelProvider.notifier).deleteAdditionalInfo(index);
            final message = "Successfully deleted additional info at index: '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete additional info: invalid index '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'modifyAdditionalInfo') {
          final index = call.args['index'] as int;
          final newItem = call.args['newItem'] as String;
          final current = ref.read(settingsPageViewModelProvider).additionalinfo;
          if (index >= 0 && index < current.length) {
            ref.read(settingsPageViewModelProvider.notifier).updateAdditionalInfo(index, newItem);
            final message = "Successfully updated additional info at index $index to '$newItem'";
            print("AI Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to update additional info: invalid index '$index'";
            print("AI Agent: $message");
            buffer.writeln(message);
          }
        }
      }
      final resultText = buffer.toString();
      try {
        _chatData.addMessage(Chat(text: resultText, isUser: false));
      } catch (e) {
        print('AI Agent: Failed to save assistant function-result to history: $e');
      }
      return resultText;
    } else {
      final assistantText = response.text ?? "No text response.";
      try {
        if (assistantText.trim().isNotEmpty) {
          _chatData.addMessage(Chat(text: assistantText, isUser: false));
        }
      } catch (e) {
        print('AI Agent: Failed to save assistant reply to history: $e');
      }
      print("AI Agent: Gemini replied with text only: $assistantText");
      return assistantText;
    }
  } catch (e) {
    print("AI ERROR: $e");
    return "AI ERROR: $e";
  }
}

Color _fromHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// AI/gemini_background.dart - Background compatible AI functions

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/database/database.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/database/chatdata.dart';
import 'package:to_do_list/models/chat_model.dart';

final themeToolBackground = Tool(functionDeclarations: [
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

final todoToolBackground = Tool(functionDeclarations: [
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

final goalToolBackground = Tool(functionDeclarations: [
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
      final personalityToolBackground = Tool(functionDeclarations: [
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

      final additionalInfoToolBackground = Tool(functionDeclarations: [
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
              'index': Schema.integer(description: 'Index of the additional info to modify'),
              'newItem': Schema.string(description: 'New additional info value.'),
            },
            requiredProperties: ['index', 'newItem'],
          ),
        ),
      ]);

Future<String> sendChatMessageBackground(Localdata db, String userInput) async {
  print("AI Background Agent: Starting request for '$userInput'");

  // Load chat data for background chat history
  final ChatData _chatData = ChatData();
  _chatData.loadData();

  // Add the user's message to chat history
  try {
    _chatData.addMessage(Chat(text: userInput, isUser: true));
  } catch (e) {
    print('AI Background Agent: Failed to save user message to history: $e');
  }

  // Use data directly from db
  final todolList = db.todolist;
  final additionalInfo = db.additionalinfo;
  final personality = db.personality;
  final goals = db.goals;

  try {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: 'AIzaSyDk8YrUKQMIGn2AXpokeF33L3IgjzEqjFI',
      tools: [themeToolBackground, todoToolBackground, goalToolBackground, personalityToolBackground, additionalInfoToolBackground],
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

    final chat = model.startChat();
    final response = await chat.sendMessage(Content.text(userInput));

    final functionCalls = response.functionCalls.toList();

    if (functionCalls.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      for (final call in functionCalls) {
        if (call.name == 'updateAppColors') {
          // In background, we can't update theme, so just acknowledge
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

          final message = "Theme colors updated to $primary and $background (background mode - UI not affected)";
          print("AI Background Agent: $message");
          buffer.writeln(message);

        } else if (call.name == 'addTodo') {
          final task = call.args['task'] as String;
          final importance = call.args['importance'] as String;
          final urgency = call.args['urgency'] as String;
          final description = call.args['description'] as String? ?? '';
          final dueDateString = call.args['dueDate'] as String?;

          DateTime? dueDate;
          if (dueDateString != null && dueDateString.isNotEmpty) {
            try {
              dueDate = DateTime.parse(dueDateString);
            } catch (e) {
              print("AI Background Agent: Error parsing dueDate string '$dueDateString': $e");
            }
          }
          dueDate ??= DateTime.now();

          final todo = Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            taskName: task,
            isCompleted: false,
            importance: importance,
            urgency: urgency,
            description: description,
            dueDate: dueDate,
          );
          db.todolist.add(todo);
          db.updatedata();
          final message = "Successfully added to-do: '$task'";
          print("AI Background Agent: $message");
          buffer.writeln(message);
        }
        else if (call.name == 'deleteTodo') {
          final taskIndex = call.args['taskId'] as int;
          if (taskIndex >= 0 && taskIndex < db.todolist.length) {
            db.todolist.removeAt(taskIndex);
            db.updatedata();
            final message = "Successfully deleted to-do at index: '$taskIndex'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete to-do: Invalid index '$taskIndex'";
            print("AI Background Agent: $message");
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
              print("AI Background Agent: Error parsing newDueDate string '$newDueDateString': $e");
            }
          }

          if (taskId >= 0 && taskId < db.todolist.length) {
            final existingTodo = db.todolist[taskId];

            final resolvedImportance = newImportance ?? existingTodo.importance;
            final resolvedUrgency = newUrgency ?? existingTodo.urgency;
            final resolvedDescription = newDescription ?? existingTodo.description;
            DateTime resolvedDueDate = newDueDate ?? existingTodo.dueDate;

            final updatedTodo = Todo(
              id: existingTodo.id,
              taskName: newTask,
              isCompleted: existingTodo.isCompleted,
              importance: resolvedImportance,
              urgency: resolvedUrgency,
              description: resolvedDescription,
              dueDate: resolvedDueDate,
            );
            db.todolist[taskId] = updatedTodo;
            db.updatedata();
            final message = "Successfully modified to-do at index: '$taskId'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to modify to-do: Invalid index '$taskId'";
            print("AI Background Agent: $message");
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
              print("AI Background Agent: Error parsing targetDate string '$targetDateString': $e");
            }
          }
          targetDate ??= DateTime.now();

          final goalBox = Hive.box<Goal>('goals');
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final goal = Goal(
            title: title,
            description: description,
            targetDate: targetDate,
            isCompleted: false,
          );
          await goalBox.put(id, goal);
          final message = "Successfully added goal: '$title'";
          print("AI Background Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deleteGoal') {
          final goalId = call.args['goalId'] as int;
          final goalBox = Hive.box<Goal>('goals');
          final goals = goalBox.values.toList();

          if (goalId >= 0 && goalId < goals.length) {
            final goalToDelete = goals[goalId];
            await goalBox.delete(goalToDelete.title); // Using title as key
            final message = "Successfully deleted goal at index: '$goalId'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete goal: Invalid index '$goalId'";
            print("AI Background Agent: $message");
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
              print("AI Background Agent: Error parsing newTargetDate string '$newTargetDateString': $e");
            }
          }

          if (goalId >= 0 && goalId < db.goals.length) {
            final existingGoal = db.goals[goalId];
            db.goals[goalId] = Goal(
              title: newTitle,
              description: newDescription ?? existingGoal.description,
              targetDate: newTargetDate ?? existingGoal.targetDate,
              isCompleted: existingGoal.isCompleted,
            );
            db.updatedata();
            final message = "Successfully modified goal with ID: '$goalId'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to modify goal: Invalid goalId '$goalId'.";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'addPersonality') {
          final item = call.args['item'] as String;
          db.personality.add(item);
          db.updatedata();
          final message = "Successfully added personality: '$item'";
          print("AI Background Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deletePersonality') {
          final index = call.args['index'] as int;
          if (index >= 0 && index < db.personality.length) {
            db.personality.removeAt(index);
            db.updatedata();
            final message = "Successfully deleted personality at index: '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete personality: invalid index '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'modifyPersonality') {
          final index = call.args['index'] as int;
          final newItem = call.args['newItem'] as String;
          if (index >= 0 && index < db.personality.length) {
            db.personality[index] = newItem;
            db.updatedata();
            final message = "Successfully updated personality at index $index to '$newItem'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to update personality: invalid index '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'addAdditionalInfo') {
          final item = call.args['item'] as String;
          db.additionalinfo.add(item);
          db.updatedata();
          final message = "Successfully added additional info: '$item'";
          print("AI Background Agent: $message");
          buffer.writeln(message);
        } else if (call.name == 'deleteAdditionalInfo') {
          final index = call.args['index'] as int;
          if (index >= 0 && index < db.additionalinfo.length) {
            db.additionalinfo.removeAt(index);
            db.updatedata();
            final message = "Successfully deleted additional info at index: '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to delete additional info: invalid index '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          }
        } else if (call.name == 'modifyAdditionalInfo') {
          final index = call.args['index'] as int;
          final newItem = call.args['newItem'] as String;
          if (index >= 0 && index < db.additionalinfo.length) {
            db.additionalinfo[index] = newItem;
            db.updatedata();
            final message = "Successfully updated additional info at index $index to '$newItem'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          } else {
            final message = "Failed to update additional info: invalid index '$index'";
            print("AI Background Agent: $message");
            buffer.writeln(message);
          }
        }
      }
      final resultText = buffer.toString();
      try {
        _chatData.addMessage(Chat(text: resultText, isUser: false));
      } catch (e) {
        print('AI Background Agent: Failed to save assistant function-result to history: $e');
      }
      return resultText;
    } else {
      final assistantText = response.text ?? "No text response.";
      try {
        _chatData.addMessage(Chat(text: assistantText, isUser: false));
      } catch (e) {
        print('AI Background Agent: Failed to save assistant reply to history: $e');
      }
      print("AI Background Agent: Gemini replied with text only: $assistantText");
      return assistantText;
    }
  } catch (e) {
    print("AI Background ERROR: $e");
    return "AI Background ERROR: $e";
  }
}

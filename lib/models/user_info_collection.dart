import 'package:hive/hive.dart';

part 'user_info_collection.g.dart';

@HiveType(typeId: 2) // Unique typeId for this adapter
class Question extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  QuestionType type;

  @HiveField(3)
  List<String>? options; // For multiple choice questions

  Question({
    required this.id,
    required this.text,
    this.type = QuestionType.text,
    this.options,
  });
}

@HiveType(typeId: 3) // Unique typeId for this adapter
enum QuestionType {
  @HiveField(0)
  text,
  @HiveField(1)
  number,
  @HiveField(2)
  singleChoice,
  @HiveField(3)
  multiChoice,
  @HiveField(4)
  paragraph,
}

class UserInfoCollectionDB {
  final _questionBox = Hive.box('questionBox');
  final _userResponsesBox = Hive.box('userResponsesBox');

  List<Question> _questions = [];

  List<Question> get questions => _questions;

  // Load initial/saved questions
  void loadQuestions() {
    print('Loading questions...');
    if (_questionBox.isEmpty) {
      print('questionBox is empty. Populating with default questions.');
      _questions = [
// basic profile

Question(id: 'name', text: 'What is your name?'),

Question(
  id: 'age',
  text: 'How old are you?',
  type: QuestionType.number,
),

Question(
  id: 'gender',
  text: 'What is your gender?',
  type: QuestionType.singleChoice,
  options: ['Male', 'Female'],
),

// intent and usage
Question(
  id: 'app_intent',
  text: 'What do you mainly want help with?',
  type: QuestionType.multiChoice,
  options: [
    'Daily task planning',
    'Long-term goal achievement',
    'Learning & skill building',
    'Career or studies',
    'Personal projects',
    'Mental clarity & routine',
  ],
),
// personality Identification
Question(
  id: 'work_style',
  text: 'When working on tasks, you prefer to:',
  type: QuestionType.singleChoice,
  options: [
    'Work alone with deep focus',
    'Work with people or interaction',
    'A mix of both',
  ],
),

Question(
  id: 'MBTI',
  text: 'What is yout MBTI type?',
  type: QuestionType.paragraph,
),

Question(
  id: 'planning_preference',
  text: 'Before starting a task, you usually:',
  type: QuestionType.singleChoice,
  options: [
    'Plan everything clearly',
    'Have a rough idea and start',
    'Start and figure it out along the way',
  ],
),
// decision making
Question(
  id: 'decision_style',
  text: 'When making decisions, you rely more on:',
  type: QuestionType.singleChoice,
  options: [
    'Logic and efficiency',
    'Feelings and personal values',
    'A balance of both',
  ],
),

Question(
  id: 'deadline_reaction',
  text: 'How do deadlines affect you?',
  type: QuestionType.singleChoice,
  options: [
    'They motivate me',
    'They stress me but help me focus',
    'They overwhelm me',
  ],
),
// structure vs Flexibility
Question(
  id: 'daily_structure',
  text: 'Your ideal daily schedule is:',
  type: QuestionType.singleChoice,
  options: [
    'Highly structured',
    'Flexible and open',
    'A mix of both',
  ],
),

Question(
  id: 'change_reaction',
  text: 'When plans change suddenly, you usually:',
  type: QuestionType.singleChoice,
  options: [
    'Adapt easily',
    'Feel uncomfortable but manage',
    'Get frustrated',
  ],
),
// Goal Discovery
Question(
  id: 'goal',
  text: 'What are your goals you would like to achieve?',
  type: QuestionType.paragraph,
),
// willingness and resources
Question(
  id: 'willingness',
  text: 'What are you willing to do to achieve your goals?',
  type: QuestionType.paragraph,
),

Question(
  id: 'path',
  text: 'Do you have any path in mind for achieving your goals?',
  type: QuestionType.paragraph,
),

Question(
  id: 'resources',
  text: 'What resources do you have to achieve your goals?',
  type: QuestionType.paragraph,
),
// Time Constraints
Question(
  id: 'daily_time',
  text: 'How much time can you realistically dedicate each day?',
  type: QuestionType.singleChoice,
  options: [
    'Less than 1 hour',
    '1–2 hours',
    '2–4 hours',
    'More than 4 hours',
  ],
),
Question(
  id: 'work-life',
  text: 'Do you like to mix up fun activities with work?',
  type: QuestionType.singleChoice,
  options: [
    'Yes',
    'No',
  ],
),
Question(
  id: "hobies", 
  text: "what are hobbies/activities that makes you happy?",
  type: QuestionType.paragraph,
),

Question(
  id: 'productive_time',
  text: 'When do you feel most productive?',
  type: QuestionType.paragraph,
),
// Obstacle Motivation
Question(
  id: 'main_obstacles',
  text: 'What usually prevents you from completing tasks?',
  type: QuestionType.paragraph,
),

Question(
  id: "health", 
  text: "How is your physical and mental health?",
  type: QuestionType.paragraph,
),

Question(
  id: "previous shedule", 
  text: "do you have a day to day shedule?",
  type: QuestionType.paragraph),


// Task Style Preferences
Question(
  id: 'task_difficulty',
  text: 'How do you want your daily tasks to feel?',
  type: QuestionType.singleChoice,
  options: [
    'Small and easy wins',
    'Balanced difficulty',
    'Challenging and intense',
  ],
),

Question(
  id: 'missed_task_behavior',
  text: 'If you miss a task, how should the assistant respond?',
  type: QuestionType.singleChoice,
  options: [
    'Gently reschedule it',
    'Break it into smaller steps',
    'Remind me firmly',
    'Ignore it unless I ask',
  ],
),
Question(
  id: "shedule-tasks", 
  text: "how would you like to shedule the tasks and reminders?",
  type:QuestionType.singleChoice,
  options: [
    'Everyday at 11 pm',
    'Everyday at 11 am',
    ]
    ),

Question(
  id: "shedule-reminders", 
  text: "how would you like to shedule the tasks and reminders?",
  type:QuestionType.singleChoice,
  options: [
    'Everyday at 11 pm',
    'Everyday at 11 am',
    ]
    ),
      ];
      updateDatabase(); // Save default questions
      print('Default questions populated and updateDatabase called. Current questions count: ${_questions.length}');
    } else {
      _questions = _questionBox.values.cast<Question>().toList();
      print('Questions loaded from questionBox. Current questions count: ${_questions.length}');
    }
  }

  // Update the database with current questions
  void updateDatabase() {
    print('Updating database...');
    _questionBox.clear();
    print('questionBox cleared.');
    for (var question in _questions) {
      _questionBox.put(question.id, question);
    }
    print('Questions saved to questionBox. New questionBox count: ${_questionBox.length}');
  }

  // Add more methods here to manage questions (e.g., add, remove, update) if needed

  // Save user responses
  Future<void> saveUserResponses(Map<String, dynamic> responses) async {
    try {
      if (!Hive.isBoxOpen('userResponsesBox')) {
        await Hive.openBox('userResponsesBox');
      }
      final box = Hive.box('userResponsesBox');

      // Sanitize responses so they're Hive-storable (primitives, lists/maps)
      final Map<String, dynamic> sanitized = {};
      responses.forEach((key, value) {
        if (value == null) {
          sanitized[key] = null;
        } else if (value is String || value is num || value is bool) {
          sanitized[key] = value;
        } else if (value is List) {
          sanitized[key] = value.map((e) => e is String || e is num || e is bool ? e : e.toString()).toList();
        } else if (value is Map) {
          sanitized[key] = value.map((k, v) => MapEntry(k.toString(), v is String || v is num || v is bool ? v : v.toString()));
        } else {
          sanitized[key] = value.toString();
        }
      });

      await box.put('userResponses', sanitized);
    } catch (e, st) {
      print('Error saving user responses: $e');
      print(st);
      rethrow;
    }
  }

  // Load user responses
  Map<String, dynamic> loadUserResponses() {
    final raw = _userResponsesBox.get('userResponses', defaultValue: {});
    if (raw == null) return {};
    if (raw is! Map) return {};

    final Map<String, dynamic> sanitized = {};
    raw.forEach((key, value) {
      final k = key.toString();
      if (value is List) {
        // Ensure lists (including JSArray on web) become List<String>
        sanitized[k] = value.map((e) => e is String ? e : e.toString()).toList();
      } else if (value is Map) {
        sanitized[k] = Map<String, dynamic>.from(value.map((rk, rv) => MapEntry(rk.toString(), rv)));
      } else {
        sanitized[k] = value;
      }
    });

    return sanitized;
  }
}

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
  options: ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
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
  id: 'primary_goals',
  text: 'What are your current goals?',
  type: QuestionType.multiChoice,
  options: [
    'Improve productivity',
    'Learn new skills',
    'Advance career or studies',
    'Build personal projects',
    'Improve health or fitness',
    'Financial growth',
  ],
),
// willingness and resources
Question(
  id: 'willingness',
  text: 'What are you willing to do to achieve your goals?',
  type: QuestionType.multiChoice,
  options: [
    'Study or practice daily',
    'Wake up early',
    'Spend money on tools or courses',
    'Sacrifice leisure time',
    'Seek help or mentorship',
  ],
),

Question(
  id: 'resources',
  text: 'What resources do you already have access to?',
  type: QuestionType.multiChoice,
  options: [
    'Laptop or PC',
    'Smartphone',
    'Internet access',
    'Online courses or books',
    'Software or tools',
    'Community or mentors',
  ],
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
  id: 'productive_time',
  text: 'When do you feel most productive?',
  type: QuestionType.singleChoice,
  options: [
    'Morning',
    'Afternoon',
    'Evening',
    'Late night',
  ],
),
// Obstacle Motivation
Question(
  id: 'main_obstacles',
  text: 'What usually prevents you from completing tasks?',
  type: QuestionType.multiChoice,
  options: [
    'Procrastination',
    'Lack of clarity',
    'Low energy',
    'Distractions (phone/social media)',
    'Lack of motivation',
    'Overloaded schedule',
  ],
),

Question(
  id: 'motivation_type',
  text: 'What motivates you the most?',
  type: QuestionType.singleChoice,
  options: [
    'Seeing progress',
    'Rewards',
    'Positive feedback',
    'Fear of failure',
    'Long-term vision',
  ],
),
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
Question(id: 'goal', text: 'What are your goals you would like to achieve?'),

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

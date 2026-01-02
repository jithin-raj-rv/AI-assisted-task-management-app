import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import flutter_riverpod
import 'package:to_do_list/models/user_info_collection.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/AI/gemini.dart'; // Import gemini.dart // Assuming theme is used for styling

class UserInfoCollectionPage extends ConsumerStatefulWidget {
  const UserInfoCollectionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<UserInfoCollectionPage> createState() => _UserInfoCollectionPageState();
}

class _UserInfoCollectionPageState extends ConsumerState<UserInfoCollectionPage> {
  final UserInfoCollectionDB _db = UserInfoCollectionDB();
  final Map<String, dynamic> _userResponses = {}; // To store user answers

  @override
  void initState() {
    super.initState();
    _db.loadQuestions(); // Load questions when the widget initializes
    _userResponses.addAll(_db.loadUserResponses()); // Load existing user responses
  }

 Widget _buildQuestionWidget(Question question) {
  switch (question.type) {
    case QuestionType.text:
    case QuestionType.number:
      return TextFormField(
        initialValue: _userResponses[question.id] ?? '',
        decoration: InputDecoration(
          labelText: question.text,
          border: const OutlineInputBorder(),
        ),
        keyboardType: question.type == QuestionType.number
            ? TextInputType.number
            : TextInputType.text,
        onChanged: (value) {
          setState(() {
            _userResponses[question.id] = value;
          });
        },
      );

    case QuestionType.singleChoice:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(question.text, style: const TextStyle(fontSize: 16)),
          ),
          ...question.options!.map(
            (option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _userResponses[question.id],
              onChanged: (value) {
                setState(() {
                  _userResponses[question.id] = value;
                });
              },
            ),
          ),
        ],
      );

    case QuestionType.multiChoice:
      if (_userResponses[question.id] == null) {
        _userResponses[question.id] = <String>[];
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(question.text, style: const TextStyle(fontSize: 16)),
          ),
          ...question.options!.map(
            (option) => CheckboxListTile(
              title: Text(option),
              value: (_userResponses[question.id] as List<String>).contains(option),
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    (_userResponses[question.id] as List<String>).add(option);
                  } else {
                    (_userResponses[question.id] as List<String>).remove(option);
                  }
                });
              },
            ),
          ),
        ],
      );

  }
} //

String _generateInitialPrompt() {
  final StringBuffer prompt = StringBuffer();
  prompt.writeln("Here is some initial information about me:");

  for (var question in _db.questions) {
    final answer = _userResponses[question.id];
    if (answer != null) {
      prompt.writeln("${question.text}: ${answer.toString()}");
    }
  }

  prompt.writeln(
    "\nBased on this, analyze my personality, goals, constraints, clear all existing goals, personality,additional information, add new goals, personality,additional information based on the quiz. don't ask questions. just do it"
  );

  return prompt.toString();
}


  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide some information about yourself.',
                style: TextStyle(fontSize: 18, color: appTheme.primary),
              ),
              const SizedBox(height: 20),
              ..._db.questions.map((question) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildQuestionWidget(question,),
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _db.saveUserResponses(_userResponses);
                  print('User Responses: $_userResponses'); // For debugging

                  final String initialPrompt = _generateInitialPrompt();
                  final String geminiResponse = await sendChatMessage(ref, initialPrompt);
                  print('Gemini Initial Response: $geminiResponse');

                  Navigator.pushReplacementNamed(context, '/home'); // Assuming '/home' is your main page route
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
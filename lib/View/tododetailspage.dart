import 'package:flutter/material.dart';// Import Goal class
import 'package:intl/intl.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class Tododetailspage extends ConsumerStatefulWidget {
  final Todo todo;

  const Tododetailspage({super.key, required this.todo});

  @override
  ConsumerState<Tododetailspage> createState() => _TododetailspageState();
}

class _TododetailspageState extends ConsumerState<Tododetailspage> {
  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final todo = widget.todo;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: todo.taskName)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo.taskName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              todo.description ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Important: ${todo.importance == 'IMPORTANT' ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Urgent: ${todo.urgency == 'URGENT' ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Completed: ${todo.isCompleted ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Due Date: ${todo.dueDate != null ? DateFormat('MMM dd, yyyy').format(todo.dueDate!) : 'Not set'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Timeline Placeholder:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TODO: Implement actual timeline visualization here
            Container(
              height: 100,
              color: Colors.grey[300],
              child: const Center(
                child: Text('Timeline visualization will go here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

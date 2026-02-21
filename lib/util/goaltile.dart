import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:to_do_list/View/goaldetailspage.dart';
import 'package:to_do_list/models/goal_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/smalltextgradient.dart'; // Import GoalDetailsPage
import 'package:intl/intl.dart'; // Add this import

class GoalTile extends ConsumerWidget {
  const GoalTile({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    return Slidable(
      endActionPane: ActionPane(motion: const StretchMotion(), children: [
        SlidableAction(
          onPressed: (context) => onEdit(),
          backgroundColor: appTheme.secondary,
          icon: Icons.edit,
          borderRadius: BorderRadius.circular(20),
        ),
        SlidableAction(
          onPressed: (context) => onDelete(),
          backgroundColor: appTheme.tertiary,
          icon: Icons.delete,
          borderRadius: BorderRadius.circular(20),
        ),
      ]),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailsPage(goal: goal),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 16),
          child: Container(
            padding: const EdgeInsets.only(left: 20, top: 0, right: 20),
            height: 75,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appTheme.background, appTheme.primary, appTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // text with gradient
                Smalltextgradient(text: goal.title, fontsize: 20),
                Row( // New Row to group deadline and icon
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.background,
                      ),
                    ),
                    const SizedBox(width: 8), // Spacing between deadline and icon
                    if (goal.isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

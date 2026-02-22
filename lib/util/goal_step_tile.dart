import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:to_do_list/models/goal_step_model.dart';
import 'package:to_do_list/theme.dart';

class GoalStepTile extends ConsumerWidget {
  final GoalStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool isFirst;
  final bool isLast;

  const GoalStepTile({
    super.key,
    required this.step,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final isCompleted = step.isCompleted;

    return Slidable(
      key: Key(step.id!),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: appTheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.drag_handle),
                    onPressed: null,
                    color: appTheme.primary,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            
            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step text
                  Text(
                    step.stepText,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCompleted 
                          ? appTheme.primary.withOpacity(0.6)
                          : appTheme.primary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Step info
                  Row(
                    children: [
                      Text(
                        'Step ${step.sortOrder + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: appTheme.primary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              children: [
                // Move up button
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: isFirst ? null : onMoveUp,
                  color: isFirst 
                      ? Colors.grey.withOpacity(0.5)
                      : appTheme.primary,
                  disabledColor: Colors.grey.withOpacity(0.3),
                  splashRadius: 20,
                ),
                
                // Move down button
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: isLast ? null : onMoveDown,
                  color: isLast 
                      ? Colors.grey.withOpacity(0.5)
                      : appTheme.primary,
                  disabledColor: Colors.grey.withOpacity(0.3),
                  splashRadius: 20,
                ),
                
                // Toggle completion
                IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : appTheme.primary,
                  ),
                  onPressed: onToggleComplete,
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
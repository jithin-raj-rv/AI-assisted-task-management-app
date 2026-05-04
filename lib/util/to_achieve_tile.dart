import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/to_achieve_model.dart';
import 'package:to_do_list/theme.dart';

class ToAchieveTile extends ConsumerWidget {
  final ToAchieve toAchieve;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool isFirst;
  final bool isLast;

  const ToAchieveTile({
    super.key,
    required this.toAchieve,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: appTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: toAchieve.isCompleted ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: toAchieve.isCompleted,
          onChanged: (_) => onToggleComplete(),
          activeColor: Colors.green,
        ),
        title: Text(
          toAchieve.title,
          style: TextStyle(
            decoration: toAchieve.isCompleted ? TextDecoration.lineThrough : null,
            color: toAchieve.isCompleted ? Colors.grey : appTheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: toAchieve.targetDate != null
            ? Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(toAchieve.targetDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: toAchieve.isCompleted ? Colors.grey : appTheme.primary.withOpacity(0.7),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: appTheme.primary.withOpacity(0.7)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFirst)
                  InkWell(
                    onTap: onMoveUp,
                    child: Icon(Icons.arrow_drop_up, size: 24, color: appTheme.primary),
                  )
                else
                  const SizedBox(height: 24),
                if (!isLast)
                  InkWell(
                    onTap: onMoveDown,
                    child: Icon(Icons.arrow_drop_down, size: 24, color: appTheme.primary),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.drag_handle, color: appTheme.primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

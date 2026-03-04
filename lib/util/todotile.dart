import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:to_do_list/View/tododetailspage.dart';
import 'package:to_do_list/models/todo_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/smalltextgradient.dart';
import 'package:intl/intl.dart';

class Todotile extends ConsumerWidget {
  const Todotile(
      {super.key,
      required this.taskName,
      required this.taskcompleted,
      required this.click,
      required this.onpressed,
      required this.onEdit,
      required this.todo});

  final String taskName;
  final bool taskcompleted;
  final void Function(bool?)? click;
  final VoidCallback onpressed;
  final VoidCallback onEdit;
  final Todo todo;

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
          onPressed: (context) => onpressed(),
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
              builder: (context) => Tododetailspage(todo: todo),
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
                // checkbox
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: taskcompleted,
                        onChanged: click,
                        activeColor: Colors.black,
                      ),
                      // text with gradient
                      Flexible(
                        child: Smalltextgradient(
                          text: taskName,
                          fontsize: 20,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Importance indicator
                    if (todo.importance != 'NOT IMPORTANT')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: todo.importance == 'VERY IMPORTANT' 
                              ? Colors.red 
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          todo.importance == 'VERY IMPORTANT' ? '!!!' : '!',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Urgency indicator
                    if (todo.urgency != 'NOT URGENT')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: todo.urgency == 'VERY URGENT' 
                              ? Colors.red 
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          todo.urgency == 'VERY URGENT' ? '>>>' : '>>',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      todo.dueDate != null 
                          ? 'Due: ${DateFormat('MMM dd, yyyy').format(todo.dueDate!)}'
                          : 'No due date',
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.background,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (taskcompleted)
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

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:to_do_list/View/tododetailspage.dart';
import 'package:to_do_list/models/todo_model.dart';

class Todotile extends StatelessWidget {
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

  String _formatTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      final hours = difference.inHours % 24;
      return '${difference.inDays}d ${hours}h left';
    } else if (difference.inHours > 0) {
      final minutes = difference.inMinutes % 60;
      return '${difference.inHours}h ${minutes}m left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Less than a minute left';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(motion: const StretchMotion(), children: [
        SlidableAction(
          onPressed: (context) => onEdit(),
          backgroundColor: Colors.blue,
          icon: Icons.edit,
          borderRadius: BorderRadius.circular(20),
        ),
        SlidableAction(
          onPressed: (context) => onpressed(),
          backgroundColor: Colors.red,
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
            padding: const EdgeInsets.only(left: 20, top: 0),
            height: 75,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                // checkbox
        
                Checkbox(
                  value: taskcompleted,
                  onChanged: click,
                  activeColor: Colors.black,
                ),
                Text(
                  taskName,
                  style: TextStyle(
                      fontSize: 20,
                      decoration: taskcompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none),
                ),
                const Spacer(), // Pushes the next widget to the right
                Text(
                  _formatTimeRemaining(todo.dueDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700], // Adjust color as needed
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
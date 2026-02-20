import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

class NotificationTile extends StatefulWidget {
  final ScheduledNotification notification;
  final Function(ScheduledNotification) onDelete;
  final Function(ScheduledNotification) onEdit; // New callback
  final Function(ScheduledNotification, String) onFeedback; // New callback
  final Function(ScheduledNotification) onAiPrompt; // New callback

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onDelete,
    required this.onEdit, // New required parameter
    required this.onFeedback, // New required parameter
    required this.onAiPrompt, // New required parameter
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 15),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => widget.onEdit(widget.notification), // Call onEdit
              icon: Icons.edit,
              backgroundColor: Colors.blue.shade400, // Edit color
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) => widget.onDelete(widget.notification),
              icon: Icons.delete,
              backgroundColor: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.notification.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (widget.notification.body != null && widget.notification.body!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    widget.notification.body!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(widget.notification.scheduledDate.toLocal())}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
              // Display Reminder Type
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Type: ${widget.notification.reminderType.toString().split('.').last}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
              // Conditional display for options
              if (widget.notification.reminderType == ReminderType.option && widget.notification.options != null && widget.notification.options!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: widget.notification.options!.map((option) {
                      return ActionChip(
                        label: Text(option),
                        onPressed: () {
                          widget.onFeedback(widget.notification, option);
                        },
                      );
                    }).toList(),
                  ),
                ),
              // Conditional display for expected answer
              if (widget.notification.reminderType == ReminderType.answerBack)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _answerController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter answer',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          if (_answerController.text.isNotEmpty) {
                            widget.onFeedback(widget.notification, _answerController.text);
                            _answerController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              // Conditional display for AI Prompt
              if (widget.notification.reminderType == ReminderType.aiPrompt)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onAiPrompt(widget.notification),
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
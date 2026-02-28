import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class NotificationTile extends ConsumerStatefulWidget {
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
  ConsumerState<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<NotificationTile> {
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
    final appTheme = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 15),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => widget.onEdit(widget.notification), // Call onEdit
              icon: Icons.edit,
              backgroundColor: appTheme.secondary, // Edit color
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) => widget.onDelete(widget.notification),
              icon: Icons.delete,
              backgroundColor: appTheme.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appTheme.background, appTheme.primary, appTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Smalltextgradient(
                text: widget.notification.title,
                fontsize: 18,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.notification.body != null && widget.notification.body!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    widget.notification.body!,
                    style: TextStyle(
                      color: appTheme.background.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(widget.notification.scheduledDate.toLocal())}',
                  style: TextStyle(
                    color: appTheme.background.withOpacity(0.6),
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
                    color: appTheme.background.withOpacity(0.6),
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
                          style: TextStyle(color: appTheme.background),
                          decoration: InputDecoration(
                            hintText: 'Enter answer',
                            hintStyle: TextStyle(color: appTheme.background.withOpacity(0.5)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: appTheme.background),
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
                      icon: Icon(Icons.auto_awesome, color: appTheme.background),
                      label: Text('Ask AI', style: TextStyle(color: appTheme.background)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.secondary,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

class TimerPromptTile extends ConsumerWidget {
  final TimerPrompt timerPrompt;
  final Function(TimerPrompt) onDelete;
  final Function(TimerPrompt) onEdit;

  const TimerPromptTile({
    super.key,
    required this.timerPrompt,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25, top: 15),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onEdit(timerPrompt),
              icon: Icons.edit,
              backgroundColor: appTheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) => onDelete(timerPrompt),
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
                text: timerPrompt.prompt,
                fontsize: 18,
                overflow: TextOverflow.ellipsis,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getRecurrenceText(timerPrompt),
                  style: TextStyle(
                    color: appTheme.foreground.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
              if (timerPrompt.response != null && timerPrompt.response!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Response: ${timerPrompt.response}',
                    style: TextStyle(
                      color: appTheme.foreground.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecurrenceText(TimerPrompt prompt) {
    if (!prompt.isRecurring) {
      return 'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(prompt.scheduledTime.toLocal())}';
    }
    if (prompt.weekdays == null || prompt.weekdays!.isEmpty) {
      return 'Daily at ${DateFormat('hh:mm a').format(prompt.scheduledTime.toLocal())}';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(prompt.weekdays!)..sort();
    final dayNames = sortedDays.map((d) => days[d - 1]).join(', ');
    return 'Weekly ($dayNames) at ${DateFormat('hh:mm a').format(prompt.scheduledTime.toLocal())}';
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/viewmodels/timer_prompt_viewmodel.dart';
import 'package:to_do_list/util/tittlegradient.dart';
import 'package:to_do_list/models/timer_prompt_model.dart';
import 'package:to_do_list/main.dart';
import 'package:to_do_list/util/timer_prompt_tile.dart';
import 'package:to_do_list/util/timerpromptdialog.dart';

class TimerPromptPage extends ConsumerStatefulWidget {
  const TimerPromptPage({super.key});

  @override
  ConsumerState<TimerPromptPage> createState() => _TimerPromptPageState();
}

class _TimerPromptPageState extends ConsumerState<TimerPromptPage> {
  void _deletePrompt(TimerPrompt prompt) async {
    await ref.read(timerPromptViewModelProvider.notifier).deletePrompt(prompt.id);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final prompts = ref.watch(timerPromptViewModelProvider).prompts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: "Timer Prompts"),
      ),
      body: Container(
        color: appTheme.background,
        child: prompts.isEmpty
            ? Center(
                child: Text(
                  'No timer prompts scheduled.',
                  style: TextStyle(color: appTheme.primary),
                ),
              )
            : ListView.builder(
                itemCount: prompts.length,
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  return TimerPromptTile(
                    timerPrompt: prompt,
                    onDelete: _deletePrompt,
                    onEdit: (p) => showTimerPromptDialog(
                      context: context,
                      existingPrompt: p,
                      onSave: (prompt) async {
                        try {
                          final vm = ref.read(timerPromptViewModelProvider.notifier);
                          await vm.updatePrompt(p.id, prompt);
                        } catch (e) {
                          print('Error updating timer prompt: $e');
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTimerPromptDialog(
          context: context,
          onSave: (prompt) async {
            try {
              final vm = ref.read(timerPromptViewModelProvider.notifier);
              await vm.savePrompt(prompt);
            } catch (e) {
              print('Error saving timer prompt: $e');
            }
          },
        ),
        backgroundColor: appTheme.actionGradientStart,
        child: const Icon(Icons.add, color: Colors.white),
      ));
  }
}

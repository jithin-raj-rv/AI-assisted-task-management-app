import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class LongButton extends ConsumerWidget {
  const LongButton({
    super.key,
    required this.savetext,
    required this.onPressed,
  });

  final String savetext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appTheme.actionGradientStart,
            appTheme.actionGradientEnd
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: appTheme.elevatedButtonTheme.style,
        onPressed: onPressed,
        child: Center(
          child: Text(
            savetext,
            style: TextStyle(
              color: appTheme.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

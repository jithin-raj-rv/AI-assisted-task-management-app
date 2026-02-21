import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Buttonstyl extends ConsumerWidget {
  const Buttonstyl({
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
          colors: [appTheme.backgroundGradientStart, appTheme.backgroundGradientEnd],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          
          padding: const EdgeInsets.symmetric(vertical: 2),
        ),
        onPressed: onPressed,
        child: Center(
          child: Text(
            savetext,
            style: TextStyle(
              color: appTheme.accentGradientEnd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
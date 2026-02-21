import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Gradienttextfield extends ConsumerWidget {
  const Gradienttextfield({super.key,required this.controller,required this.text,this.obscureText=false});
  final TextEditingController controller;
  final String text;
  final bool obscureText;

  @override
  Widget build(BuildContext context ,WidgetRef ref ) {
    final appTheme = ref.watch(themeProvider);
return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appTheme.backgroundGradientStart, appTheme.backgroundGradientEnd],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: appTheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: text,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
    );
  }
}
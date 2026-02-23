import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Smalltextgradient extends ConsumerWidget {
  const Smalltextgradient({super.key, required this.text, required this.fontsize, this.maxLines = 1, this.overflow = TextOverflow.clip});
  final String text;
  final double fontsize;
  final int maxLines;
  final TextOverflow overflow;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [appTheme.textGradientEnd, appTheme.textGradientStart],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(fontSize: fontsize, color: Colors.white),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

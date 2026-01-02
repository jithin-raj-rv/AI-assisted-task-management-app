import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Smalltextgradient extends ConsumerWidget {
  const Smalltextgradient({super.key, required this.text,required this.fontsize});
  final String text;
  final double fontsize;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [appTheme.secondary, appTheme.secondaryGradient1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,style: TextStyle(fontSize: fontsize,color: Colors.white),// important for ShaderMask
      ),
    );
  }
}

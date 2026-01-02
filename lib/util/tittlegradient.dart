import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Tittlegradient extends ConsumerWidget {
  const Tittlegradient({super.key,required this.text});
  final String text;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [appTheme.primary, appTheme.primaryGradient1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,style: TextStyle(color: Colors.white), // important for ShaderMask
      ),
    );
  }
}

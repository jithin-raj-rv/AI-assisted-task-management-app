import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Icongradient extends ConsumerWidget {
  const Icongradient({super.key,required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return ShaderMask(
              blendMode: BlendMode.srcIn,
              child: Icon(icon),
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [appTheme.primary, appTheme.primaryGradient1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
            );
  }
}

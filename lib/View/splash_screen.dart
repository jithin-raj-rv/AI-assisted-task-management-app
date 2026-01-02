import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:to_do_list/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Navigate to home after the splash animation completes
    _animationController.forward().then((_) {
      Navigator.of(context).pushReplacementNamed('/userInfoCollection');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: appTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation - using a built-in animation
            Lottie.network(
              'https://lottie.host/d2355f57-cd05-4bed-9f04-eb6fb064625a/NaaE0qhAGw.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              repeat: false,
              controller: _animationController,
              onLoaded: (composition) {
                _animationController.duration = composition.duration;
              },
            ),
            const SizedBox(height: 30),
            Text(
              'Todo List',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: appTheme.primaryGradient1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your tasks efficiently',
              style: TextStyle(
                fontSize: 14,
                color: appTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

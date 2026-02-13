import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_list/main.dart'; // For UserInfoCollectionDialog

class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  Future<void> _skipOnboarding() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pop(); // Close the modal
    }
  }

  void _startQuiz() {
    // Close current modal and show UserInfoCollectionDialog
    Navigator.of(context).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UserInfoCollectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Your Personal Task Manager!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'It looks like you don\'t have any tasks, goals, or reminders set up yet. '
              'Would you like to answer a few questions so our AI can create personalized content for you?',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startQuiz,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Yes, Let\'s Get Started!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipOnboarding,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Skip for Now',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class OfflineUtils {
  static void showOfflinePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Offline Mode',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This action requires an internet connection. Please connect to the internet and try again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

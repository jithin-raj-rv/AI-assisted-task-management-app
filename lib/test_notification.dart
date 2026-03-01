import 'package:flutter/material.dart';
import 'package:to_do_list/Notification/notification_service.dart';
import 'package:to_do_list/models/scheduled_notification_model.dart';

class TestNotificationPage extends StatefulWidget {
  const TestNotificationPage({super.key});

  @override
  State<TestNotificationPage> createState() => _TestNotificationPageState();
}

class _TestNotificationPageState extends State<TestNotificationPage> {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.init();
      setState(() {
        _isInitialized = true;
      });
      
      // Request permission
      final granted = await _notificationService.requestNotificationPermission();
      setState(() {
        _isPermissionGranted = granted;
      });
      
      if (granted) {
        print('✅ Notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _testInstantNotification() async {
    if (!_isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant notification permission first')),
      );
      return;
    }

    try {
      await _notificationService.showNotification(
        id: 1,
        title: 'Test Instant Notification',
        body: 'This is a test notification to verify the system is working!',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instant notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    }
  }

  Future<void> _testScheduledNotification() async {
    if (!_isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant notification permission first')),
      );
      return;
    }

    try {
      final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
      final testNotification = ScheduledNotification(
        id: 'test_2',
        title: 'Test Scheduled Notification',
        body: 'This notification will appear in 10 seconds!',
        scheduledDate: scheduledDate,
        reminderType: ReminderType.basic,
        userId: 'test_user',
        payload: 'test_payload_2'
      );

      await _notificationService.showScheduledNotification(
        notification: testNotification,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled notification set for 10 seconds!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Notification Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service Initialized:'),
                          _isInitialized
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Permission Granted:'),
                          _isPermissionGranted
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _testInstantNotification,
                child: const Text('Test Instant Notification'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _testScheduledNotification,
                child: const Text('Test Scheduled Notification (10s)'),
              ),
              const SizedBox(height: 30),
              const Text(
                'Check the console for detailed logs',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
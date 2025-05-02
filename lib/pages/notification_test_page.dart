import 'package:flutter/material.dart';
import 'package:Emplbee/services/notification_service.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  String? _fcmToken;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    final token = await _notificationService.getFCMToken();
    setState(() {
      _fcmToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM Token:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(_fcmToken ?? 'Loading...'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _getFCMToken,
              child: const Text('Refresh Token'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Copy the FCM token above\n'
              '2. Go to Firebase Console\n'
              '3. Navigate to Messaging\n'
              '4. Send a test message using this token',
            ),
          ],
        ),
      ),
    );
  }
}

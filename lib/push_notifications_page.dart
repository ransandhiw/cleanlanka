import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationsPage extends StatefulWidget {
  const PushNotificationsPage({super.key});

  @override
  State<PushNotificationsPage> createState() => _PushNotificationsPageState();
}

class _PushNotificationsPageState extends State<PushNotificationsPage> {
  String? _fcmToken;
  String _notificationTitle = '';
  String _notificationBody = '';
  bool _isTokenLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _setupMessageListener();
  }

  Future<void> _loadFCMToken() async {
    setState(() {
      _isTokenLoading = true;
    });
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token;
        _isTokenLoading = false;
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'Failed to get token: $e';
        _isTokenLoading = false;
      });
    }
  }

  void _setupMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notificationTitle = message.notification?.title ?? 'No title';
        _notificationBody = message.notification?.body ?? 'No body';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Your FCM Token:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _isTokenLoading
                ? const CircularProgressIndicator()
                : SelectableText(
                    _fcmToken ?? 'No token available',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadFCMToken,
              child: const Text("Refresh Token"),
            ),
            const Divider(height: 40),
            const Text(
              'Last Received Notification:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Title: $_notificationTitle'),
            const SizedBox(height: 5),
            Text('Body: $_notificationBody'),
          ],
        ),
      ),
    );
  }
}

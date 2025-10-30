import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // <--- ADD THIS IMPORT

import 'package:clean_lanka/login_screen.dart';
import 'package:clean_lanka/dashboard_screen.dart';
import 'package:clean_lanka/common_widgets.dart';
import 'package:clean_lanka/suggest_point_screen.dart';
import 'package:clean_lanka/app_notices_screen.dart';
import 'package:clean_lanka/forgot_password_screen.dart';
import 'package:clean_lanka/profile_screen.dart';
import 'package:clean_lanka/vote_suggestions_screen.dart';
import 'package:clean_lanka/push_notifications_page.dart'; // optional test screen

import 'firebase_options.dart';

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Ensure Firebase is initialized for background
  print("🔔 Background message received: ${message.messageId}");

  // Display background message as a local notification (optional, but good for testing)
  if (message.notification != null) {
    _showLocalNotification(message); // Call local notification display
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lwbldxzvutnwdjapmgqu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3YmxkeHp2dXRud2RqYXBtZ3F1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4ODg1MDcsImV4cCI6MjA2NzQ2NDUwN30.K2cUdPhProaNIcvCP-qttuCI3HSQ1-6Kays5gtZPf20',
  );

  // Request permissions & setup FCM listeners
  await _setupFCM();

  runApp(const MyApp());
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // --- 1. Request Notification Permissions ---
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Push notification permission granted');
  } else {
    print('❌ Push notification permission denied');
  }

  // --- 2. Initialize Local Notifications ---
  // This is for displaying notifications when the app is in the foreground.
  await _initLocalNotifications();

  // --- 3. Get the token (print for testing or use in Supabase for sending) ---
  String? token = await messaging.getToken();
  print("🔥 FCM Token: $token");

  // --- 4. Foreground message handling ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message received: ${message.notification?.title}');
    // <--- CRITICAL: Display foreground messages using local notifications
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  });

  // --- 5. When user taps notification and app is opened ---
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📲 Notification clicked: ${message.notification?.title}');
    // Navigate if needed (e.g., to a specific page based on message.data)
  });

  // --- 6. Handle initial message when app is launched from terminated state ---
  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App launched from terminated state by notification: ${message.notification?.title}');
      // Handle navigation based on message.data if needed
    }
  });
}

/// Initializes Flutter Local Notifications plugin for foreground notifications.
Future<void> _initLocalNotifications() async {
  // Android settings
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app icon here

  // iOS settings
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false, // Permissions handled by FirebaseMessaging
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    // onDidReceiveNotificationResponse handles taps on notifications when app is in foreground
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Local notification tapped: ${response.payload}');
      // You can handle navigation here based on response.payload
    },
  );
}

/// Displays a local notification when an FCM message is received in the foreground or background.
Future<void> _showLocalNotification(RemoteMessage message) async {
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;
  // You can pass custom data from message.data as payload if needed
  final String? payload = message.data['custom_data']?.toString();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // <--- IMPORTANT: Must match the channel ID in AndroidManifest.xml
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker', // For older Android versions
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode, // Unique ID for the notification
    title ?? 'No Title',
    body ?? 'No Body',
    platformDetails,
    payload: payload, // Pass custom data as payload
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Lanka Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: secondaryBlue,
          secondary: primaryGreen,
        ),
      ),
      home: Supabase.instance.client.auth.currentUser != null
          ? const DashboardScreen()
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/suggest_point': (context) => const SuggestPointScreen(),
        '/app_notices': (context) => const AppNoticesScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/vote_suggestions': (context) => const VoteSuggestionsScreen(),
        '/push_notification_test': (context) => const PushNotificationsPage(), // optional
      },
    );
  }
}

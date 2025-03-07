import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Request permission first
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // if (Platform.isIOS) {
      //   print('iOS platform detected, waiting for APNS token...');
      //   // Wait for APNS token with retries
      //   String? apnsToken;
      //   int maxRetries = 5;
      //   int currentRetry = 0;

      //   while (currentRetry < maxRetries && apnsToken == null) {
      //     try {
      //       apnsToken = await _messaging.getAPNSToken();
      //       if (apnsToken == null) {
      //         currentRetry++;
      //         print(
      //             'APNS token not available, attempt $currentRetry of $maxRetries');
      //         await Future.delayed(const Duration(seconds: 2));
      //       } else {
      //         print('APNS Token obtained: $apnsToken');
      //         break;
      //       }
      //     } catch (e) {
      //       currentRetry++;
      //       print('Error getting APNS token: $e');
      //       await Future.delayed(const Duration(seconds: 2));
      //     }
      //   }

      //   if (apnsToken == null) {
      //     print('Failed to obtain APNS token after $maxRetries attempts');
      //     if (Platform.isIOS) {
      //       return;
      //     }
      //   }
      // }

      // Get FCM token only after ensuring APNS token is available on iOS
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('FCM Token obtained: $_fcmToken');
      } else {
        print('Failed to obtain FCM token');
      }

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle token refresh
      _messaging.onTokenRefresh.listen((String token) {
        _fcmToken = token;
        print('FCM Token refreshed: $_fcmToken');
        // TODO: Send this token to your backend
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      // Continue initialization even if there's an error
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
        // Handle notification click
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    if (message.notification != null) {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Handling background message: ${message.messageId}');
    // Handle the background message
  }

  // Method to manually get the current FCM token
  Future<String?> getFCMToken() async {
    _fcmToken = await _messaging.getToken();
    return _fcmToken;
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
}

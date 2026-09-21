import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('Handling background FCM message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for critical app notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request Permissions (iOS & Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('User notification permission status: ${settings.authorizationStatus}');

    // 3. Configure Local Notifications for Foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    // 4. Create Android High Importance Channel
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }

    // 5. Set FCM Foreground Presentation Options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received: ${message.notification?.title}');
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 7. Listen to App Taps from Background / Terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification tap (background): ${message.data}');
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification tap (killed): ${initialMessage.data}');
    }
  }

  /// Saves or updates the current user's FCM token in Firestore
  Future<void> saveFcmToken(String userId) async {
    if (userId.isEmpty) return;

    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token successfully saved for user: $userId');
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Warning: Could not save FCM token for $userId: $e');
    }
  }

  /// Sends both an in-app Firestore notification document and a push notification payload
  Future<void> sendNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String type, // 'message' or 'follow'
    required String title,
    required String body,
    Map<String, dynamic>? dataPayload,
  }) async {
    if (recipientId.isEmpty || recipientId == senderId) return;

    try {
      // 1. Create In-App Notification Record in Firestore
      final notifRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(recipientId)
          .collection('notifications')
          .doc();

      final notifData = {
        'id': notifRef.id,
        'recipientId': recipientId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'type': type,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        ...?dataPayload,
      };

      await notifRef.set(notifData);

      // 2. Fetch Recipient FCM Token to dispatch Push Notification
      final recipientSnap = await _firestore.collection(AppConstants.usersCollection).doc(recipientId).get();
      final fcmToken = recipientSnap.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Send FCM HTTP Push Request
        await _sendFcmPushMessage(
          token: fcmToken,
          title: title,
          body: body,
          data: {
            'type': type,
            'senderId': senderId,
            'senderName': senderName,
            ...?dataPayload,
          },
        );
      }
    } catch (e) {
      debugPrint('Warning: Failed to deliver notification to $recipientId: $e');
    }
  }

  /// Internal FCM HTTP dispatch
  Future<void> _sendFcmPushMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Post FCM notification payload for native OS system tray handling
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': token,
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': data,
        }),
      );
      debugPrint('FCM Push notification sent. Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('FCM push send error: $e');
    }
  }
}

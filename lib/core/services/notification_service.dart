import 'dart:async';
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
  StreamSubscription? _notificationSubscription;
  String? _activeUserId;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for critical app notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Register Background Handler (Native only)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

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

        if (notification != null) {
          showLocalBanner(
            title: notification.title ?? 'New Notification',
            body: notification.body ?? '',
            data: message.data,
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
    } catch (e) {
      debugPrint('NotificationService initialization notice: $e');
    }
  }

  /// Starts real-time listening for in-app notifications for the logged-in user
  void startListeningToUserNotifications(String userId) {
    if (userId.isEmpty || _activeUserId == userId) return;
    _activeUserId = userId;
    _notificationSubscription?.cancel();

    _notificationSubscription = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final senderId = data['senderId'] as String? ?? '';
            // Only notify if notification is from another user
            if (senderId != userId) {
              final title = data['title'] as String? ?? 'New Notification';
              final body = data['body'] as String? ?? '';
              showLocalBanner(title: title, body: body, data: data);
            }
          }
        }
      }
    }, onError: (e) {
      debugPrint('Notification snapshot error: $e');
    });
  }

  /// Safely converts Firestore map values (including Timestamps) into JSON-encodable primitives
  Map<String, dynamic> _cleanDataForJson(Map<String, dynamic> rawMap) {
    final Map<String, dynamic> clean = {};
    rawMap.forEach((key, value) {
      if (value is Timestamp) {
        clean[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        clean[key] = value.toIso8601String();
      } else if (value is num || value is String || value is bool) {
        clean[key] = value;
      } else if (value != null) {
        clean[key] = value.toString();
      }
    });
    return clean;
  }

  /// Displays high-priority local notification banner
  Future<void> showLocalBanner({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final safePayload = data != null ? jsonEncode(_cleanDataForJson(data)) : null;

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: safePayload,
      );
    } catch (e) {
      debugPrint('Notice: Local notification banner display skipped ($e)');
    }
  }

  /// Saves or updates the current user's FCM token in Firestore and starts notification listener
  Future<void> saveFcmToken(String userId) async {
    if (userId.isEmpty) return;

    startListeningToUserNotifications(userId);

    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token successfully saved for user: $userId');
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Notice: FCM token registration skipped or unsupported on platform ($e)');
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

      // 2. Fetch Recipient FCM Token to dispatch Push Notification if token exists
      final recipientSnap = await _firestore.collection(AppConstants.usersCollection).doc(recipientId).get();
      final fcmToken = recipientSnap.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
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
      final safeData = _cleanDataForJson(data);

      await http.post(
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
          'data': safeData,
        }),
      );
    } catch (e) {
      debugPrint('FCM push send notice: $e');
    }
  }
}

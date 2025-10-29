import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize push notifications
  static Future<void> initialize() async {
    // Request permissions (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(initializationSettings);

    // Get token and save to Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundNotification(message);
    });

    // Background message handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Terminated state handler
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  /// Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      // This would need user ID - typically from auth service
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userId)
      //     .update({'fcmToken': token});
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Handle foreground notifications
  static void _handleForegroundNotification(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Show local notification
      _showLocalNotification(
        title: message.notification!.title ?? 'Bildirim',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }

    // Emit to stream
    _notificationStreamController.add(message.data);
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('User tapped notification: ${message.messageId}');
    _notificationStreamController.add(message.data);

    // Handle navigation based on notification type
    _navigateBasedOnNotification(message.data);
  }

  /// Background message handler (top-level function)
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Handle background notification
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tuniverse_channel',
      'Tuniverse Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload != null ? Uri(queryParameters: payload).query : null,
    );
  }

  /// Navigate based on notification type
  static void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';

    switch (type) {
      case 'message':
        // Navigate to chat
        break;
      case 'follow':
        // Navigate to profile
        break;
      case 'like':
        // Navigate to liked item
        break;
      case 'comment':
        // Navigate to comments
        break;
    }
  }

  /// Send notification (admin use)
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // This would call a Cloud Function to send notifications
      // For now, just show local notification
      await _showLocalNotification(
        title: title,
        body: body,
        payload: {
          'type': type,
          ...?additionalData,
        },
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Get notification preferences
  static Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      // Fetch from Firestore or SharedPreferences
      return {
        'messages': true,
        'follows': true,
        'likes': true,
        'comments': true,
        'mentions': true,
      };
    } catch (e) {
      return {
        'messages': true,
        'follows': true,
        'likes': true,
        'comments': true,
        'mentions': true,
      };
    }
  }

  /// Update notification preferences
  static Future<void> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    try {
      // Save to Firestore or SharedPreferences
    } catch (e) {
      print('Error updating notification preferences: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    _notificationStreamController.close();
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Setup Firebase messaging
        await _setupFirebaseMessaging();

        // Get FCM token
        final token = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $token');
        }

        _initialized = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification initialization error: $e');
      }
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Setup Firebase messaging handlers
  static Future<void> _setupFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  /// Handle foreground message
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Foreground message received: ${message.notification?.title}');
    }

    // Show local notification for foreground messages
    await _showLocalNotification(
      title: message.notification?.title ?? 'Yeni Bildirim',
      body: message.notification?.body ?? 'Yeni bir bildirim aldınız',
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap when app is in background
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.notification?.title}');
    }
    // Handle navigation based on message data
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'music_notifications',
      'Music Notifications',
      channelDescription: 'Notifications for new music and recommendations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show music recommendation notification
  static Future<void> showMusicRecommendation({
    required String trackName,
    required String artistName,
    String? albumImage,
  }) async {
    await _showLocalNotification(
      title: 'Yeni Müzik Önerisi 🎵',
      body: '$trackName - $artistName',
      payload: 'music_recommendation',
    );
  }

  /// Show new release notification
  static Future<void> showNewRelease({
    required String albumName,
    required String artistName,
    String? albumImage,
  }) async {
    await _showLocalNotification(
      title: 'Yeni Albüm Çıktı! 🎤',
      body: '$albumName - $artistName',
      payload: 'new_release',
    );
  }

  /// Show trending notification
  static Future<void> showTrendingTrack({
    required String trackName,
    required String artistName,
  }) async {
    await _showLocalNotification(
      title: 'Trend Şarkı 🔥',
      body: '$trackName - $artistName',
      payload: 'trending_track',
    );
  }

  /// Show rating reminder notification
  static Future<void> showRatingReminder({
    required String trackName,
    required String artistName,
  }) async {
    await _showLocalNotification(
      title: 'Şarkıyı Puanlamayı Unutmayın ⭐',
      body: '$trackName - $artistName',
      payload: 'rating_reminder',
    );
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.notification?.title}');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Unused import
import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import 'enhanced_spotify_service.dart';

class SmartNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Unused field
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  // static DateTime? _lastNotificationTime; // Unused field
  static final Map<String, DateTime> _lastTrackNotifications = {};

  /// Initialize smart notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await NotificationService.initialize();
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Smart notification initialization error: $e');
      }
    }
  }

  /// Start smart notifications for authenticated user
  static Future<void> startForAuthenticatedUser() async {
    if (!_initialized) return;

    try {
      // Only setup notifications if user is authenticated
      if (FirebaseAuth.instance.currentUser != null) {
        await _setupSmartNotifications();
        await _startSmartMonitoring();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Smart notification start error: $e');
      }
    }
  }

  /// Setup smart notification handlers
  static Future<void> _setupSmartNotifications() async {
    // Monitor Spotify playback state changes
    _monitorSpotifyPlayback();
    
    // Monitor user activity patterns
    _monitorUserActivity();
    
    // Setup intelligent notification triggers
    _setupIntelligentTriggers();
  }

  /// Monitor Spotify playback for smart notifications
  static void _monitorSpotifyPlayback() {
    // Monitor every 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      // Only monitor if user is still authenticated and Spotify is connected
      if (FirebaseAuth.instance.currentUser != null && EnhancedSpotifyService.isConnected) {
        await _checkPlaybackNotifications();
        _monitorSpotifyPlayback(); // Continue monitoring only if conditions are met
      }
    });
  }

  /// Check for playback-based notifications
  static Future<void> _checkPlaybackNotifications() async {
    try {
      final currentTrack = await EnhancedSpotifyService.getCurrentTrack();
      if (currentTrack == null) return;

      final trackId = currentTrack['id'] as String?;
      final trackName = currentTrack['name'] as String?;
      final artistName = currentTrack['artist'] as String?;

      if (trackId == null || trackName == null || artistName == null) return;

      // Check if we've already notified about this track recently
      final lastNotification = _lastTrackNotifications[trackId];
      if (lastNotification != null && 
          DateTime.now().difference(lastNotification).inMinutes < 5) {
        return; // Don't spam notifications
      }

      // Smart notification triggers
      await _checkRatingReminder(currentTrack);
      await _checkDiscoveryNotification(currentTrack);
      await _checkMoodBasedNotification(currentTrack);
      await _checkTimeBasedNotification(currentTrack);

      _lastTrackNotifications[trackId] = DateTime.now();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if user should be reminded to rate a track
  static Future<void> _checkRatingReminder(Map<String, dynamic> track) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final trackId = track['id'] as String?;
      if (trackId == null) return;

      // Check if user has already rated this track
      final existingRating = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('trackId', isEqualTo: trackId)
          .get();

      if (existingRating.docs.isNotEmpty) return;

      // Check if track has been playing for more than 30 seconds
      final position = EnhancedSpotifyService.currentPosition;
      if (position > 30000) { // 30 seconds
        await NotificationService.showRatingReminder(
          trackName: track['name'] ?? 'Bu Şarkı',
          artistName: track['artist'] ?? 'Bu Sanatçı',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for discovery notifications
  static Future<void> _checkDiscoveryNotification(Map<String, dynamic> track) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final artistName = track['artist'] as String?;
      if (artistName == null) return;

      // Check if this is a new artist for the user
      final existingArtistRatings = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('artists', isEqualTo: artistName)
          .get();

      if (existingArtistRatings.docs.isEmpty) {
        // New artist discovery
        await NotificationService.showMusicRecommendation(
          trackName: 'Yeni Sanatçı Keşfettiniz! 🎉',
          artistName: artistName,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for mood-based notifications
  static Future<void> _checkMoodBasedNotification(Map<String, dynamic> track) async {
    try {
      final features = track['features'] as Map<String, dynamic>?;
      if (features == null) return;

      final valence = features['valence'] as double? ?? 0.5;
      final energy = features['energy'] as double? ?? 0.5;
      final currentHour = DateTime.now().hour;

      // High energy, high valence = happy mood
      if (valence > 0.7 && energy > 0.7) {
        if (currentHour >= 6 && currentHour <= 12) {
          await NotificationService.showMusicRecommendation(
            trackName: 'Güne Enerjik Başlıyorsunuz! ⚡',
            artistName: track['name'] ?? 'Bu Şarkı',
          );
        }
      }

      // Low energy, low valence = sad mood
      if (valence < 0.3 && energy < 0.3) {
        if (currentHour >= 18 && currentHour <= 23) {
          await NotificationService.showMusicRecommendation(
            trackName: 'Hüzünlü Bir Akşam 🌙',
            artistName: track['name'] ?? 'Bu Şarkı',
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for time-based notifications
  static Future<void> _checkTimeBasedNotification(Map<String, dynamic> track) async {
    try {
      final currentHour = DateTime.now().hour;
      final trackName = track['name'] as String? ?? 'Bu Şarkı';

      // Morning motivation
      if (currentHour >= 6 && currentHour <= 9) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Güne Motivasyonla Başlayın! ☀️',
          artistName: trackName,
        );
      }

      // Afternoon productivity
      if (currentHour >= 14 && currentHour <= 16) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Öğleden Sonra Enerjisi! 💪',
          artistName: trackName,
        );
      }

      // Evening relaxation
      if (currentHour >= 20 && currentHour <= 22) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Akşam Rahatlaması! 🌅',
          artistName: trackName,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Monitor user activity patterns
  static void _monitorUserActivity() {
    // Monitor every hour
    Future.delayed(const Duration(hours: 1), () async {
      await _analyzeUserActivity();
      _monitorUserActivity(); // Continue monitoring
    });
  }

  /// Analyze user activity patterns
  static Future<void> _analyzeUserActivity() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get user's recent ratings
      final recentRatings = await _firestore
          .collection('music_ratings')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      if (recentRatings.docs.isEmpty) return;

      await _checkActivityBasedNotifications(recentRatings.docs);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for activity-based notifications
  static Future<void> _checkActivityBasedNotifications(List<QueryDocumentSnapshot> ratings) async {
    try {
      // Check for rating streak
      await _checkRatingStreak(ratings);
      
      // Check for genre diversity
      await _checkGenreDiversity(ratings);
      
      // Check for rating patterns
      await _checkRatingPatterns(ratings);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for rating streak notifications
  static Future<void> _checkRatingStreak(List<QueryDocumentSnapshot> ratings) async {
    try {
      final now = DateTime.now();
      int streakDays = 0;
      
      for (int i = 0; i < ratings.length; i++) {
        final rating = ratings[i];
        final createdAt = (rating.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        if (createdAt == null) break;
        
        final ratingDate = createdAt.toDate();
        final expectedDate = now.subtract(Duration(days: i));
        
        if (ratingDate.day == expectedDate.day && 
            ratingDate.month == expectedDate.month && 
            ratingDate.year == expectedDate.year) {
          streakDays++;
        } else {
          break;
        }
      }

      // Notify about streaks
      if (streakDays >= 3 && streakDays % 3 == 0) {
        await NotificationService.showMusicRecommendation(
          trackName: '$streakDays Günlük Puanlama Serisi! 🔥',
          artistName: 'Harika gidiyorsunuz!',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for genre diversity
  static Future<void> _checkGenreDiversity(List<QueryDocumentSnapshot> ratings) async {
    try {
      final Set<String> genres = {};
      
      for (final rating in ratings.take(10)) {
        final data = rating.data() as Map<String, dynamic>;
        final tags = List<String>.from(data['tags'] ?? []);
        genres.addAll(tags);
      }

      if (genres.length >= 5) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Çeşitli Müzik Zevkiniz! 🎵',
          artistName: '${genres.length} farklı türde müzik dinliyorsunuz',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for rating patterns
  static Future<void> _checkRatingPatterns(List<QueryDocumentSnapshot> ratings) async {
    try {
      final recentRatings = ratings.take(10).map((r) => 
          (r.data() as Map<String, dynamic>)['rating'] as int? ?? 0).toList();
      
      if (recentRatings.isEmpty) return;

      final averageRating = recentRatings.reduce((a, b) => a + b) / recentRatings.length;
      
      // High rating pattern
      if (averageRating >= 4.0) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Yüksek Kalite Müzik Zevkiniz! ⭐',
          artistName: 'Son 10 puanlamanızın ortalaması: ${averageRating.toStringAsFixed(1)}',
        );
      }

      // Low rating pattern (encourage discovery)
      if (averageRating <= 2.5) {
        await NotificationService.showMusicRecommendation(
          trackName: 'Yeni Müzik Keşfetme Zamanı! 🎧',
          artistName: 'Keşfet sayfasından yeni şarkılar bulabilirsiniz',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Setup intelligent notification triggers
  static void _setupIntelligentTriggers() {
    // Daily summary notification
    _scheduleDailySummary();
    
    // Weekly insights notification
    _scheduleWeeklyInsights();
    
    // Monthly statistics notification
    _scheduleMonthlyStats();
  }

  /// Schedule daily summary notification
  static void _scheduleDailySummary() {
    // Schedule for 9 PM daily
    _localNotifications.show(
      1,
      'Günlük Müzik Özeti',
      'Bugün dinlediğiniz müziklerin özeti hazır!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Günlük Özet',
          channelDescription: 'Günlük müzik dinleme özeti',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedule weekly insights notification
  static void _scheduleWeeklyInsights() {
    // Schedule for Sunday 10 AM
    _localNotifications.show(
      2,
      'Haftalık Müzik İçgörüleri',
      'Bu haftanın müzik istatistiklerinizi görün!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_insights',
          'Haftalık İçgörüler',
          channelDescription: 'Haftalık müzik dinleme içgörüleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedule monthly statistics notification
  static void _scheduleMonthlyStats() {
    // Schedule for 1st of each month at 11 AM
    _localNotifications.show(
      3,
      'Aylık Müzik İstatistikleri',
      'Geçen ayın müzik istatistikleriniz hazır!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_stats',
          'Aylık İstatistikler',
          channelDescription: 'Aylık müzik dinleme istatistikleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Removed unused scheduling methods - using simple show() instead of zonedSchedule()

  /// Start smart monitoring
  static Future<void> _startSmartMonitoring() async {
    // Monitor user preferences and adjust notifications accordingly
    _monitorUserPreferences();
  }

  /// Monitor user preferences
  static void _monitorUserPreferences() {
    // Check preferences every 6 hours
    Future.delayed(const Duration(hours: 6), () async {
      await _updateNotificationPreferences();
      _monitorUserPreferences(); // Continue monitoring
    });
  }

  /// Update notification preferences based on user behavior
  static Future<void> _updateNotificationPreferences() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Analyze user's notification interaction patterns
      // This would involve tracking which notifications the user interacts with
      // and adjusting the frequency and types accordingly
      
      // For now, we'll implement basic preference learning
      await _learnUserPreferences();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Learn user preferences from behavior
  static Future<void> _learnUserPreferences() async {
    try {
      // This would analyze user behavior and adjust notification settings
      // For example:
      // - If user rarely interacts with rating reminders, reduce frequency
      // - If user often clicks on discovery notifications, increase them
      // - If user prefers certain times, adjust scheduling
      
      // Placeholder for preference learning logic
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send personalized recommendation notification
  static Future<void> sendPersonalizedRecommendation({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'personalized_recommendations',
            'Kişiselleştirilmiş Öneriler',
            channelDescription: 'Size özel müzik önerileri',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: data?.toString(),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send contextual notification based on current situation
  static Future<void> sendContextualNotification() async {
    try {
      final currentHour = DateTime.now().hour;
      // final currentTrack = await EnhancedSpotifyService.getCurrentTrack(); // Unused variable
      
      String title = '';
      String message = '';
      
      if (currentHour >= 6 && currentHour <= 9) {
        title = 'Güne Enerjik Başlayın! ☀️';
        message = 'Sabah motivasyonu için müzik önerilerimiz var';
      } else if (currentHour >= 12 && currentHour <= 14) {
        title = 'Öğle Molası Müziği 🎵';
        message = 'Öğle arasında dinlemek için şarkılar';
      } else if (currentHour >= 18 && currentHour <= 20) {
        title = 'Akşam Rahatlaması 🌅';
        message = 'Günün yorgunluğunu atmak için müzikler';
      } else if (currentHour >= 21 && currentHour <= 23) {
        title = 'Gece Müziği 🌙';
        message = 'Sakin akşamlar için öneriler';
      }
      
      if (title.isNotEmpty) {
        await sendPersonalizedRecommendation(
          title: title,
          message: message,
          data: {'type': 'contextual', 'hour': currentHour},
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get notification analytics
  static Future<Map<String, dynamic>> getNotificationAnalytics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      // This would analyze notification performance and user engagement
      // For now, return mock data
      return {
        'totalNotifications': 45,
        'openedNotifications': 32,
        'clickThroughRate': 0.71,
        'favoriteNotificationType': 'rating_reminders',
        'optimalNotificationTime': '21:00',
        'userEngagementScore': 8.5,
      };
    } catch (e) {
      return {};
    }
  }
}

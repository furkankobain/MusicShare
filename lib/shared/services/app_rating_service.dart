import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

import '../widgets/rating/app_rating_dialog.dart';

class AppRatingService {
  static const String _lastRatingRequestKey = 'last_rating_request';
  static const String _ratingDismissedKey = 'rating_dismissed';
  static const String _hasRatedKey = 'has_rated';
  static const int _daysBetweenRequests = 30; // 30 gün bekle
  static const int _minAppUsageDays = 7; // En az 7 gün kullanım
  static const int _minRatingThreshold = 4; // 4+ puan verirse Play Store'a yönlendir

  // Uygulama kullanım süresini kontrol et
  static Future<bool> shouldShowRatingDialog() async {
    try {
      // SharedPreferences'ı cache'den al
      final prefs = await SharedPreferences.getInstance();
      
      // Eğer daha önce puan verildiyse tekrar gösterme
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      if (hasRated) return false;
      
      // Eğer kullanıcı "Daha Sonra" dediyse ve 30 gün geçmediyse
      final lastRequest = prefs.getInt(_lastRatingRequestKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLastRequest = (now - lastRequest) / (1000 * 60 * 60 * 24);
      
      if (daysSinceLastRequest < _daysBetweenRequests) {
        final ratingDismissed = prefs.getBool(_ratingDismissedKey) ?? false;
        if (ratingDismissed) return false;
      }
      
      // Uygulama ilk açılış tarihini kontrol et
      final firstLaunch = prefs.getInt('first_launch') ?? now;
      final daysSinceFirstLaunch = (now - firstLaunch) / (1000 * 60 * 60 * 24);
      
      if (daysSinceFirstLaunch < _minAppUsageDays) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // İlk açılış tarihini kaydet
  static Future<void> recordFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Eğer daha önce kaydedilmemişse kaydet
      if (!prefs.containsKey('first_launch')) {
        await prefs.setInt('first_launch', now);
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Rating dialog gösterildiğini kaydet
  static Future<void> recordRatingRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastRatingRequestKey, now);
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Kullanıcı "Daha Sonra" dediğinde kaydet
  static Future<void> recordRatingDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ratingDismissedKey, true);
      await recordRatingRequest();
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Kullanıcı puan verdiğinde kaydet
  static Future<void> recordRatingSubmitted(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_rating', rating);
      await prefs.setInt('rating_date', DateTime.now().millisecondsSinceEpoch);
      
      // Eğer 4+ puan verdiyse Play Store'a yönlendir
      if (rating >= _minRatingThreshold) {
        await prefs.setBool(_hasRatedKey, true);
        await _openPlayStoreReview();
      } else {
        // Düşük puan verirse feedback sayfasına yönlendir
        await prefs.setBool(_hasRatedKey, false);
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Play Store'a yönlendir
  static Future<void> _openPlayStoreReview() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      
      // In-app review destekleniyorsa kullan
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Desteklenmiyorsa Play Store'a yönlendir
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Manuel olarak Play Store'a yönlendir
  static Future<void> openPlayStoreManually() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing();
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Kullanıcının verdiği puanı al
  static Future<int?> getUserRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_rating');
    } catch (e) {
      return null;
    }
  }

  // Rating istatistiklerini al
  static Future<Map<String, dynamic>> getRatingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final firstLaunch = prefs.getInt('first_launch') ?? 0;
      final lastRequest = prefs.getInt(_lastRatingRequestKey) ?? 0;
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      final userRating = prefs.getInt('user_rating');
      final ratingDate = prefs.getInt('rating_date');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceFirstLaunch = firstLaunch > 0 
          ? (now - firstLaunch) / (1000 * 60 * 60 * 24)
          : 0;
      
      final daysSinceLastRequest = lastRequest > 0
          ? (now - lastRequest) / (1000 * 60 * 60 * 24)
          : 0;
      
      return {
        'firstLaunch': firstLaunch,
        'lastRequest': lastRequest,
        'hasRated': hasRated,
        'userRating': userRating,
        'ratingDate': ratingDate,
        'daysSinceFirstLaunch': daysSinceFirstLaunch,
        'daysSinceLastRequest': daysSinceLastRequest,
        'canShowRating': await shouldShowRatingDialog(),
      };
    } catch (e) {
      return {};
    }
  }

  // Rating verilerini sıfırla (test için)
  static Future<void> resetRatingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastRatingRequestKey);
      await prefs.remove(_ratingDismissedKey);
      await prefs.remove(_hasRatedKey);
      await prefs.remove('user_rating');
      await prefs.remove('rating_date');
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Belirli koşullarda rating dialog'u göster
  static Future<void> showRatingDialogIfNeeded(BuildContext context) async {
    try {
      final shouldShow = await shouldShowRatingDialog();
      if (shouldShow && context.mounted) {
        await recordRatingRequest();
        _showRatingDialog(context);
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  // Rating dialog'u göster
  static void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AppRatingDialog(),
    );
  }

  // Manuel rating dialog'u göster
  static void showManualRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AppRatingDialog(),
    );
  }
}

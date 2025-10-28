import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'firebase_bypass_auth_service.dart';

/// Advanced recommendation service
/// Multiple sources: Spotify, Last.fm, Collaborative Filtering, Content-Based
class RecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _spotifyApiUrl = 'https://api.spotify.com/v1';
  static const String _lastfmApiUrl = 'https://ws.audioscrobbler.com/2.0/';
  static const String _lastfmApiKey = 'YOUR_LASTFM_API_KEY'; // TODO: Add real key
  
  static String? _spotifyToken;

  static void setSpotifyToken(String token) {
    _spotifyToken = token;
  }

  /// Get personalized recommendations
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int limit = 20,
  }) async {
    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId == null) return [];

    // Combine multiple recommendation sources
    final recommendations = <Map<String, dynamic>>[];

    // 1. Spotify-based recommendations
    final spotifyRecs = await _getSpotifyRecommendations(limit: limit ~/ 3);
    recommendations.addAll(spotifyRecs);

    // 2. Collaborative filtering (users with similar taste)
    final collaborativeRecs = await _getCollaborativeRecommendations(
      userId: userId,
      limit: limit ~/ 3,
    );
    recommendations.addAll(collaborativeRecs);

    // 3. Content-based (similar to liked tracks)
    final contentRecs = await _getContentBasedRecommendations(
      userId: userId,
      limit: limit ~/ 3,
    );
    recommendations.addAll(contentRecs);

    // Remove duplicates and shuffle
    final unique = _removeDuplicates(recommendations);
    unique.shuffle();

    return unique.take(limit).toList();
  }

  /// Get Spotify recommendations
  static Future<List<Map<String, dynamic>>> _getSpotifyRecommendations({
    required int limit,
  }) async {
    if (_spotifyToken == null) {
      return _getMockRecommendations(limit);
    }

    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return [];

      // Get user's top tracks as seeds
      final topTracks = await _getUserTopTracks(userId, limit: 5);
      if (topTracks.isEmpty) return _getMockRecommendations(limit);

      final seedTracks = topTracks.take(5).map((t) => t['id']).join(',');

      final url = Uri.parse(
        '$_spotifyApiUrl/recommendations?seed_tracks=$seedTracks&limit=$limit',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_spotifyToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks'] as List;
        
        return tracks.map((track) => {
          'id': track['id'],
          'name': track['name'],
          'artist': track['artists'][0]['name'],
          'album': track['album']['name'],
          'imageUrl': track['album']['images'][0]['url'],
          'source': 'Spotify',
          'reason': 'Based on your listening history',
        }).toList();
      }
    } catch (e) {
      print('Error getting Spotify recommendations: $e');
    }

    return _getMockRecommendations(limit);
  }

  /// Get collaborative filtering recommendations
  static Future<List<Map<String, dynamic>>> _getCollaborativeRecommendations({
    required String userId,
    required int limit,
  }) async {
    try {
      // Find users with similar taste
      final similarUsers = await _findSimilarUsers(userId, limit: 10);
      if (similarUsers.isEmpty) return [];

      // Get tracks liked by similar users but not by current user
      final recommendations = <Map<String, dynamic>>[];
      
      for (final similarUserId in similarUsers) {
        final theirLikes = await _getUserLikedTracks(similarUserId);
        final myLikes = await _getUserLikedTracks(userId);
        
        final myLikeIds = myLikes.map((t) => t['id']).toSet();
        
        for (final track in theirLikes) {
          if (!myLikeIds.contains(track['id'])) {
            recommendations.add({
              ...track,
              'source': 'Collaborative',
              'reason': 'Users with similar taste also liked this',
            });
          }
        }
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error in collaborative filtering: $e');
      return [];
    }
  }

  /// Get content-based recommendations
  static Future<List<Map<String, dynamic>>> _getContentBasedRecommendations({
    required String userId,
    required int limit,
  }) async {
    try {
      // Get user's liked tracks
      final likedTracks = await _getUserLikedTracks(userId);
      if (likedTracks.isEmpty) return [];

      // Get similar tracks based on audio features
      final recommendations = <Map<String, dynamic>>[];

      for (final track in likedTracks.take(5)) {
        final similar = await _getSimilarTracksByFeatures(
          track['id'],
          limit: limit ~/ 5,
        );
        
        for (final simTrack in similar) {
          recommendations.add({
            ...simTrack,
            'source': 'Content-Based',
            'reason': 'Similar to ${track['name']}',
          });
        }
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error in content-based recommendations: $e');
      return [];
    }
  }

  /// Find users with similar taste
  static Future<List<String>> _findSimilarUsers(
    String userId, {
    required int limit,
  }) async {
    try {
      // Get current user's liked tracks
      final myLikes = await _getUserLikedTracks(userId);
      final myLikeIds = myLikes.map((t) => t['id']).toSet();

      // Find users who liked similar tracks
      final userScores = <String, int>{};

      for (final trackId in myLikeIds.take(20)) {
        final snapshot = await _firestore
            .collection('track_likes')
            .where('trackId', isEqualTo: trackId)
            .limit(50)
            .get();

        for (final doc in snapshot.docs) {
          final otherUserId = doc.data()['userId'];
          if (otherUserId != userId) {
            userScores[otherUserId] = (userScores[otherUserId] ?? 0) + 1;
          }
        }
      }

      // Sort by similarity score
      final sortedUsers = userScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUsers.take(limit).map((e) => e.key).toList();
    } catch (e) {
      print('Error finding similar users: $e');
      return [];
    }
  }

  /// Get user's top tracks
  static Future<List<Map<String, dynamic>>> _getUserTopTracks(
    String userId, {
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2)
          .get();

      // Count track occurrences
      final trackCounts = <String, int>{};
      final trackData = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final trackId = data['trackId'];
        
        trackCounts[trackId] = (trackCounts[trackId] ?? 0) + 1;
        trackData[trackId] = data;
      }

      // Sort by play count
      final sorted = trackCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((e) => trackData[e.key]!)
          .toList();
    } catch (e) {
      print('Error getting user top tracks: $e');
      return [];
    }
  }

  /// Get user's liked tracks
  static Future<List<Map<String, dynamic>>> _getUserLikedTracks(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('track_likes')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting liked tracks: $e');
      return [];
    }
  }

  /// Get similar tracks by audio features
  static Future<List<Map<String, dynamic>>> _getSimilarTracksByFeatures(
    String trackId, {
    required int limit,
  }) async {
    // TODO: Implement actual audio features similarity
    // For now, use Last.fm similar tracks
    return _getLastfmSimilarTracks(trackId, limit: limit);
  }

  /// Get Last.fm similar tracks
  static Future<List<Map<String, dynamic>>> _getLastfmSimilarTracks(
    String trackId, {
    required int limit,
  }) async {
    try {
      // Note: Would need track name and artist for Last.fm API
      // For now, return empty list
      return [];
    } catch (e) {
      print('Error getting Last.fm similar tracks: $e');
      return [];
    }
  }

  /// Remove duplicate recommendations
  static List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> recommendations,
  ) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (final rec in recommendations) {
      final id = rec['id'];
      if (!seen.contains(id)) {
        seen.add(id);
        unique.add(rec);
      }
    }

    return unique;
  }

  /// Record recommendation feedback (like/dislike)
  static Future<void> recordFeedback({
    required String trackId,
    required bool isLike,
  }) async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return;

      await _firestore
          .collection('recommendation_feedback')
          .add({
        'userId': userId,
        'trackId': trackId,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user preference model
      await _updateUserPreferences(userId, trackId, isLike);
    } catch (e) {
      print('Error recording feedback: $e');
    }
  }

  /// Update user preferences based on feedback
  static Future<void> _updateUserPreferences(
    String userId,
    String trackId,
    bool isLike,
  ) async {
    try {
      final prefRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('model');

      await prefRef.set({
        'lastUpdated': FieldValue.serverTimestamp(),
        if (isLike)
          'likedTracks': FieldValue.arrayUnion([trackId])
        else
          'dislikedTracks': FieldValue.arrayUnion([trackId]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  /// Generate mock recommendations
  static List<Map<String, dynamic>> _getMockRecommendations(int limit) {
    final mockTracks = [
      {
        'id': 'mock_1',
        'name': 'Midnight Dreams',
        'artist': 'Luna Wave',
        'album': 'Nocturnal Sessions',
        'imageUrl': 'https://via.placeholder.com/300',
        'source': 'MusicBoxd',
        'reason': 'Recommended for you',
      },
      {
        'id': 'mock_2',
        'name': 'Electric Sunset',
        'artist': 'Neon Pulse',
        'album': 'Digital Horizons',
        'imageUrl': 'https://via.placeholder.com/300',
        'source': 'MusicBoxd',
        'reason': 'Based on your listening',
      },
      {
        'id': 'mock_3',
        'name': 'Ocean Breeze',
        'artist': 'Coastal Vibes',
        'album': 'Summer Waves',
        'imageUrl': 'https://via.placeholder.com/300',
        'source': 'MusicBoxd',
        'reason': 'Similar to your favorites',
      },
      {
        'id': 'mock_4',
        'name': 'City Lights',
        'artist': 'Urban Echo',
        'album': 'Metropolitan',
        'imageUrl': 'https://via.placeholder.com/300',
        'source': 'MusicBoxd',
        'reason': 'Popular in your area',
      },
      {
        'id': 'mock_5',
        'name': 'Starlight Symphony',
        'artist': 'Cosmic Orchestra',
        'album': 'Universe',
        'imageUrl': 'https://via.placeholder.com/300',
        'source': 'MusicBoxd',
        'reason': 'Trending now',
      },
    ];

    return List.generate(
      limit,
      (i) => mockTracks[i % mockTracks.length],
    );
  }

  /// Get recommendation explanation
  static String getRecommendationExplanation(Map<String, dynamic> track) {
    return track['reason'] ?? 'Recommended for you';
  }

  /// Get recommendations by genre
  static Future<List<Map<String, dynamic>>> getRecommendationsByGenre(
    String genre, {
    int limit = 20,
  }) async {
    // TODO: Implement genre-based recommendations
    return _getMockRecommendations(limit);
  }

  /// Get recommendations by mood
  static Future<List<Map<String, dynamic>>> getRecommendationsByMood(
    String mood, {
    int limit = 20,
  }) async {
    // TODO: Implement mood-based recommendations
    return _getMockRecommendations(limit);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for fetching and caching song lyrics
/// Supports multiple providers: Genius, Musixmatch (mock), and fallback
class LyricsService {
  static const String _cacheKeyPrefix = 'lyrics_cache_';
  static const Duration _cacheDuration = Duration(days: 30);

  // Mock API endpoints (replace with real ones)
  static const String _geniusApiUrl = 'https://api.genius.com';
  static const String _geniusAccessToken = 'YOUR_GENIUS_API_KEY'; // TODO: Add real key

  /// Fetch lyrics for a track
  static Future<LyricsData?> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
  }) async {
    // Check cache first
    final cacheKey = _getCacheKey(trackName, artistName);
    final cachedLyrics = await _getFromCache(cacheKey);
    if (cachedLyrics != null) {
      return cachedLyrics;
    }

    // Try fetching from Genius
    try {
      final geniusLyrics = await _fetchFromGenius(trackName, artistName);
      if (geniusLyrics != null) {
        await _saveToCache(cacheKey, geniusLyrics);
        return geniusLyrics;
      }
    } catch (e) {
      print('Error fetching from Genius: $e');
    }

    // Fallback to mock lyrics
    final mockLyrics = _getMockLyrics(trackName, artistName);
    await _saveToCache(cacheKey, mockLyrics);
    return mockLyrics;
  }

  /// Fetch lyrics from Genius API
  static Future<LyricsData?> _fetchFromGenius(
    String trackName,
    String artistName,
  ) async {
    try {
      // Search for the song
      final searchUrl = Uri.parse(
        '$_geniusApiUrl/search?q=${Uri.encodeComponent('$trackName $artistName')}',
      );

      final searchResponse = await http.get(
        searchUrl,
        headers: {'Authorization': 'Bearer $_geniusAccessToken'},
      );

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final hits = searchData['response']['hits'] as List;

        if (hits.isNotEmpty) {
          final songPath = hits[0]['result']['path'];
          
          // Note: Genius API doesn't provide lyrics directly
          // You would need to scrape the web page or use a third-party service
          // For now, return mock data with Genius URL
          
          return LyricsData(
            trackName: trackName,
            artistName: artistName,
            lyrics: _generateMockLyrics(trackName),
            syncedLyrics: null,
            source: 'Genius',
            url: 'https://genius.com$songPath',
          );
        }
      }
    } catch (e) {
      print('Genius API error: $e');
    }
    return null;
  }

  /// Generate mock lyrics (for demo purposes)
  static String _generateMockLyrics(String trackName) {
    return '''[Verse 1]
This is the beginning of $trackName
A beautiful melody that flows through time
Every note, every word, perfectly aligned
In this moment, everything feels fine

[Chorus]
$trackName, oh $trackName
You're the rhythm in my heart
$trackName, sweet $trackName
Been with me right from the start

[Verse 2]
As the music plays on and on
I find myself lost in your song
Every beat, every chord feels so strong
This is where I truly belong

[Chorus]
$trackName, oh $trackName
You're the rhythm in my heart
$trackName, sweet $trackName
Been with me right from the start

[Bridge]
When the world feels cold and gray
Your melody guides my way
Through the darkest night and brightest day
$trackName will forever stay

[Outro]
$trackName, $trackName
Forever in my soul
$trackName, $trackName
You make me feel whole''';
  }

  /// Get mock lyrics data
  static LyricsData _getMockLyrics(String trackName, String artistName) {
    return LyricsData(
      trackName: trackName,
      artistName: artistName,
      lyrics: _generateMockLyrics(trackName),
      syncedLyrics: _generateSyncedLyrics(trackName),
      source: 'MusicBoxd',
      url: null,
    );
  }

  /// Generate synced lyrics (LRC format timestamp)
  static List<SyncedLyric>? _generateSyncedLyrics(String trackName) {
    return [
      SyncedLyric(timestamp: Duration(seconds: 0), text: '[Verse 1]'),
      SyncedLyric(timestamp: Duration(seconds: 2), text: 'This is the beginning of $trackName'),
      SyncedLyric(timestamp: Duration(seconds: 6), text: 'A beautiful melody that flows through time'),
      SyncedLyric(timestamp: Duration(seconds: 10), text: 'Every note, every word, perfectly aligned'),
      SyncedLyric(timestamp: Duration(seconds: 14), text: 'In this moment, everything feels fine'),
      SyncedLyric(timestamp: Duration(seconds: 18), text: ''),
      SyncedLyric(timestamp: Duration(seconds: 20), text: '[Chorus]'),
      SyncedLyric(timestamp: Duration(seconds: 22), text: '$trackName, oh $trackName'),
      SyncedLyric(timestamp: Duration(seconds: 26), text: "You're the rhythm in my heart"),
      SyncedLyric(timestamp: Duration(seconds: 30), text: '$trackName, sweet $trackName'),
      SyncedLyric(timestamp: Duration(seconds: 34), text: 'Been with me right from the start'),
      SyncedLyric(timestamp: Duration(seconds: 38), text: ''),
      SyncedLyric(timestamp: Duration(seconds: 40), text: '[Verse 2]'),
      SyncedLyric(timestamp: Duration(seconds: 42), text: 'As the music plays on and on'),
      SyncedLyric(timestamp: Duration(seconds: 46), text: 'I find myself lost in your song'),
      SyncedLyric(timestamp: Duration(seconds: 50), text: 'Every beat, every chord feels so strong'),
      SyncedLyric(timestamp: Duration(seconds: 54), text: 'This is where I truly belong'),
    ];
  }

  /// Get cache key
  static String _getCacheKey(String trackName, String artistName) {
    final normalized = '${trackName.toLowerCase()}_${artistName.toLowerCase()}'
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '$_cacheKeyPrefix$normalized';
  }

  /// Get lyrics from cache
  static Future<LyricsData?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      
      if (cached != null) {
        final data = json.decode(cached);
        final timestamp = DateTime.parse(data['timestamp']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return LyricsData.fromJson(data['lyrics']);
        } else {
          // Cache expired, remove it
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache read error: $e');
    }
    return null;
  }

  /// Save lyrics to cache
  static Future<void> _saveToCache(String key, LyricsData lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'lyrics': lyrics.toJson(),
      };
      await prefs.setString(key, json.encode(cacheData));
    } catch (e) {
      print('Cache write error: $e');
    }
  }

  /// Clear lyrics cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Search in lyrics
  static List<int> searchInLyrics(String lyrics, String query) {
    if (query.isEmpty) return [];
    
    final lines = lyrics.split('\n');
    final results = <int>[];
    
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        results.add(i);
      }
    }
    
    return results;
  }
}

/// Lyrics data model
class LyricsData {
  final String trackName;
  final String artistName;
  final String lyrics;
  final List<SyncedLyric>? syncedLyrics;
  final String source;
  final String? url;

  LyricsData({
    required this.trackName,
    required this.artistName,
    required this.lyrics,
    this.syncedLyrics,
    required this.source,
    this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackName': trackName,
      'artistName': artistName,
      'lyrics': lyrics,
      'syncedLyrics': syncedLyrics?.map((l) => l.toJson()).toList(),
      'source': source,
      'url': url,
    };
  }

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    return LyricsData(
      trackName: json['trackName'],
      artistName: json['artistName'],
      lyrics: json['lyrics'],
      syncedLyrics: json['syncedLyrics'] != null
          ? (json['syncedLyrics'] as List)
              .map((l) => SyncedLyric.fromJson(l))
              .toList()
          : null,
      source: json['source'],
      url: json['url'],
    );
  }
}

/// Synced lyric line with timestamp
class SyncedLyric {
  final Duration timestamp;
  final String text;

  SyncedLyric({
    required this.timestamp,
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.inMilliseconds,
      'text': text,
    };
  }

  factory SyncedLyric.fromJson(Map<String, dynamic> json) {
    return SyncedLyric(
      timestamp: Duration(milliseconds: json['timestamp']),
      text: json['text'],
    );
  }
}

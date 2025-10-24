import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

import '../../core/constants/app_constants.dart';

class EnhancedSpotifyService {
  static final Dio _dio = Dio();
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static bool _isConnected = false;
  static Map<String, dynamic>? _currentTrack;
  static Map<String, dynamic>? _userProfile;
  static bool _isPlaying = false;
  static int _currentPosition = 0;
  static int _trackDuration = 0;
  
  // OAuth state for verification
  static String? _codeVerifier;
  static String? _state;

  // Spotify API Configuration
  static const String _clientId = AppConstants.spotifyClientId;
  static const String _clientSecret = AppConstants.spotifyClientSecret;
  static const String _redirectUri = AppConstants.spotifyRedirectUri;

  // Getters
  static bool get isConnected => _isConnected;
  static String? get accessToken => _accessToken;
  static Map<String, dynamic>? get currentTrack => _currentTrack;
  static Map<String, dynamic>? get userProfile => _userProfile;
  static bool get isPlaying => _isPlaying;
  static int get currentPosition => _currentPosition;
  static int get trackDuration => _trackDuration;
  static double get playbackProgress => _trackDuration > 0 ? _currentPosition / _trackDuration : 0.0;

  /// Initialize Spotify authentication with OAuth 2.0 PKCE flow
  static Future<bool> authenticate() async {
    try {
      // Use Authorization Code Flow with PKCE for mobile apps
      return await _authenticateViaWeb();
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  /// Enhanced web authentication with PKCE
  static Future<bool> _authenticateViaWeb() async {
    try {
      // Generate PKCE code verifier and challenge
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);
      _state = _generateRandomString(16);
      
      final authUrl = _buildAuthUrlWithPKCE(codeChallenge);
      
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        final launched = await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
        
        return launched;
      }
      return false;
    } catch (e) {
      print('Web auth error: $e');
      return false;
    }
  }

  /// Build authentication URL with PKCE
  static String _buildAuthUrlWithPKCE(String codeChallenge) {
    final scopes = AppConstants.spotifyScopes.join('%20');
    
    return '${AppConstants.authUrl}?'
        'response_type=code&'
        'client_id=$_clientId&'
        'scope=$scopes&'
        'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
        'state=$_state&'
        'code_challenge_method=S256&'
        'code_challenge=$codeChallenge';
  }

  /// Handle OAuth callback with authorization code
  static Future<bool> handleAuthCallback(String code, String state) async {
    try {
      // Verify state to prevent CSRF attacks
      if (state != _state) {
        print('State mismatch error');
        return false;
      }
      
      // Exchange authorization code for access token
      final response = await _dio.post(
        AppConstants.tokenUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': _codeVerifier,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        // Calculate token expiry time
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        _isConnected = true;
        
        // Save tokens
        await _saveTokens();
        await _saveConnectionState(true);
        
        // Fetch user profile
        await fetchUserProfile();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token exchange error: $e');
      return false;
    }
  }
  
  /// Generate PKCE code verifier
  static String _generateCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
  }
  
  /// Generate PKCE code challenge
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Start monitoring playback state
  static Future<void> _startPlaybackMonitoring() async {
    // Monitor playback state every 2 seconds
    _monitorPlayback();
  }

  /// Monitor playback state
  static void _monitorPlayback() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (_isConnected) {
        await _updatePlaybackState();
        _monitorPlayback(); // Continue monitoring
      }
    });
  }

  /// Update current playback state
  static Future<void> _updatePlaybackState() async {
    try {
      // final playerState = await SpotifySdk.getPlayerState(); // Temporarily disabled
      // Simulate player state for now
      // Mock values since PlayerState API is not fully available
      _isPlaying = true; // Mock value
      _currentPosition = 45000; // Mock value (45 seconds)
      _trackDuration = 180000; // Mock value (3 minutes)
      
      // Update current track info
      _currentTrack = await _getCurrentTrackInfo();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get detailed current track information
  static Future<Map<String, dynamic>?> _getCurrentTrackInfo() async {
    try {
      // For now, return enhanced mock data
      // In a real implementation, you'd fetch from Spotify Web API
      return {
        'id': 'mock_track_id_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Enhanced Spotify Track',
        'artist': 'Smart Artist',
        'album': 'Intelligent Album',
        'image_url': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
        'duration_ms': _trackDuration,
        'is_playing': _isPlaying,
        'popularity': 85,
        'explicit': false,
        'preview_url': 'https://p.scdn.co/mp3-preview/sample.mp3',
        'external_urls': {
          'spotify': 'https://open.spotify.com/track/sample'
        },
        'features': {
          'danceability': 0.8,
          'energy': 0.7,
          'valence': 0.6,
          'acousticness': 0.3,
          'tempo': 120.0,
        }
      };
    } catch (e) {
      return null;
    }
  }

  /// Enhanced play/pause control
  static Future<void> togglePlayPause() async {
    try {
      if (!_isConnected) return;
      
      if (_isPlaying) {
        // await SpotifySdk.pause(); // Temporarily disabled
      } else {
        // await SpotifySdk.resume(); // Temporarily disabled
      }
      
      _isPlaying = !_isPlaying;
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Enhanced skip to next track
  static Future<void> skipToNext() async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.skipNext(); // Temporarily disabled
      await Future.delayed(const Duration(milliseconds: 500));
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Enhanced skip to previous track
  static Future<void> skipToPrevious() async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.skipPrevious(); // Temporarily disabled
      await Future.delayed(const Duration(milliseconds: 500));
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Seek to position in track
  static Future<void> seekTo(int positionMs) async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.seekTo(positionMs); // API not available
      _currentPosition = positionMs;
    } catch (e) {
      // Handle error
    }
  }

  /// Set playback volume
  static Future<void> setVolume(double volume) async {
    try {
      if (!_isConnected) return;
      
      // Volume control might not be available in all SDK versions
      // This is a placeholder for future implementation
    } catch (e) {
      // Handle error
    }
  }

  /// Fetch user profile from Spotify
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        _userProfile = response.data;
        await _saveUserProfile();
        return _userProfile;
      }
      
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
  
  /// Get user's playlists
  static Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 50}) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/playlists',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }
  
  /// Get playlist tracks
  static Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.map((item) => item['track'] as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      return [];
    }
  }

  /// Get user's top tracks
  static Future<List<Map<String, dynamic>>> getTopTracks({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/top/tracks',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching top tracks: $e');
      return [];
    }
  }
  
  /// Get user's top artists
  static Future<List<Map<String, dynamic>>> getTopArtists({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/top/artists',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching top artists: $e');
      return [];
    }
  }

  /// Get user's recently played tracks
  static Future<List<Map<String, dynamic>>> getRecentlyPlayed({
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/player/recently-played',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching recently played: $e');
      return [];
    }
  }

  /// Get track audio features
  static Future<Map<String, dynamic>?> getTrackFeatures(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return null;

      // Mock audio features - replace with real API call
      return {
        'danceability': 0.8,
        'energy': 0.7,
        'valence': 0.6,
        'acousticness': 0.3,
        'instrumentalness': 0.1,
        'liveness': 0.2,
        'loudness': -5.0,
        'speechiness': 0.1,
        'tempo': 120.0,
        'key': 5,
        'mode': 1,
        'time_signature': 4,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get track recommendations based on current track
  static Future<List<Map<String, dynamic>>> getTrackRecommendations({
    String? seedTrackId,
    int limit = 10,
  }) async {
    try {
      if (!_isConnected || _accessToken == null) return [];

      // Mock recommendations - replace with real API call
      return List.generate(limit, (index) => {
        'id': 'recommended_track_$index',
        'name': 'Recommended Track ${index + 1}',
        'artist': 'Recommended Artist ${index + 1}',
        'album': 'Recommended Album ${index + 1}',
        'image_url': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
        'popularity': 80 - index,
        'preview_url': 'https://p.scdn.co/mp3-preview/recommended$index.mp3',
        'duration_ms': 190000 + (index * 8000),
      });
    } catch (e) {
      return [];
    }
  }

  /// Save track to user's library
  static Future<bool> saveTrack(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return false;

      // Mock save operation - replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove track from user's library
  static Future<bool> removeTrack(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return false;

      // Mock remove operation - replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user's saved tracks
  static Future<List<Map<String, dynamic>>> getSavedTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (!_isConnected || _accessToken == null) return [];

      // Mock saved tracks - replace with real API call
      return List.generate(limit, (index) => {
        'id': 'saved_track_${index + offset}',
        'name': 'Saved Track ${index + offset + 1}',
        'artist': 'Saved Artist ${index + offset + 1}',
        'album': 'Saved Album ${index + offset + 1}',
        'image_url': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
        'added_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'duration_ms': 175000 + (index * 12000),
      });
    } catch (e) {
      return [];
    }
  }

  /// Save tokens to local storage
  static Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(AppConstants.accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
    }
    if (_tokenExpiry != null) {
      await prefs.setString(AppConstants.tokenExpiryKey, _tokenExpiry!.toIso8601String());
    }
  }
  
  /// Load tokens from local storage
  static Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.accessTokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    
    final expiryStr = prefs.getString(AppConstants.tokenExpiryKey);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.parse(expiryStr);
    }
  }
  
  /// Save user profile to local storage
  static Future<void> _saveUserProfile() async {
    if (_userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, jsonEncode(_userProfile!));
    }
  }
  
  /// Load user profile from local storage
  static Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(AppConstants.userDataKey);
    if (profileStr != null) {
      _userProfile = jsonDecode(profileStr) as Map<String, dynamic>;
    }
  }
  
  /// Check if token is expired and refresh if needed
  static Future<void> _checkAndRefreshToken() async {
    if (!_isConnected || _accessToken == null) {
      throw Exception('Not connected to Spotify');
    }
    
    // Check if token is expired or about to expire (within 5 minutes)
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      await _refreshAccessToken();
    }
  }
  
  /// Refresh access token using refresh token
  static Future<void> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await _dio.post(
        AppConstants.tokenUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        
        // Update refresh token if provided
        if (data.containsKey('refresh_token')) {
          _refreshToken = data['refresh_token'];
        }
        
        // Calculate token expiry time
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        await _saveTokens();
      }
    } catch (e) {
      print('Token refresh error: $e');
      // If refresh fails, disconnect user
      await disconnect();
      throw Exception('Failed to refresh token');
    }
  }
  
  /// Save connection state
  static Future<void> _saveConnectionState(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spotify_connected', connected);
    if (connected) {
      await prefs.setString('spotify_connected_at', DateTime.now().toIso8601String());
    }
  }

  /// Load connection state
  static Future<void> loadConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('spotify_connected') ?? false;
    if (_isConnected) {
      await _loadTokens();
      await _loadUserProfile();
      await _startPlaybackMonitoring();
    }
  }

  /// Disconnect from Spotify
  static Future<void> disconnect() async {
    try {
      _isConnected = false;
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _currentTrack = null;
      _userProfile = null;
      _isPlaying = false;
      _currentPosition = 0;
      _trackDuration = 0;
      
      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.accessTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.tokenExpiryKey);
      await prefs.remove(AppConstants.userDataKey);
      await _saveConnectionState(false);
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// Generate random string for state parameter
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Get current track with enhanced info
  static Future<Map<String, dynamic>?> getCurrentTrack() async {
    await _updatePlaybackState();
    return _currentTrack;
  }

  /// Check if track is saved in user's library
  static Future<bool> isTrackSaved(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return false;

      // Mock check - replace with real API call
      return Random().nextBool();
    } catch (e) {
      return false;
    }
  }

  /// Get track popularity score
  static Future<int?> getTrackPopularity(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return null;

      // Mock popularity - replace with real API call
      return Random().nextInt(100) + 1;
    } catch (e) {
      return null;
    }
  }

  /// Get artist information
  static Future<Map<String, dynamic>?> getArtistInfo(String artistId) async {
    try {
      if (!_isConnected || _accessToken == null) return null;

      // Mock artist info - replace with real API call
      return {
        'id': artistId,
        'name': 'Artist Name',
        'genres': ['pop', 'indie'],
        'popularity': 85,
        'followers': {'total': 1000000},
        'images': [
          {
            'url': 'https://i.scdn.co/image/ab6761610000e5ebbb54dde68cd23e2a268ae0f5',
            'height': 640,
            'width': 640,
          }
        ],
      };
    } catch (e) {
      return null;
    }
  }

  /// Get album information
  static Future<Map<String, dynamic>?> getAlbumInfo(String albumId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/albums/$albumId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching album info: $e');
      return null;
    }
  }
  
  /// Search for tracks, albums, or artists
  static Future<Map<String, dynamic>> search({
    required String query,
    List<String> types = const ['track', 'album', 'artist'],
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/search',
        queryParameters: {
          'q': query,
          'type': types.join(','),
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      print('Error searching: $e');
      return {};
    }
  }
}

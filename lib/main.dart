import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import 'core/theme/app_theme.dart'; // Replaced with enhanced_theme.dart
import 'core/theme/enhanced_theme.dart';
import 'core/constants/app_constants.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/services/firebase_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/smart_notification_service.dart';
import 'shared/services/enhanced_spotify_service.dart';
import 'shared/services/enhanced_auth_service.dart';
import 'shared/services/simple_auth_service.dart';
import 'shared/services/firebase_bypass_auth_service.dart';
import 'shared/services/popular_tracks_seed_service.dart';
import 'shared/services/music_player_service.dart';
import 'features/auth/presentation/pages/enhanced_login_page.dart';
import 'features/auth/presentation/pages/enhanced_signup_page.dart';
import 'features/auth/presentation/pages/spotify_connect_page.dart';
import 'features/auth/presentation/pages/spotify_callback_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/modern_home_page.dart';
import 'features/home/presentation/pages/music_share_home_page.dart';
import 'features/discover/presentation/pages/discover_page.dart';
import 'features/discover/presentation/pages/discover_search_page.dart';
import 'features/discover/presentation/pages/discover_section_page.dart';
import 'features/discover/presentation/pages/genre_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/enhanced_profile_page.dart';
import 'features/profile/presentation/pages/letterboxd_profile_page.dart';
import 'features/search/presentation/pages/advanced_search_page.dart';
import 'features/search/presentation/pages/modern_search_page.dart';
import 'features/search/presentation/pages/search_results_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/statistics/presentation/pages/listening_stats_page.dart';
import 'features/music/presentation/pages/my_ratings_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'shared/widgets/feedback/feedback_widgets.dart';
import 'features/legal/presentation/pages/terms_of_service_page.dart';
import 'features/legal/presentation/pages/privacy_policy_page.dart';
import 'shared/services/app_rating_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/home/presentation/pages/modern_home_page.dart';
import 'features/social/presentation/pages/social_feed_page.dart';
import 'features/social/presentation/pages/user_profile_page.dart';
import 'features/diary/presentation/pages/music_diary_page.dart';
import 'features/lists/presentation/pages/music_lists_page.dart';
import 'features/reviews/presentation/pages/reviews_page.dart';
import 'features/music/presentation/pages/spotify_tracks_page.dart';
import 'features/music/presentation/pages/spotify_albums_page.dart';
// import 'features/music/presentation/pages/create_playlist_page.dart'; // Removed - using playlists version
import 'features/music/presentation/pages/turkey_top_tracks_page.dart';
import 'features/music/presentation/pages/turkey_top_albums_page.dart';
import 'features/music/presentation/pages/track_detail_page.dart';
import 'features/music/presentation/pages/artist_profile_page.dart';
import 'features/music/presentation/pages/album_detail_page.dart';
import 'features/favorites/presentation/pages/favorites_page.dart';
import 'features/recently_played/recently_played_page.dart';
import 'features/playlists/user_playlists_page.dart';
import 'features/playlists/create_playlist_page.dart';
import 'features/playlists/import_spotify_playlists_page.dart';
import 'features/playlists/playlist_detail_page.dart';
import 'features/playlists/playlist_loader_page.dart';
import 'features/playlists/discover_playlists_page.dart';
import 'features/playlists/qr_scanner_page.dart';
import 'features/playlists/smart_playlists_page.dart';
import 'features/messaging/conversations_page.dart';
import 'features/create/presentation/pages/create_content_page.dart';
import 'shared/models/music_list.dart';
import 'shared/widgets/mini_player/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  
  // Initialize Firebase Bypass Auth Service (completely bypasses Firebase)
  await FirebaseBypassAuthService.initialize();
  
  // Initialize Notifications
  await NotificationService.initialize();
  
  // Initialize Smart Notifications (only basic initialization)
  await SmartNotificationService.initialize();
  
  // Initialize Enhanced Spotify Service
  await EnhancedSpotifyService.loadConnectionState();
  
  // Initialize Music Player Service
  await MusicPlayerService.initialize();
  
  // Initialize popular tracks seed (background, don't wait)
  PopularTracksSeedService.initializeSeed();
  
  // Initialize App Rating
  await AppRatingService.recordFirstLaunch();
  
  runApp(const ProviderScope(child: MusicShareApp()));
}

class MusicShareApp extends StatelessWidget {
  const MusicShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: EnhancedTheme.lightTheme,
          darkTheme: EnhancedTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Simple redirect logic
    final isSignedIn = FirebaseBypassAuthService.isSignedIn;
    final currentPath = state.uri.path;
    
    // If user is signed in and on splash, go to home
    if (isSignedIn && currentPath == '/splash') {
      return '/';
    }
    
    // If user is not signed in and on home, go to login
    if (!isSignedIn && currentPath == '/') {
      return '/login';
    }
    
    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const EnhancedLoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const EnhancedSignupPage(),
    ),
    GoRoute(
      path: '/spotify-callback',
      name: 'spotify-callback',
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];
        final stateParam = state.uri.queryParameters['state'];
        final error = state.uri.queryParameters['error'];
        return SpotifyCallbackPage(
          code: code,
          state: stateParam,
          error: error,
        );
      },
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: '/profile-tab',
      name: 'profile-tab',
      builder: (context, state) => const MainNavigationPage(initialTab: 4),
    ),
        GoRoute(
          path: '/spotify-connect',
          name: 'spotify-connect',
          builder: (context, state) => const SpotifyConnectPage(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const ModernSearchPage(),
        ),
        GoRoute(
          path: '/search-results',
          name: 'search-results',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return SearchResultsPage(
              query: extra['query'] as String,
              type: extra['type'] as String,
              results: extra['results'] as List<Map<String, dynamic>>,
            );
          },
        ),
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        GoRoute(
          path: '/discover-search',
          name: 'discover-search',
          builder: (context, state) => const DiscoverSearchPage(),
        ),
        GoRoute(
          path: '/discover-section/:type/:title',
          name: 'discover-section',
          builder: (context, state) {
            final type = state.pathParameters['type']!;
            final title = state.pathParameters['title']!;
            return DiscoverSectionPage(title: title, sectionType: type);
          },
        ),
        GoRoute(
          path: '/genre/:genre',
          name: 'genre',
          builder: (context, state) {
            final genre = state.pathParameters['genre']!;
            return GenrePage(genre: genre);
          },
        ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: '/listening-stats',
        name: 'listening-stats',
        builder: (context, state) => const ListeningStatsPage(),
      ),
      GoRoute(
        path: '/my-ratings',
        name: 'my-ratings',
        builder: (context, state) => const MyRatingsPage(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const SocialFeedPage(),
      ),
      GoRoute(
        path: '/diary',
        name: 'diary',
        builder: (context, state) => const MusicDiaryPage(),
      ),
      GoRoute(
        path: '/lists',
        name: 'lists',
        builder: (context, state) => const MusicListsPage(),
      ),
      GoRoute(
        path: '/reviews',
        name: 'reviews',
        builder: (context, state) => const ReviewsPage(),
      ),
      GoRoute(
        path: '/spotify-tracks',
        name: 'spotify-tracks',
        builder: (context, state) => const SpotifyTracksPage(),
      ),
      GoRoute(
        path: '/spotify-albums',
        name: 'spotify-albums',
        builder: (context, state) => const SpotifyAlbumsPage(),
      ),
      GoRoute(
        path: '/track-detail',
        name: 'track-detail',
        builder: (context, state) {
          final track = state.extra as Map<String, dynamic>;
          return TrackDetailPage(track: track);
        },
      ),
      GoRoute(
        path: '/turkey-top-tracks',
        name: 'turkey-top-tracks',
        builder: (context, state) => const TurkeyTopTracksPage(),
      ),
      GoRoute(
        path: '/turkey-top-albums',
        name: 'turkey-top-albums',
        builder: (context, state) => const TurkeyTopAlbumsPage(),
      ),
      GoRoute(
        path: '/artist-profile',
        name: 'artist-profile',
        builder: (context, state) {
          final artist = state.extra as Map<String, dynamic>;
          return ArtistProfilePage(artist: artist);
        },
      ),
      GoRoute(
        path: '/album-detail',
        name: 'album-detail',
        builder: (context, state) {
          final album = state.extra as Map<String, dynamic>;
          return AlbumDetailPage(album: album);
        },
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/recently-played',
        name: 'recently-played',
        builder: (context, state) => const RecentlyPlayedPage(),
      ),
      GoRoute(
        path: '/playlists',
        name: 'playlists',
        builder: (context, state) => const UserPlaylistsPage(showBackButton: true),
      ),
      GoRoute(
        path: '/create-playlist',
        name: 'create-playlist',
        builder: (context, state) => const CreatePlaylistPage(),
      ),
      GoRoute(
        path: '/import-spotify-playlists',
        name: 'import-spotify-playlists',
        builder: (context, state) => const ImportSpotifyPlaylistsPage(),
      ),
      GoRoute(
        path: '/playlist-detail',
        name: 'playlist-detail',
        builder: (context, state) {
          final playlist = state.extra as MusicList;
          return PlaylistDetailPage(playlist: playlist);
        },
      ),
      GoRoute(
        path: '/playlist/:playlistId',
        name: 'playlist-by-id',
        builder: (context, state) {
          final playlistId = state.pathParameters['playlistId']!;
          return PlaylistLoaderPage(playlistId: playlistId);
        },
      ),
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: '/smart-playlists',
        name: 'smart-playlists',
        builder: (context, state) => const SmartPlaylistsPage(),
      ),
      GoRoute(
        path: '/user-profile/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final username = state.uri.queryParameters['username'] ?? 'User';
          return UserProfilePage(
            userId: userId,
            username: username,
          );
        },
      ),
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ConversationsPage(),
      ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/feedback',
      name: 'feedback',
      builder: (context, state) => const FeedbackPage(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsOfServicePage(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
  ],
);

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = FirebaseBypassAuthService.isSignedIn;
    
    if (isSignedIn) {
      return const MainNavigationPage();
    } else {
      return const EnhancedLoginPage();
    }
  }
}


class MainNavigationPage extends StatefulWidget {
  final int initialTab;
  
  const MainNavigationPage({super.key, this.initialTab = 0});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final List<Widget> _pages = [
    const MusicShareHomePage(),
    const DiscoverPage(),
    const CreateContentPage(),
    const ConversationsPage(),
    const LetterboxdProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: const MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        selectedItemColor: const Color(0xFFFF5E5E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
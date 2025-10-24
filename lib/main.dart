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
import 'features/auth/presentation/pages/enhanced_login_page.dart';
import 'features/auth/presentation/pages/enhanced_signup_page.dart';
import 'features/auth/presentation/pages/spotify_connect_page.dart';
import 'features/auth/presentation/pages/spotify_callback_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/modern_home_page.dart';
import 'features/home/presentation/pages/music_share_home_page.dart';
import 'features/discover/presentation/pages/discover_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/enhanced_profile_page.dart';
import 'features/search/presentation/pages/advanced_search_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/music/presentation/pages/my_ratings_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'shared/widgets/feedback/feedback_widgets.dart';
import 'features/legal/presentation/pages/terms_of_service_page.dart';
import 'features/legal/presentation/pages/privacy_policy_page.dart';
import 'shared/services/app_rating_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/home/presentation/pages/modern_home_page.dart';
import 'features/social/presentation/pages/social_feed_page.dart';
import 'features/diary/presentation/pages/music_diary_page.dart';
import 'features/lists/presentation/pages/music_lists_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';

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
          path: '/spotify-connect',
          name: 'spotify-connect',
          builder: (context, state) => const SpotifyConnectPage(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const AdvancedSearchPage(),
        ),
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (context, state) => const DiscoverPage(),
        ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
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
        path: '/notes',
        name: 'notes',
        builder: (context, state) => const NotesPage(),
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
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MusicShareHomePage(),
    const DiscoverPage(),
    const EnhancedProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/widgets/enhanced_spotify_player_widget.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';
import '../../../../shared/widgets/timeline_feed_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _popularReleases = [];
  List<Map<String, dynamic>> _timelinePosts = [];
  Map<String, int> _favoriteCounts = {};
  final _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  String _releaseViewMode = 'popular'; // 'popular' or 'new'
  String _timelineViewMode = 'popular'; // 'popular' or 'friends'

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load Spotify data - both new releases and global popular
      final newReleases = await EnhancedSpotifyService.getNewReleases(limit: 10);
      final popularReleases = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 10);

      // Load favorites count
      final currentUser = FirebaseAuth.instance.currentUser;
      Map<String, int> counts = {};
      if (currentUser != null) {
        counts = await FavoritesService.getFavoritesCount();
      }

      // Mock timeline posts (replace with real data from Firestore)
      final posts = _generateMockTimelinePosts();

      if (mounted) {
        setState(() {
          _newReleases = newReleases;
          _popularReleases = popularReleases;
          _timelinePosts = posts;
          _favoriteCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _generateMockTimelinePosts() {
    return [
      {
        'title': 'Thriller',
        'artist': 'Michael Jackson',
        'albumType': 'Album',
        'type': 'popular',
        'review': 'Why Michael Jackson will always be the GOAT!!!',
        'rating': 5.0,
        'userName': 'MusicLover92',
        'reviewBody':
            'I know this review is out a month before its next anniversary, but let me cook. Back in middle school, I was really obsessed with Michael Jackson.',
      },
      {
        'title': 'Hotel California',
        'artist': 'Eagles',
        'albumType': 'Album',
        'type': 'friends',
        'review': 'A masterpiece of rock music',
        'rating': 5.0,
        'userName': 'RockFan',
        'reviewBody': 'This album is timeless. Every track is perfect and the production is amazing.',
      },
      {
        'title': 'Dark Side of the Moon',
        'artist': 'Pink Floyd',
        'albumType': 'Album',
        'type': 'popular',
        'review': 'Progressive rock at its finest',
        'rating': 5.0,
        'userName': 'ProgressiveLover',
        'reviewBody': 'One of the greatest albums ever made. Timeless masterpiece.',
      },
      {
        'title': 'Abbey Road',
        'artist': 'The Beatles',
        'albumType': 'Album',
        'type': 'friends',
        'review': 'The Beatles perfection',
        'rating': 5.0,
        'userName': 'BeatlesFan',
        'reviewBody': 'Every song on this album is incredible. Come Together is amazing!',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-playlist'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Playlist'),
        backgroundColor: ModernDesignSystem.primaryGreen,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tuniverse',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.primaryGreen.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              bottom: AppConstants.defaultPadding + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Popular/New Toggle Section
                _buildReleasesToggleSection(context, isDark),
                const SizedBox(height: 16),
                // Popular or New Releases
                _buildReleasesView(context, isDark),
                const SizedBox(height: 24),
                // Discover/Friends Toggle Section
                _buildDiscoverToggleSection(context, isDark),
                const SizedBox(height: 16),
                // Discover Feed
                _buildDiscoverView(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReleasesToggleSection(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_releaseViewMode == 'popular')
          Text(
            'Popular This Week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
            ),
          )
        else
          Text(
            'Hot New Releases',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
            ),
          ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _releaseViewMode = 'popular'),
              child: Text(
                'POPULAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _releaseViewMode == 'popular'
                      ? ModernDesignSystem.primaryGreen
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('/', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _releaseViewMode = 'new'),
              child: Text(
                'NEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _releaseViewMode == 'new'
                      ? ModernDesignSystem.primaryGreen
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReleasesView(BuildContext context, bool isDark) {
    final data = _releaseViewMode == 'popular' ? _popularReleases : _newReleases;
    
    if (_isLoading) {
      return const HorizontalScrollSkeleton(height: 220, itemCount: 3);
    }

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No releases found',
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < data.length - 1 ? 12 : 0,
                ),
                child: HorizontalAlbumCard(album: data[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            onTap: () => context.push('/discover'),
            child: const Text(
              'View Full List',
              style: TextStyle(
                color: ModernDesignSystem.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverToggleSection(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Discover',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _timelineViewMode = 'popular'),
              child: Text(
                'POPULAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _timelineViewMode == 'popular'
                      ? ModernDesignSystem.primaryGreen
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('/', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _timelineViewMode = 'friends'),
              child: Text(
                'FRIENDS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _timelineViewMode == 'friends'
                      ? ModernDesignSystem.primaryGreen
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscoverView(BuildContext context, bool isDark) {
    // Filter posts based on mode
    final posts = _timelineViewMode == 'popular'
        ? _timelinePosts.where((p) => p['type'] == 'popular').toList()
        : _timelinePosts.where((p) => p['type'] == 'friends').toList();

    return TimelineFeedWidget(
      posts: posts.isEmpty ? _timelinePosts : posts,
      isLoading: _isLoading,
    );
  }

  Widget _buildModernWelcomeSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.modernGradient,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
        boxShadow: ModernDesignSystem.getGlowEffect(
          ModernDesignSystem.primaryGreen,
          intensity: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ready for new discoveries?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickStats(BuildContext context, bool isDark) {
    final totalFavorites = _favoriteCounts['total'] ?? 0;
    final tracks = _favoriteCounts['tracks'] ?? 0;
    final albums = _favoriteCounts['albums'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.music_note_rounded,
            title: 'Tracks',
            value: tracks.toString(),
            gradient: ModernDesignSystem.primaryGradient,
            onTap: () => context.push('/favorites'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.album_rounded,
            title: 'Albums',
            value: albums.toString(),
            gradient: ModernDesignSystem.blueGradient,
            onTap: () => context.push('/favorites'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.favorite_rounded,
            title: 'Favorites',
            value: totalFavorites.toString(),
            gradient: ModernDesignSystem.sunsetGradient,
            onTap: () => context.push('/favorites'),
          ),
        ),
      ],
    );
  }

  Widget _buildNewReleases(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ModernDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.new_releases_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Releases',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/discover'),
                style: TextButton.styleFrom(
                  foregroundColor: ModernDesignSystem.primaryGreen,
                ),
                child: const Text('All'),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const HorizontalScrollSkeleton(height: 220, itemCount: 3)
        else if (_newReleases.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'No new releases found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newReleases.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(
                    right: index < _newReleases.length - 1 ? 12 : 0,
                  ),
                  child: HorizontalAlbumCard(album: _newReleases[index]),
                );
              },
            ),
          ),
      ],
    );
  }


  Widget _buildModernStatCard(BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: isDark 
            ? ModernDesignSystem.darkGlassmorphism
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                boxShadow: ModernDesignSystem.mediumShadow,
              ),
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.6)
                  : ModernDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full timeline
                },
                style: TextButton.styleFrom(
                  foregroundColor: ModernDesignSystem.primaryGreen,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        TimelineFeedWidget(
          posts: _timelinePosts,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildModernActivityItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.6)
                      : ModernDesignSystem.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTopTracks(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ModernDesignSystem.sunsetGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'This Week\'s Top Tracks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full list
                },
                style: TextButton.styleFrom(
                  foregroundColor: ModernDesignSystem.primaryGreen,
                ),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: isDark 
              ? ModernDesignSystem.darkGlassmorphism
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                  boxShadow: ModernDesignSystem.mediumShadow,
                ),
          child: Column(
            children: [
              _buildModernTrackItem(
                isDark: isDark,
                rank: 1,
                title: 'Bohemian Rhapsody',
                artist: 'Queen',
                rating: 5.0,
              ),
              const SizedBox(height: 16),
              _buildModernTrackItem(
                isDark: isDark,
                rank: 2,
                title: 'Hotel California',
                artist: 'Eagles',
                rating: 4.5,
              ),
              const SizedBox(height: 16),
              _buildModernTrackItem(
                isDark: isDark,
                rank: 3,
                title: 'Stairway to Heaven',
                artist: 'Led Zeppelin',
                rating: 4.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTrackItem({
    required bool isDark,
    required int rank,
    required String title,
    required String artist,
    required double rating,
  }) {
    final rankColors = [
      ModernDesignSystem.sunsetGradient,
      ModernDesignSystem.primaryGradient,
      ModernDesignSystem.blueGradient,
    ];
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: rankColors[rank - 1],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: rankColors[rank - 1].colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: ModernDesignSystem.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                style: TextStyle(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.6)
                      : ModernDesignSystem.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ModernDesignSystem.accentYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: ModernDesignSystem.accentYellow,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ModernDesignSystem.accentYellow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // Removed unused _buildSpotifyPlayer method - replaced with EnhancedSpotifyPlayerWidget

  // Removed unused _openRateMusicPage method - functionality moved to EnhancedSpotifyPlayerWidget
}

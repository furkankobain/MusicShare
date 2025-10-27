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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _featuredPlaylists = [];
  Map<String, int> _favoriteCounts = {};
  final _scrollController = ScrollController();
  double _scrollOffset = 0.0;

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
      // Load Spotify data
      final releases = await EnhancedSpotifyService.getNewReleases(limit: 6);
      final playlists = await EnhancedSpotifyService.getFeaturedPlaylists(limit: 4);

      // Load favorites count
      final currentUser = FirebaseAuth.instance.currentUser;
      Map<String, int> counts = {};
      if (currentUser != null) {
        counts = await FavoritesService.getFavoritesCount();
      }

      if (mounted) {
        setState(() {
          _newReleases = releases;
          _featuredPlaylists = playlists;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-playlist'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Çalma Listesi'),
        backgroundColor: ModernDesignSystem.primaryGreen,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => ModernDesignSystem.modernGradient.createShader(bounds),
          child: const Text(
            'MusicShare',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, size: 20),
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernDesignSystem.accentPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          const SizedBox(width: 12),
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
                // Welcome Section with parallax
                Transform.translate(
                  offset: Offset(0, -_scrollOffset * 0.2),
                  child: _buildModernWelcomeSection(context, isDark),
                ),
                
                const SizedBox(height: 24),
                
                // Spotify Player Widget (only if connected)
                if (EnhancedSpotifyService.isConnected)
                  const EnhancedSpotifyPlayerWidget(),
                
                if (EnhancedSpotifyService.isConnected)
                  const SizedBox(height: 24),
                
                // Quick Stats
                _buildModernQuickStats(context, isDark),
                
                const SizedBox(height: 24),
                
                // New Releases
                _buildNewReleases(context, isDark),
                
                const SizedBox(height: 24),
                
                // Featured Playlists
                _buildFeaturedPlaylists(context, isDark),
                
                const SizedBox(height: 24),
                
                // Recent Activity
                _buildModernRecentActivity(context, isDark),
              ],
            ),
          ),
        ),
      ),
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
                      'Hoş Geldiniz!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Yeni keşifler için hazır mısınız?',
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
            title: 'Şarkılar',
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
            title: 'Albümler',
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
            title: 'Favoriler',
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
                    'Yeni Çıkanlar',
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
                child: const Text('Tümü'),
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
              'Yeni çıkan albüm bulunamadı',
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

  Widget _buildFeaturedPlaylists(BuildContext context, bool isDark) {
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
                      gradient: ModernDesignSystem.blueGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.featured_play_list_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Öne Çıkan Playlistler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/playlists'),
                style: TextButton.styleFrom(
                  foregroundColor: ModernDesignSystem.primaryGreen,
                ),
                child: const Text('Tümü'),
              ),
            ],
          ),
        ),
        if (_isLoading)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const AlbumCardSkeleton(),
          )
        else if (_featuredPlaylists.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'Öne çıkan playlist bulunamadı',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _featuredPlaylists.length > 4 ? 4 : _featuredPlaylists.length,
            itemBuilder: (context, index) {
              return AlbumCard(album: _featuredPlaylists[index]);
            },
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

  Widget _buildModernRecentActivity(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Son Aktiviteler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                ),
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
              _buildModernActivityItem(
                isDark: isDark,
                icon: Icons.star_rounded,
                title: '"Bohemian Rhapsody" puanlandı',
                subtitle: '5 yıldız • 2 saat önce',
                gradient: ModernDesignSystem.sunsetGradient,
              ),
              const SizedBox(height: 16),
              _buildModernActivityItem(
                isDark: isDark,
                icon: Icons.playlist_add_rounded,
                title: 'Favorilere eklendi',
                subtitle: '"Hotel California" • 4 saat önce',
                gradient: ModernDesignSystem.primaryGradient,
              ),
              const SizedBox(height: 16),
              _buildModernActivityItem(
                isDark: isDark,
                icon: Icons.edit_note_rounded,
                title: 'Bir yorum yazıldı',
                subtitle: '"Dark Side of the Moon" • Dün',
                gradient: ModernDesignSystem.blueGradient,
              ),
            ],
          ),
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
                    'Bu Haftanın En İyileri',
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
                child: const Text('Tümü'),
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

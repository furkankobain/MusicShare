import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/widgets/enhanced_spotify_player_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppConstants.defaultPadding,
            right: AppConstants.defaultPadding,
            bottom: AppConstants.defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildModernWelcomeSection(context, isDark),
              
              const SizedBox(height: 24),
              
              // Spotify Player Widget
              const EnhancedSpotifyPlayerWidget(),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              _buildModernQuickStats(context, isDark),
              
              const SizedBox(height: 24),
              
              // Recent Activity
              _buildModernRecentActivity(context, isDark),
              
              const SizedBox(height: 24),
              
              // Top Tracks This Week
              _buildModernTopTracks(context, isDark),
              
              const SizedBox(height: 24),
              
              // Recently Played
              _buildRecentlyPlayed(context, ref),
            ],
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
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.music_note_rounded,
            title: 'Şarkılar',
            value: '247',
            gradient: ModernDesignSystem.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.album_rounded,
            title: 'Albümler',
            value: '43',
            gradient: ModernDesignSystem.blueGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            context,
            isDark: isDark,
            icon: Icons.favorite_rounded,
            title: 'Favoriler',
            value: '89',
            gradient: ModernDesignSystem.sunsetGradient,
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
  }) {
    return Container(
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

  Widget _buildRecentlyPlayed(BuildContext context, WidgetRef ref) {
    // final recentlyPlayed = ref.watch(recentlyPlayedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Played',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full recently played page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildConnectSpotifyPrompt(context),
      ],
    );
  }

  Widget _buildConnectSpotifyPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.music_note,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect Spotify to see your music',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sync your listening history and discover new music',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to Spotify connect page
            },
            icon: const Icon(Icons.music_note, size: 18),
            label: const Text('Connect Spotify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Removed unused _buildSpotifyPlayer method - replaced with EnhancedSpotifyPlayerWidget

  // Removed unused _openRateMusicPage method - functionality moved to EnhancedSpotifyPlayerWidget
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../music/presentation/pages/rate_music_page.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context),
            
            const SizedBox(height: 24),
            
            // Featured Tracks
            _buildFeaturedSection('Öne Çıkan Şarkılar', _buildFeaturedTracks(ref)),
            
            const SizedBox(height: 24),
            
            // New Releases
            _buildFeaturedSection('Yeni Çıkanlar', _buildNewReleases(ref)),
            
            const SizedBox(height: 24),
            
            // Trending Artists
            _buildFeaturedSection('Trend Sanatçılar', _buildTrendingArtists(ref)),
            
            const SizedBox(height: 24),
            
            // Recommendations
            _buildFeaturedSection('Sana Özel Öneriler', _buildRecommendations(ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Müzikler Keşfet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Favori sanatçılarınızın yeni şarkılarını keşfedin ve puanlayın',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.trending_up,
            title: 'Trend',
            subtitle: 'Popüler şarkılar',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.new_releases,
            title: 'Yeni',
            subtitle: 'Son çıkanlar',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.recommend,
            title: 'Öneriler',
            subtitle: 'Sana özel',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTracks(WidgetRef ref) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          final tracks = [
            {
              'name': 'Anti-Hero',
              'artist': 'Taylor Swift',
              'image': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
            },
            {
              'name': 'As It Was',
              'artist': 'Harry Styles',
              'image': 'https://i.scdn.co/image/ab67616d0000b273f7b7174bef6f3fbfda3a0bb7',
            },
            {
              'name': 'Heat Waves',
              'artist': 'Glass Animals',
              'image': 'https://i.scdn.co/image/ab67616d0000b2737c05b5e35713c6643bb9a7c0',
            },
            {
              'name': 'Stay',
              'artist': 'The Kid LAROI',
              'image': 'https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856',
            },
            {
              'name': 'Good 4 U',
              'artist': 'Olivia Rodrigo',
              'image': 'https://i.scdn.co/image/ab67616d0000b2739e5d5a6f7b3b5a6f7b3b5a6f',
            },
          ];
          
          final track = tracks[index];
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => _openRateMusicPage(context, track),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: track['image']!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track['artist']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewReleases(WidgetRef ref) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          final releases = [
            {
              'name': 'Midnights',
              'artist': 'Taylor Swift',
              'image': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
            },
            {
              'name': 'Harry\'s House',
              'artist': 'Harry Styles',
              'image': 'https://i.scdn.co/image/ab67616d0000b273f7b7174bef6f3fbfda3a0bb7',
            },
            {
              'name': 'Dreamland',
              'artist': 'Glass Animals',
              'image': 'https://i.scdn.co/image/ab67616d0000b2737c05b5e35713c6643bb9a7c0',
            },
            {
              'name': 'F*CK LOVE 3',
              'artist': 'The Kid LAROI',
              'image': 'https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856',
            },
            {
              'name': 'SOUR',
              'artist': 'Olivia Rodrigo',
              'image': 'https://i.scdn.co/image/ab67616d0000b2739e5d5a6f7b3b5a6f7b3b5a6f',
            },
          ];
          
          final release = releases[index];
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => _openRateMusicPage(context, release),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: release['image']!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            release['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            release['artist']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations(WidgetRef ref) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          final recommendations = [
            {
              'name': 'Blinding Lights',
              'artist': 'The Weeknd',
              'image': 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
            },
            {
              'name': 'Levitating',
              'artist': 'Dua Lipa',
              'image': 'https://i.scdn.co/image/ab67616d0000b273f7b7174bef6f3fbfda3a0bb7',
            },
            {
              'name': 'Watermelon Sugar',
              'artist': 'Harry Styles',
              'image': 'https://i.scdn.co/image/ab67616d0000b273f7b7174bef6f3fbfda3a0bb7',
            },
            {
              'name': 'Peaches',
              'artist': 'Justin Bieber',
              'image': 'https://i.scdn.co/image/ab67616d0000b273c8b444df094279e70d0ed856',
            },
            {
              'name': 'Industry Baby',
              'artist': 'Lil Nas X',
              'image': 'https://i.scdn.co/image/ab67616d0000b2739e5d5a6f7b3b5a6f7b3b5a6f',
            },
          ];
          
          final recommendation = recommendations[index];
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => _openRateMusicPage(context, recommendation),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: recommendation['image']!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['artist']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingArtists(WidgetRef ref) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (context, index) {
          final artists = [
            'Taylor Swift',
            'The Weeknd',
            'Bad Bunny',
            'Drake',
            'Billie Eilish',
            'Ed Sheeran',
            'Ariana Grande',
            'Post Malone',
          ];
          
          final artist = artists[index];
          
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => _openArtistPage(context, artist),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          artist.split(' ').map((word) => word[0]).join(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  void _openRateMusicPage(BuildContext context, Map<String, dynamic> track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateMusicPage(track: track),
      ),
    );
  }

  void _openArtistPage(BuildContext context, String artistName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(artistName),
        content: Text('$artistName sanatçısının detayları yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    Navigator.pushNamed(context, '/search');
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimler'),
        content: const Text('Bildirim ayarları yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

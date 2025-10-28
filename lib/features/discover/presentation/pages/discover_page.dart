import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _categories = [];
  late TabController _tabController;
  
  String _currentViewMode = 'grid';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        EnhancedSpotifyService.getNewReleases(limit: 20),
        EnhancedSpotifyService.getTopTracks(limit: 20),
        EnhancedSpotifyService.getFeaturedPlaylists(limit: 10),
        EnhancedSpotifyService.getCategories(limit: 12),
      ]);

      if (mounted) {
        setState(() {
          _newReleases = results[0];
          _topTracks = results[1];
          _featured = results[2];
          _categories = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading discover data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_currentViewMode == 'grid' ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _currentViewMode = _currentViewMode == 'grid' ? 'list' : 'grid'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ModernDesignSystem.accentPurple,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          indicatorColor: ModernDesignSystem.accentPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Yeni Çıkanlar'),
            Tab(text: 'Popüler'),
            Tab(text: 'Playlistler'),
            Tab(text: 'Kategoriler'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildNewReleasesTab(isDark),
            _buildTopTracksTab(isDark),
            _buildFeaturedTab(isDark),
            _buildCategoriesTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNewReleasesTab(bool isDark) {
    if (_isLoading) {
      return _currentViewMode == 'grid'
          ? const GridSkeleton(itemCount: 20)
          : const ListSkeleton(itemCount: 20);
    }

    if (_newReleases.isEmpty) {
      return Center(
        child: Text(
          'Yeni çıkan albüm bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    if (_currentViewMode == 'grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _newReleases.length,
        itemBuilder: (context, index) => AlbumCard(album: _newReleases[index]),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _newReleases.length,
        itemBuilder: (context, index) {
          // Convert album to track format for TrackCard
          final album = _newReleases[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AlbumCard(album: album),
          );
        },
      );
    }
  }

  Widget _buildTopTracksTab(bool isDark) {
    if (_isLoading) {
      return const ListSkeleton(itemCount: 20);
    }

    if (_topTracks.isEmpty) {
      return Center(
        child: Text(
          'Popüler şarkı bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topTracks.length,
      itemBuilder: (context, index) => TrackCard(track: _topTracks[index]),
    );
  }

  Widget _buildFeaturedTab(bool isDark) {
    if (_isLoading) {
      return const GridSkeleton(itemCount: 10);
    }

    if (_featured.isEmpty) {
      return Center(
        child: Text(
          'Öne çıkan playlist bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _featured.length,
      itemBuilder: (context, index) => AlbumCard(album: _featured[index]),
    );
  }

  Widget _buildCategoriesTab(bool isDark) {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => const AlbumCardSkeleton(),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'Kategori bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final name = category['name'] ?? 'Unknown';
        final icons = category['icons'] as List?;
        final imageUrl = icons?.isNotEmpty == true ? icons![0]['url'] : null;

        return InkWell(
          onTap: () {
            // Navigate to category detail
          },
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          child: Container(
            decoration: BoxDecoration(
              gradient: _getCategoryGradient(index),
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(name),
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getCategoryGradient(int index) {
    final gradients = [
      ModernDesignSystem.primaryGradient,
      ModernDesignSystem.purpleGradient,
      ModernDesignSystem.blueGradient,
      ModernDesignSystem.sunsetGradient,
      ModernDesignSystem.modernGradient,
    ];
    return gradients[index % gradients.length];
  }

  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('rock')) return Icons.music_note;
    if (nameLower.contains('pop')) return Icons.star;
    if (nameLower.contains('jazz')) return Icons.piano;
    if (nameLower.contains('hip')) return Icons.mic;
    if (nameLower.contains('electronic')) return Icons.equalizer;
    if (nameLower.contains('classical')) return Icons.music_video;
    if (nameLower.contains('country')) return Icons.landscape;
    if (nameLower.contains('latin')) return Icons.celebration;
    if (nameLower.contains('metal')) return Icons.bolt;
    if (nameLower.contains('indie')) return Icons.headphones;
    return Icons.music_note;
  }
}

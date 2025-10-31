import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/loading_skeletons.dart';

class DiscoverSectionPage extends ConsumerStatefulWidget {
  final String title;
  final String sectionType; // 'new-releases', 'popular', 'top-albums', etc.
  
  const DiscoverSectionPage({
    super.key,
    required this.title,
    required this.sectionType,
  });

  @override
  ConsumerState<DiscoverSectionPage> createState() => _DiscoverSectionPageState();
}

class _DiscoverSectionPageState extends ConsumerState<DiscoverSectionPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> data = [];

      switch (widget.sectionType) {
        case 'new-releases':
          data = await EnhancedSpotifyService.getNewReleases(limit: 50);
          break;
        case 'popular':
          data = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 50);
          break;
        case 'top-albums':
          data = await EnhancedSpotifyService.getNewReleases(limit: 50); // Placeholder
          break;
        case 'top-tracks':
          data = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 50);
          break;
        case 'top-artists':
          data = []; // TODO: Implement
          break;
        case 'popular-albums':
          data = await EnhancedSpotifyService.getNewReleases(limit: 50);
          break;
        case 'popular-artists':
          data = []; // TODO: Implement
          break;
        case 'popular-tracks':
          data = await EnhancedSpotifyService.getGlobalPopularTracks(limit: 50);
          break;
        case 'recommended-albums':
          data = await EnhancedSpotifyService.getNewReleases(limit: 20);
          break;
        case 'recommended-users':
          data = []; // TODO: Implement from Firestore
          break;
        case 'trending-users':
          data = []; // TODO: Implement from Firestore
          break;
        case 'reviews':
          data = []; // TODO: Implement from Firestore
          break;
        case 'playlists':
          data = []; // TODO: Implement from Firestore
          break;
        case 'friends-lists':
          data = []; // TODO: Implement from Firestore
          break;
        default:
          data = [];
      }

      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ${widget.sectionType}: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const GridSkeleton(itemCount: 20)
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(isDark),
                ),
    );
  }

  Widget _buildContent(bool isDark) {
    // Determine if items are tracks or albums based on type
    final isTrackList = widget.sectionType.contains('track') || widget.sectionType == 'popular';
    
    if (isTrackList) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TrackCard(
            key: ValueKey(_items[index]['id']),
            track: _items[index],
          ),
        ),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) => AlbumCard(
          key: ValueKey(_items[index]['id']),
          album: _items[index],
        ),
      );
    }
  }
}

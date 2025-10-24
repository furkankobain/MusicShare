import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/favorites_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorilerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ModernDesignSystem.primaryGreen,
          unselectedLabelColor: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
          indicatorColor: ModernDesignSystem.primaryGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Şarkılar'),
            Tab(text: 'Albümler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllFavorites(isDark),
          _buildFavoriteTracks(isDark),
          _buildFavoriteAlbums(isDark),
        ],
      ),
    );
  }

  Widget _buildAllFavorites(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FavoritesService.getAllFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return _buildEmptyState(
            'Henüz favori eklemediniz',
            'Şarkı veya albümleri favorilere ekleyerek buradan kolayca erişebilirsiniz',
            isDark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final item = favorites[index];
            final type = item['type'] as String;
            
            if (type == 'track') {
              return _buildTrackCard(item, isDark);
            } else {
              return _buildAlbumCard(item, isDark);
            }
          },
        );
      },
    );
  }

  Widget _buildFavoriteTracks(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FavoritesService.getFavoriteTracks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final tracks = snapshot.data ?? [];

        if (tracks.isEmpty) {
          return _buildEmptyState(
            'Henüz favori şarkı eklemediniz',
            'Beğendiğiniz şarkıları favorilere ekleyin',
            isDark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            return _buildTrackCard(tracks[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildFavoriteAlbums(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FavoritesService.getFavoriteAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return _buildEmptyState(
            'Henüz favori albüm eklemediniz',
            'Beğendiğiniz albümleri favorilere ekleyin',
            isDark,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            return _buildAlbumGridCard(albums[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track, bool isDark) {
    final trackName = track['name'] as String? ?? 'Unknown';
    final artists = track['artists'] as List? ?? [];
    final artistNames = artists.isNotEmpty
        ? artists.map((a) => a['name'] as String).join(', ')
        : 'Unknown Artist';
    final albumData = track['album'] as Map<String, dynamic>?;
    final images = albumData?['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    return GestureDetector(
      onTap: () => context.push('/track-detail', extra: track),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? ModernDesignSystem.darkCard
              : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isDark
                ? ModernDesignSystem.darkBorder
                : ModernDesignSystem.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: ModernDesignSystem.darkCard,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: ModernDesignSystem.darkCard,
                        child: const Icon(Icons.music_note),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: ModernDesignSystem.darkCard,
                      child: const Icon(Icons.music_note),
                    ),
            ),

            const SizedBox(width: 12),

            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: ModernDesignSystem.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                      fontSize: ModernDesignSystem.fontSizeS,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Favorite Icon
            Icon(
              Icons.bookmark,
              color: ModernDesignSystem.accentYellow,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, bool isDark) {
    final albumName = album['name'] as String? ?? 'Unknown Album';
    final artists = album['artists'] as List? ?? [];
    final artistNames = artists.isNotEmpty
        ? artists.map((a) => a['name'] as String).join(', ')
        : 'Unknown Artist';
    final images = album['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    return GestureDetector(
      onTap: () => context.push('/album-detail', extra: album),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? ModernDesignSystem.darkCard
              : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isDark
                ? ModernDesignSystem.darkBorder
                : ModernDesignSystem.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: ModernDesignSystem.darkCard,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: ModernDesignSystem.darkCard,
                        child: const Icon(Icons.album),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: ModernDesignSystem.darkCard,
                      child: const Icon(Icons.album),
                    ),
            ),

            const SizedBox(width: 12),

            // Album Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: ModernDesignSystem.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                      fontSize: ModernDesignSystem.fontSizeS,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Favorite Icon
            Icon(
              Icons.bookmark,
              color: ModernDesignSystem.accentYellow,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGridCard(Map<String, dynamic> album, bool isDark) {
    final albumName = album['name'] as String? ?? 'Unknown Album';
    final artists = album['artists'] as List? ?? [];
    final artistName = artists.isNotEmpty
        ? artists[0]['name'] as String
        : 'Unknown Artist';
    final images = album['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;

    return GestureDetector(
      onTap: () => context.push('/album-detail', extra: album),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? ModernDesignSystem.darkCard
              : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isDark
                ? ModernDesignSystem.darkBorder
                : ModernDesignSystem.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ModernDesignSystem.radiusM),
                      topRight: Radius.circular(ModernDesignSystem.radiusM),
                    ),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: ModernDesignSystem.darkCard,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: ModernDesignSystem.darkCard,
                              child: const Icon(Icons.album, size: 48),
                            ),
                          )
                        : Container(
                            color: ModernDesignSystem.darkCard,
                            child: const Icon(Icons.album, size: 48),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ModernDesignSystem.accentYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Album Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: ModernDesignSystem.fontSizeS,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistName,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                      fontSize: ModernDesignSystem.fontSizeXS,
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
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 100,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeM,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

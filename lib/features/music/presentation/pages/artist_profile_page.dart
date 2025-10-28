import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/lastfm_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtistProfilePage extends StatefulWidget {
  final Map<String, dynamic> artist;

  const ArtistProfilePage({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _albums = [];
  Map<String, dynamic>? _artistDetails;
  Map<String, dynamic>? _lastFmInfo;
  List<Map<String, dynamic>> _similarArtists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    setState(() => _isLoading = true);

    try {
      final artistId = widget.artist['id'] as String;
      final artistName = widget.artist['name'] as String;

      // Load artist details, top tracks, albums, Last.fm info, and similar artists in parallel
      final results = await Future.wait([
        _getArtistDetails(artistId),
        _getArtistTopTracks(artistId),
        _getArtistAlbums(artistId),
        _getLastFmInfo(artistName),
        _getSimilarArtists(artistName),
      ]);

      setState(() {
        _artistDetails = results[0] as Map<String, dynamic>?;
        _topTracks = results[1] as List<Map<String, dynamic>>;
        _albums = results[2] as List<Map<String, dynamic>>;
        _lastFmInfo = results[3] as Map<String, dynamic>?;
        _similarArtists = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artist data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getArtistDetails(String artistId) async {
    try {
      // Try to get more details from Spotify API
      return await EnhancedSpotifyService.getArtistInfo(artistId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getArtistTopTracks(String artistId) async {
    try {
      // Use the new getArtistTopTracks method
      return await EnhancedSpotifyService.getArtistTopTracks(artistId);
    } catch (e) {
      print('Error loading top tracks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getArtistAlbums(String artistId) async {
    try {
      // Use the new getArtistAlbums method
      // Include only albums and singles
      return await EnhancedSpotifyService.getArtistAlbums(
        artistId,
        includeGroups: 'album,single',
      );
    } catch (e) {
      print('Error loading albums: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getLastFmInfo(String artistName) async {
    try {
      return await LastFmService.getArtistInfo(artist: artistName);
    } catch (e) {
      print('Error loading Last.fm info: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getSimilarArtists(String artistName) async {
    try {
      return await LastFmService.getSimilarArtists(
        artist: artistName,
        limit: 10,
      );
    } catch (e) {
      print('Error loading similar artists: $e');
      return [];
    }
  }

  String _formatFollowers(int? followers) {
    if (followers == null) return '0';
    if (followers >= 1000000) {
      return '${(followers / 1000000).toStringAsFixed(1)}M';
    } else if (followers >= 1000) {
      return '${(followers / 1000).toStringAsFixed(1)}K';
    }
    return followers.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artistName = widget.artist['name'] as String? ?? 'Unknown Artist';
    final artistImage = _getArtistImage();
    final followers = _artistDetails?['followers']?['total'] as int? ??
        widget.artist['followers']?['total'] as int?;
    final genres = _artistDetails?['genres'] as List? ??
        widget.artist['genres'] as List? ??
        [];
    final popularity = _artistDetails?['popularity'] as int? ??
        widget.artist['popularity'] as int? ??
        0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Artist Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: isDark
                ? ModernDesignSystem.darkBackground
                : ModernDesignSystem.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artist Image
                  if (artistImage != null)
                    CachedNetworkImage(
                      imageUrl: artistImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ModernDesignSystem.darkCard,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ModernDesignSystem.darkCard,
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: ModernDesignSystem.purpleGradient,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Artist Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verified Badge (optional)
                        if (followers != null && followers > 100000)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ModernDesignSystem.primaryGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Artist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ModernDesignSystem.fontSizeXS,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Artist Name
                        Text(
                          artistName,
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeXXXL,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Stats Row
                        Row(
                          children: [
                            if (followers != null) ...[
                              Icon(
                                Icons.people,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatFollowers(followers)} takipçi',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: ModernDesignSystem.fontSizeS,
                                ),
                              ),
                            ],
                            if (followers != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Icon(
                                  Icons.headphones,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatFollowers(followers)} aylık dinleyici',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: ModernDesignSystem.fontSizeS,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Share Button
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
              // Spotify Link
              if (widget.artist['external_urls']?['spotify'] != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final url = widget.artist['external_urls']['spotify'] as String;
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
            ],
          ),

          // Genres
          if (genres.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: ModernDesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        genre.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: ModernDesignSystem.fontSizeS,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: ModernDesignSystem.primaryGreen,
                unselectedLabelColor: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                indicatorColor: ModernDesignSystem.primaryGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: ModernDesignSystem.fontSizeM,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Hakkında'),
                  Tab(text: 'Popüler Şarkılar'),
                  Tab(text: 'Diskografi'),
                ],
              ),
              isDark,
            ),
          ),

          // Tab Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(isDark),
                  _buildTopTracks(isDark),
                  _buildAlbums(isDark),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _getArtistImage() {
    final images = _artistDetails?['images'] as List? ??
        widget.artist['images'] as List? ??
        [];

    if (images.isNotEmpty) {
      final firstImage = images[0] as Map<String, dynamic>;
      return firstImage['url'] as String?;
    }
    return null;
  }

  Widget _buildAboutTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          if (_lastFmInfo != null && _lastFmInfo!['bio'] != null) ...[
            if (_lastFmInfo!['bio'] is Map && 
                (_lastFmInfo!['bio'] as Map)['content'] != null) ...[
              Text(
                'Hakkında',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _cleanBioText((_lastFmInfo!['bio'] as Map)['content'] as String),
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeM,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],

          // Similar Artists Section
          if (_similarArtists.isNotEmpty) ...[
            Text(
              'Benzer Sanatçılar',
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _similarArtists.length,
              itemBuilder: (context, index) {
                final artist = _similarArtists[index];
                return _buildSimilarArtistCard(artist, isDark);
              },
            ),
          ],

          // Empty State
          if ((_lastFmInfo == null || 
               _lastFmInfo!['bio'] == null || 
               (_lastFmInfo!['bio'] is Map && (_lastFmInfo!['bio'] as Map)['content'] == null)) &&
              _similarArtists.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bilgi bulunamadı',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: ModernDesignSystem.fontSizeM,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _cleanBioText(String bio) {
    // Remove HTML tags and clean up Last.fm bio text
    return bio
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildSimilarArtistCard(Map<String, dynamic> artist, bool isDark) {
    final artistName = artist['name'] as String? ?? 'Unknown';
    final imageUrl = artist['image'] as String?;

    return GestureDetector(
      onTap: () {
        // Navigate to similar artist profile
        // Note: We need the full artist object with ID for Spotify
        // For now, just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$artistName profili yükleniyor...')),
        );
      },
      child: Column(
        children: [
          Expanded(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: ModernDesignSystem.darkCard,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: ModernDesignSystem.darkCard,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : Container(
                        color: ModernDesignSystem.darkCard,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artistName,
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracks(bool isDark) {
    if (_topTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Şarkı bulunamadı',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: ModernDesignSystem.fontSizeM,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _topTracks.length,
      itemBuilder: (context, index) {
        final track = _topTracks[index];
        return _buildTrackCard(track, index + 1, isDark);
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track, int index, bool isDark) {
    final trackName = track['name'] as String? ?? 'Unknown';
    final albumData = track['album'] as Map<String, dynamic>?;
    final albumName = albumData?['name'] as String? ?? '';
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
            // Track Number
            SizedBox(
              width: 32,
              child: Text(
                '$index',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                  fontSize: ModernDesignSystem.fontSizeM,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 12),

            // Album Cover
            if (imageUrl != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(ModernDesignSystem.radiusS),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 50,
                    height: 50,
                    color: ModernDesignSystem.darkCard,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 50,
                    height: 50,
                    color: ModernDesignSystem.darkCard,
                    child: const Icon(Icons.music_note, size: 24),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ModernDesignSystem.darkCard,
                  borderRadius:
                      BorderRadius.circular(ModernDesignSystem.radiusS),
                ),
                child: const Icon(Icons.music_note, size: 24),
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
                  if (albumName.isNotEmpty)
                    Text(
                      albumName,
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

            // Play Button
            IconButton(
              icon: Icon(
                Icons.play_circle_filled,
                color: ModernDesignSystem.primaryGreen,
                size: 32,
              ),
              onPressed: () async {
                final spotifyUrl =
                    track['external_urls']?['spotify'] as String?;
                if (spotifyUrl != null) {
                  final uri = Uri.parse(spotifyUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbums(bool isDark) {
    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Albüm bulunamadı',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: ModernDesignSystem.fontSizeM,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _buildAlbumCard(album, isDark);
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, bool isDark) {
    final albumName = album['name'] as String? ?? 'Unknown Album';
    final images = album['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final releaseDate = album['release_date'] as String? ?? '';
    final year = releaseDate.isNotEmpty ? releaseDate.split('-')[0] : '';

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
              child: ClipRRect(
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
                  if (year.isNotEmpty)
                    Text(
                      year,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                        fontSize: ModernDesignSystem.fontSizeXS,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark
          ? ModernDesignSystem.darkBackground
          : ModernDesignSystem.lightBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

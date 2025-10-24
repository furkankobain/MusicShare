import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AlbumDetailPage extends StatefulWidget {
  final Map<String, dynamic> album;

  const AlbumDetailPage({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _albumDetails;
  List<Map<String, dynamic>> _tracks = [];
  double _userRating = 0.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadAlbumDetails();
  }

  Future<void> _loadAlbumDetails() async {
    setState(() => _isLoading = true);

    try {
      final albumId = widget.album['id'] as String;
      final details = await EnhancedSpotifyService.getAlbumInfo(albumId);

      if (mounted) {
        setState(() {
          _albumDetails = details;
          if (details != null && details['tracks']?['items'] != null) {
            _tracks = (details['tracks']['items'] as List)
                .cast<Map<String, dynamic>>();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading album details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '--:--';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatReleaseDate(String? date) {
    if (date == null || date.isEmpty) return 'Unknown';
    try {
      final parts = date.split('-');
      if (parts.length >= 1) {
        return parts[0]; // Year
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  int _getTotalDuration() {
    int total = 0;
    for (var track in _tracks) {
      total += (track['duration_ms'] as int?) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final albumName = _albumDetails?['name'] ?? widget.album['name'] ?? 'Unknown Album';
    final artists = _albumDetails?['artists'] ?? widget.album['artists'] ?? [];
    final artistNames = artists.isNotEmpty
        ? (artists as List).map((a) => a['name'] as String).join(', ')
        : 'Unknown Artist';
    final images = _albumDetails?['images'] ?? widget.album['images'] ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final releaseDate = _albumDetails?['release_date'] ?? widget.album['release_date'] ?? '';
    final totalTracks = _albumDetails?['total_tracks'] ?? widget.album['total_tracks'] ?? _tracks.length;
    final totalDuration = _getTotalDuration();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Album Cover
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
                  // Album Cover
                  if (imageUrl != null)
                    CachedNetworkImage(
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
                          Icons.album,
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
                        Icons.album,
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

                  // Album Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Album Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ModernDesignSystem.accentPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ALBUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ModernDesignSystem.fontSizeXS,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Album Name
                        Text(
                          albumName,
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeXXL,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Artist Name
                        GestureDetector(
                          onTap: () {
                            if (artists.isNotEmpty) {
                              context.push('/artist-profile', extra: artists[0]);
                            }
                          },
                          child: Text(
                            artistNames,
                            style: TextStyle(
                              fontSize: ModernDesignSystem.fontSizeL,
                              color: ModernDesignSystem.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Album Stats
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatReleaseDate(releaseDate),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: ModernDesignSystem.fontSizeS,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.music_note,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalTracks şarkı',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: ModernDesignSystem.fontSizeS,
                              ),
                            ),
                            if (totalDuration > 0) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(totalDuration),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: ModernDesignSystem.fontSizeS,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Favorite Button
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              // Share Button
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
              // Spotify Link
              if (_albumDetails?['external_urls']?['spotify'] != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final url = _albumDetails!['external_urls']['spotify'] as String;
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
            ],
          ),

          // Rating Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? ModernDesignSystem.darkCard
                    : ModernDesignSystem.lightCard,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                border: Border.all(
                  color: isDark
                      ? ModernDesignSystem.darkBorder
                      : ModernDesignSystem.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Bu albümü değerlendir',
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userRating = (index + 1).toDouble();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: ModernDesignSystem.accentYellow,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_userRating > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_userRating.toStringAsFixed(0)}/5',
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeL,
                        fontWeight: FontWeight.bold,
                        color: ModernDesignSystem.accentYellow,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Track List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Şarkılar',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // Track List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tracks.isEmpty)
            SliverFillRemaining(
              child: Center(
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
                      'Şarkı bilgisi bulunamadı',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                        fontSize: ModernDesignSystem.fontSizeM,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _tracks[index];
                  return _buildTrackItem(track, index + 1, isDark);
                },
                childCount: _tracks.length,
              ),
            ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int trackNumber, bool isDark) {
    final trackName = track['name'] as String? ?? 'Unknown Track';
    final duration = track['duration_ms'] as int?;
    final explicit = track['explicit'] as bool? ?? false;
    final trackArtists = track['artists'] as List? ?? [];
    final artistNames = trackArtists.isNotEmpty
        ? trackArtists.map((a) => a['name'] as String).join(', ')
        : '';

    return GestureDetector(
      onTap: () {
        // Combine album and track data for detail page
        final trackWithAlbum = {
          ...track,
          'album': {
            'name': widget.album['name'],
            'images': widget.album['images'],
            'artists': widget.album['artists'],
          }
        };
        context.push('/track-detail', extra: trackWithAlbum);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? ModernDesignSystem.darkCard.withValues(alpha: 0.5)
              : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isDark
                ? ModernDesignSystem.darkBorder
                : ModernDesignSystem.lightBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Track Number
            SizedBox(
              width: 32,
              child: Text(
                '$trackNumber',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                  fontSize: ModernDesignSystem.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 12),

            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trackName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: ModernDesignSystem.fontSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (explicit)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'E',
                            style: TextStyle(
                              fontSize: ModernDesignSystem.fontSizeXS,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (artistNames.isNotEmpty)
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

            const SizedBox(width: 12),

            // Duration
            Text(
              _formatDuration(duration),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                fontSize: ModernDesignSystem.fontSizeS,
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
                final spotifyUrl = track['external_urls']?['spotify'] as String?;
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
}

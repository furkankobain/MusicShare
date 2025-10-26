import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/profile_service.dart';
import '../../../../shared/services/rating_aggregation_service.dart';
import '../../../../shared/services/rating_cache_service.dart';
import '../../../../shared/widgets/aggregated_rating_display.dart';

class TrackDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> track;

  const TrackDetailPage({
    super.key,
    required this.track,
  });

  @override
  ConsumerState<TrackDetailPage> createState() => _TrackDetailPageState();
}

class _TrackDetailPageState extends ConsumerState<TrackDetailPage> {
  double _userRating = 0;
  bool _isFavorite = false;
  bool _isPinned = false;
  bool _isSavedToSpotify = false;
  bool _isCheckingSpotify = true;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoadingAudio = false;
  AggregatedRating? _aggregatedRating;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _checkSpotifyStatus();
    _checkFavoriteStatus();
    _checkPinnedStatus();
    _setupAudioPlayer();
    _loadAggregatedRating();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null) {
      final isFav = await FavoritesService.isTrackFavorite(trackId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _checkPinnedStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null) {
      final isPinned = await ProfileService.isTrackPinned(trackId);
      if (mounted) {
        setState(() => _isPinned = isPinned);
      }
    }
  }

  Future<void> _loadAggregatedRating() async {
    final trackId = widget.track['id'] as String?;
    final trackName = widget.track['name'] as String?;
    final artistName = (widget.track['artists'] as List?)?.first?['name'] as String?;
    final popularity = widget.track['popularity'] as int?;

    if (trackId != null && trackName != null && artistName != null) {
      // Cache sistemi ile rating getir
      final rating = await RatingCacheService.getRatingWithCache(
        trackId: trackId,
        trackName: trackName,
        artistName: artistName,
        spotifyPopularity: popularity,
      );

      if (mounted) {
        setState(() {
          _aggregatedRating = rating;
          _isLoadingRating = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingRating = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    // First add/remove from favorites
    final success = await FavoritesService.toggleTrackFavorite(widget.track);
    
    if (success && mounted) {
      final newFavoriteStatus = !_isFavorite;
      setState(() => _isFavorite = newFavoriteStatus);
      
      // If adding to favorites, also add to pinned tracks (if not already pinned and space available)
      if (newFavoriteStatus) {
        final currentPinned = await ProfileService.getPinnedTracks();
        if (currentPinned.length < 4 && !_isPinned) {
          final pinSuccess = await ProfileService.addPinnedTrack(widget.track);
          if (pinSuccess && mounted) {
            setState(() => _isPinned = true);
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'Favorilere eklendi'
                : 'Favorilerden çıkarıldı',
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.stopped) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _checkSpotifyStatus() async {
    final trackId = widget.track['id'] as String?;
    if (trackId != null && EnhancedSpotifyService.isConnected) {
      final isSaved = await EnhancedSpotifyService.checkSavedTrack(trackId);
      if (mounted) {
        setState(() {
          _isSavedToSpotify = isSaved;
          _isCheckingSpotify = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingSpotify = false);
      }
    }
  }

  Future<void> _toggleSpotifySave() async {
    final trackId = widget.track['id'] as String?;
    if (trackId == null) return;

    if (!EnhancedSpotifyService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spotify hesabınıza bağlanmanız gerekiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCheckingSpotify = true);

    final success = _isSavedToSpotify
        ? await EnhancedSpotifyService.removeTrack(trackId)
        : await EnhancedSpotifyService.saveTrack(trackId);

    if (mounted) {
      setState(() {
        if (success) {
          _isSavedToSpotify = !_isSavedToSpotify;
        }
        _isCheckingSpotify = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (_isSavedToSpotify
                    ? 'Spotify beğenilen şarkılara eklendi'
                    : 'Spotify beğenilen şarkılardan çıkarıldı')
                : 'İşlem başarısız oldu',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = widget.track;
    
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final artistNames = (track['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';
    final albumName = track['album']?['name'] ?? 'Unknown Album';
    final duration = track['duration_ms'] ?? 0;
    final popularity = track['popularity'] ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: _isFavorite ? ModernDesignSystem.accentYellow : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Share functionality
            },
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
                    ModernDesignSystem.primaryGreen.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: CustomScrollView(
          slivers: [
            // Header with album art
            SliverToBoxAdapter(
              child: _buildHeader(imageUrl, isDark),
            ),
            
            // Track info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Track title
                    Text(
                      track['name'] ?? 'Unknown Track',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Artist name
                    Text(
                      artistNames,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Album name
                    Text(
                      albumName,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats row
                    _buildStatsRow(duration, popularity, isDark),
                    const SizedBox(height: 32),
                    
                    // Aggregated Rating
                    if (_isLoadingRating)
                      const Center(child: CircularProgressIndicator())
                    else if (_aggregatedRating != null)
                      AggregatedRatingDisplay(
                        rating: _aggregatedRating!,
                        showBreakdown: true,
                        showStats: true,
                        compact: false,
                      ),
                    const SizedBox(height: 24),
                    
                    // Rating section
                    _buildRatingSection(isDark),
                    const SizedBox(height: 32),
                    
                    // Play button
                    _buildPlayButton(isDark),
                    const SizedBox(height: 32),
                    
                    // Comments section
                    _buildCommentsSection(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildMiniPlayerBar(isDark),
    );
  }

  Widget _buildMiniPlayerBar(bool isDark) {
    final track = widget.track;
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Album Cover
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey,
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note),
                ),

              const SizedBox(width: 12),

              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (track['artists'] as List?)?.map((a) => a['name']).join(', ') ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Spotify Save Button
              if (_isCheckingSpotify)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: _isSavedToSpotify
                        ? ModernDesignSystem.primaryGreen.withValues(alpha: 0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSavedToSpotify ? Icons.favorite : Icons.favorite_border,
                      color: _isSavedToSpotify
                          ? ModernDesignSystem.primaryGreen
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
                    onPressed: _toggleSpotifySave,
                    tooltip: _isSavedToSpotify
                        ? 'Spotify beğenilenlerden çıkar'
                        : 'Spotify beğenilenlere ekle',
                  ),
                ),

              // Play Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _isPlaying
                      ? LinearGradient(
                          colors: [
                            ModernDesignSystem.primaryGreen.withValues(alpha: 0.8),
                            ModernDesignSystem.secondaryGreen.withValues(alpha: 0.8),
                          ],
                        )
                      : ModernDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final previewUrl = track['preview_url'] as String?;
                      
                      if (previewUrl != null && previewUrl.isNotEmpty) {
                        // Play preview audio
                        if (_isPlaying) {
                          await _audioPlayer.stop();
                          setState(() => _isPlaying = false);
                        } else {
                          setState(() {
                            _isPlaying = true;
                            _isLoadingAudio = true;
                          });
                          
                          try {
                            await _audioPlayer.play(UrlSource(previewUrl));
                            setState(() => _isLoadingAudio = false);
                          } catch (e) {
                            print('Error playing preview: $e');
                            setState(() {
                              _isPlaying = false;
                              _isLoadingAudio = false;
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Önizleme çalınamadı'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      } else {
                        // No preview available, open in Spotify
                        final spotifyUrl = track['external_urls']?['spotify'] as String?;
                        if (spotifyUrl != null) {
                          final uri = Uri.parse(spotifyUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _isLoadingAudio
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? imageUrl, bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (imageUrl != null)
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Icons.music_note,
                      size: 100,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              child: Icon(
                Icons.music_note,
                size: 100,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark ? Colors.black : Colors.white,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int duration, int popularity, bool isDark) {
    return Row(
      children: [
        _buildStatItem(
          Icons.access_time_rounded,
          _formatDuration(duration),
          isDark,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          Icons.trending_up_rounded,
          '$popularity%',
          isDark,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          Icons.favorite_rounded,
          '1.2K',
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: ModernDesignSystem.primaryGreen,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isDark
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Puanınız',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() => _userRating = index + 1.0);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_userRating.toStringAsFixed(0)}/5',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            // TODO: Play track
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, color: Colors.white, size: 32),
              SizedBox(width: 8),
              Text(
                'Spotify\'da Çal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yorumlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: isDark
              ? ModernDesignSystem.darkGlassmorphism
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
                  boxShadow: ModernDesignSystem.mediumShadow,
                ),
          child: Text(
            'Henüz yorum yapılmamış. İlk yorumu siz yapın!',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

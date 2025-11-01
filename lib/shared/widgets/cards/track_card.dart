import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../core/theme/modern_design_system.dart';
import '../../services/mini_player_service.dart';
import '../../services/haptic_service.dart';
import '../../services/music_player_service.dart';

class TrackCard extends StatefulWidget {
  final Map<String, dynamic> track;
  final VoidCallback? onTap;
  final bool showAlbumArt;
  final bool showFavorite;

  const TrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.showAlbumArt = true,
    this.showFavorite = true,
  });

  @override
  State<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends State<TrackCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isCurrentlyPlaying = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Listen to player state changes
    MusicPlayerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isCurrentlyPlaying = MusicPlayerService.currentTrackId == widget.track['id'] &&
                                MusicPlayerService.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '--:--';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handlePlayPause() async {
    HapticService.mediumImpact();
    
    final previewUrl = widget.track['preview_url'] as String?;
    
    if (previewUrl == null || previewUrl.isEmpty) {
      // Show snackbar if no preview available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preview not available for this track'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    final trackName = widget.track['name'] as String? ?? 'Unknown Track';
    final artists = widget.track['artists'] as List?;
    final artistNames = artists?.isNotEmpty == true
        ? artists!.map((a) => a['name'] as String).join(', ')
        : 'Unknown Artist';
    final album = widget.track['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    
    await MusicPlayerService.playTrack(
      trackId: widget.track['id'] as String,
      previewUrl: previewUrl,
      trackName: trackName,
      artistName: artistNames,
      imageUrl: imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackName = widget.track['name'] as String? ?? 'Unknown Track';
    final artists = widget.track['artists'] as List?;
    final artistNames = artists?.isNotEmpty == true
        ? artists!.map((a) => a['name'] as String).join(', ')
        : 'Unknown Artist';
    final album = widget.track['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    final duration = widget.track['duration_ms'] as int?;
    final explicit = widget.track['explicit'] as bool? ?? false;

    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
        HapticService.lightImpact();
      },
      onTapUp: (_) {
        _animationController.reverse();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push('/track-detail', extra: widget.track);
        }
      },
      onTapCancel: () => _animationController.reverse(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? ModernDesignSystem.darkCard
                    : ModernDesignSystem.lightCard,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                border: Border.all(
                  color: _isHovered
                      ? ModernDesignSystem.accentPurple.withOpacity(0.5)
                      : (isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: ModernDesignSystem.accentPurple.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Album Art
                  if (widget.showAlbumArt) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 56,
                                    height: 56,
                                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 56,
                                    height: 56,
                                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                                    child: const Icon(Icons.music_note, size: 24),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: ModernDesignSystem.purpleGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                                ),
                        ),
                        // Play overlay on hover
                        if (_isHovered)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _handlePlayPause,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _isCurrentlyPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Track Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'E',
                                  style: TextStyle(
                                    fontSize: ModernDesignSystem.fontSizeXS,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artistNames,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: ModernDesignSystem.fontSizeS,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Play/Pause Button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isCurrentlyPlaying
                          ? ModernDesignSystem.accentPurple.withOpacity(0.1)
                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(18),
                      border: _isCurrentlyPlaying
                          ? Border.all(color: ModernDesignSystem.accentPurple, width: 2)
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                        color: _isCurrentlyPlaying
                            ? ModernDesignSystem.accentPurple
                            : (isDark ? Colors.white : Colors.black),
                        size: 20,
                      ),
                      onPressed: _handlePlayPause,
                    ),
                  ),

                  const SizedBox(width: 8),
                  
                  // Duration
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: ModernDesignSystem.fontSizeS,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Favorite Button
                  if (widget.showFavorite)
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact track card for small lists
class CompactTrackCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final int? trackNumber;
  final VoidCallback? onTap;

  const CompactTrackCard({
    super.key,
    required this.track,
    this.trackNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackName = track['name'] as String? ?? 'Unknown Track';

    return InkWell(
      onTap: onTap ?? () => context.push('/track-detail', extra: track),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (trackNumber != null) ...[
              SizedBox(
                width: 24,
                child: Text(
                  '$trackNumber',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: ModernDesignSystem.fontSizeS,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                trackName,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: ModernDesignSystem.fontSizeM,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: ModernDesignSystem.primaryGreen,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

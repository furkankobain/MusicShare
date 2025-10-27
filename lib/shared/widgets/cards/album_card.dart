import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/modern_design_system.dart';

class AlbumCard extends StatefulWidget {
  final Map<String, dynamic> album;
  final VoidCallback? onTap;
  final bool showArtist;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.showArtist = true,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final albumName = widget.album['name'] as String? ?? 'Unknown Album';
    final artists = widget.album['artists'] as List?;
    final artistName = artists?.isNotEmpty == true
        ? (artists!.first['name'] as String? ?? 'Unknown Artist')
        : 'Unknown Artist';
    final images = widget.album['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    final releaseDate = widget.album['release_date'] as String?;
    final year = releaseDate?.split('-').first;

    return GestureDetector(
      onTap: widget.onTap ?? () => context.push('/album-detail', extra: widget.album),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_rotationAnimation.value),
              alignment: Alignment.center,
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
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: ModernDesignSystem.accentPurple.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album Cover
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(ModernDesignSystem.radiusM),
                            ),
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        gradient: ModernDesignSystem.primaryGradient,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.album, size: 48, color: Colors.white),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: ModernDesignSystem.primaryGradient,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.album, size: 48, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                        // Play overlay on hover
                        if (_isHovered)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(ModernDesignSystem.radiusM),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: ModernDesignSystem.primaryGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: ModernDesignSystem.primaryGreen.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                              fontSize: ModernDesignSystem.fontSizeM,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (widget.showArtist)
                            Text(
                              artistName,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: ModernDesignSystem.fontSizeS,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (year != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ModernDesignSystem.accentPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                year,
                                style: TextStyle(
                                  color: ModernDesignSystem.accentPurple,
                                  fontSize: ModernDesignSystem.fontSizeXS,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal album card for carousels
class HorizontalAlbumCard extends StatelessWidget {
  final Map<String, dynamic> album;
  final VoidCallback? onTap;

  const HorizontalAlbumCard({
    super.key,
    required this.album,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final albumName = album['name'] as String? ?? 'Unknown Album';
    final artists = album['artists'] as List?;
    final artistName = artists?.isNotEmpty == true
        ? (artists!.first['name'] as String? ?? 'Unknown Artist')
        : 'Unknown Artist';
    final images = album['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;

    return GestureDetector(
      onTap: onTap ?? () => context.push('/album-detail', extra: album),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: ModernDesignSystem.primaryGradient,
                          ),
                          child: const Icon(Icons.album, size: 48, color: Colors.white),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: ModernDesignSystem.primaryGradient,
                        ),
                        child: const Icon(Icons.album, size: 48, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              albumName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: ModernDesignSystem.fontSizeS,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artistName,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: ModernDesignSystem.fontSizeXS,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

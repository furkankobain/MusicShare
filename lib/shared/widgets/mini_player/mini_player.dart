import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/mini_player_service.dart';
import '../../services/haptic_service.dart';
import '../../../core/theme/modern_design_system.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  final MiniPlayerService _playerService = MiniPlayerService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _playerService.addListener(_onPlayerChange);
    if (_playerService.hasTrack) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerChange);
    _slideController.dispose();
    super.dispose();
  }

  void _onPlayerChange() {
    if (mounted) {
      if (_playerService.hasTrack) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_playerService.hasTrack) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = _playerService.currentTrack!;
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final trackName = track['name'] ?? 'Unknown Track';
    final artistName = (track['artists'] as List?)?.isNotEmpty == true
        ? track['artists'][0]['name']
        : 'Unknown Artist';

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? ModernDesignSystem.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: LinearProgressIndicator(
                value: _playerService.progress,
                minHeight: 2,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E5E)),
              ),
            ),
            // Player content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album art
                    GestureDetector(
                      onTap: () => context.push('/track-detail', extra: track),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? const Icon(Icons.music_note, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Track info
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/track-detail', extra: track),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trackName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artistName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFFFF5E5E),
                        size: 28,
                      ),
                      onPressed: () {
                        HapticService.lightImpact();
                        _playerService.togglePlayPause();
                      },
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        HapticService.lightImpact();
                        _playerService.stop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

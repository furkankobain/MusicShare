import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/spotify_sync_service.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';

/// Page to handle Spotify OAuth callback
class SpotifyCallbackPage extends StatefulWidget {
  final String? code;
  final String? state;
  final String? error;

  const SpotifyCallbackPage({
    super.key,
    this.code,
    this.state,
    this.error,
  });

  @override
  State<SpotifyCallbackPage> createState() => _SpotifyCallbackPageState();
}

class _SpotifyCallbackPageState extends State<SpotifyCallbackPage> {
  bool _isProcessing = true;
  String _statusMessage = 'Spotify bağlantısı kuruluyor...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Check for errors from Spotify
      if (widget.error != null) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Spotify yetkilendirmesi iptal edildi';
        });
        return;
      }

      // Check if we have the authorization code
      if (widget.code == null || widget.state == null) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Geçersiz yetkilendirme kodu';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Token alınıyor...';
      });

      // Exchange authorization code for access token
      final success = await EnhancedSpotifyService.handleAuthCallback(
        widget.code!,
        widget.state!,
      );

      if (success) {
        setState(() {
          _statusMessage = 'Profil bilgileri çekiliyor...';
        });

        // Fetch user profile
        await EnhancedSpotifyService.fetchUserProfile();

        setState(() {
          _statusMessage = 'Spotify verileri senkronize ediliyor...';
        });

        // Sync Spotify data (profile, playlists, etc.)
        await SpotifySyncService.fullSync();

        setState(() {
          _isProcessing = false;
          _statusMessage = 'Başarıyla bağlandı!';
        });

        // Wait a moment to show success message
        await Future.delayed(const Duration(seconds: 1));

        // Navigate to home page
        if (mounted) {
          context.go('/');
        }
      } else {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _statusMessage = 'Spotify bağlantısı kurulamadı';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _statusMessage = 'Hata oluştu: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.lightBackground.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: _hasError
                          ? LinearGradient(
                              colors: [
                                ModernDesignSystem.error,
                                ModernDesignSystem.error.withValues(alpha: 0.7),
                              ],
                            )
                          : ModernDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXXL),
                      boxShadow: [
                        BoxShadow(
                          color: (_hasError
                                  ? ModernDesignSystem.error
                                  : ModernDesignSystem.primaryGreen)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _hasError
                          ? Icons.error_outline
                          : _isProcessing
                              ? Icons.music_note
                              : Icons.check_circle_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: ModernDesignSystem.spacingXXL),

                  // Loading indicator
                  if (_isProcessing)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ModernDesignSystem.primaryGreen,
                      ),
                    ),

                  const SizedBox(height: ModernDesignSystem.spacingXL),

                  // Status message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ModernDesignSystem.textOnDark
                          : ModernDesignSystem.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (_hasError) ...[
                    const SizedBox(height: ModernDesignSystem.spacingXXL),
                    EnhancedButton(
                      text: 'Geri Dön',
                      type: ButtonType.primary,
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

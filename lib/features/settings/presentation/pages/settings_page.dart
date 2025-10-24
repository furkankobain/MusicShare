import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import '../../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../../shared/widgets/feedback/feedback_widgets.dart';
import '../../../../shared/services/app_rating_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/google_sign_in_service.dart';
import '../../../../core/theme/modern_design_system.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeColors = ref.watch(themeColorsProvider);
    final animationState = ref.watch(animationProvider);
    final accessibilityState = ref.watch(accessibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: EnhancedAnimations.staggeredFadeIn(
        children: [
          _buildThemeSection(context, ref, themeMode, themeColors),
          _buildAnimationSection(context, ref, animationState),
          _buildAccessibilitySection(context, ref, accessibilityState),
          _buildSpotifySection(context, ref),
          _buildNotificationsSection(context, ref),
          _buildFeedbackSection(context, ref),
          _buildAboutSection(context, ref),
          _buildLogoutSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    ThemeColors themeColors,
  ) {
    return EnhancedCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Tema',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildThemeOption(
            context,
            ref,
            'Sistem',
            'Sistem temasını takip eder',
            ThemeMode.system,
            themeMode,
            Icons.settings_system_daydream,
          ),
          _buildThemeOption(
            context,
            ref,
            'Açık Tema',
            'Açık renk teması',
            ThemeMode.light,
            themeMode,
            Icons.light_mode,
          ),
          _buildThemeOption(
            context,
            ref,
            'Koyu Tema',
            'Koyu renk teması',
            ThemeMode.dark,
            themeMode,
            Icons.dark_mode,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    ThemeMode mode,
    ThemeMode currentMode,
    IconData icon,
  ) {
    // final isSelected = currentMode == mode; // Unused variable
    final themeColors = ref.watch(themeColorsProvider);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<ThemeMode>(
        value: mode,
        // ignore: deprecated_member_use
        groupValue: currentMode,
        // ignore: deprecated_member_use
        onChanged: (ThemeMode? value) {
          if (value != null) {
            ref.read(themeProvider.notifier).setTheme(value);
          }
        },
        // ignore: deprecated_member_use
        // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
      ),
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
    );
  }

  Widget _buildAnimationSection(
    BuildContext context,
    WidgetRef ref,
    AnimationState animationState,
  ) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.animation,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Animasyonlar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Animasyonları Etkinleştir'),
            subtitle: const Text('Arayüz animasyonlarını aç/kapat'),
            value: animationState.animationsEnabled,
            onChanged: (bool value) {
              if (value) {
                ref.read(animationProvider.notifier).enableAnimations();
              } else {
                ref.read(animationProvider.notifier).disableAnimations();
              }
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          if (animationState.animationsEnabled) ...[
            ListTile(
              title: const Text('Animasyon Hızı'),
              subtitle: Text(_getAnimationSpeedText(animationState.animationDuration)),
              trailing: DropdownButton<Duration>(
                value: animationState.animationDuration,
                onChanged: (Duration? value) {
                  if (value != null) {
                    ref.read(animationProvider.notifier).setAnimationDuration(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Duration(milliseconds: 150),
                    child: Text('Hızlı'),
                  ),
                  DropdownMenuItem(
                    value: Duration(milliseconds: 300),
                    child: Text('Normal'),
                  ),
                  DropdownMenuItem(
                    value: Duration(milliseconds: 500),
                    child: Text('Yavaş'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection(
    BuildContext context,
    WidgetRef ref,
    AccessibilityState accessibilityState,
  ) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Erişilebilirlik',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Yüksek Kontrast'),
            subtitle: const Text('Daha belirgin renkler kullan'),
            value: accessibilityState.highContrast,
            onChanged: (bool value) {
              ref.read(accessibilityProvider.notifier).setHighContrast(value);
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Büyük Metin'),
            subtitle: const Text('Daha büyük yazı tipleri kullan'),
            value: accessibilityState.largeText,
            onChanged: (bool value) {
              ref.read(accessibilityProvider.notifier).setLargeText(value);
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Azaltılmış Hareket'),
            subtitle: const Text('Animasyonları azalt'),
            value: accessibilityState.reducedMotion,
            onChanged: (bool value) {
              ref.read(accessibilityProvider.notifier).setReducedMotion(value);
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Ekran Okuyucu'),
            subtitle: const Text('Ekran okuyucu desteği'),
            value: accessibilityState.screenReader,
            onChanged: (bool value) {
              ref.read(accessibilityProvider.notifier).setScreenReader(value);
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifySection(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Spotify',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Spotify Bağlantısı'),
            subtitle: const Text('Spotify hesabınızı bağlayın'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/spotify-connect');
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Otomatik Senkronizasyon'),
            subtitle: const Text('Çalma listelerini otomatik senkronize et'),
            trailing: Switch(
              value: true, // Mock value
              onChanged: (bool value) {
                // Handle sync toggle
              },
              // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Bildirimler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push Bildirimleri'),
            subtitle: const Text('Sistem bildirimlerini etkinleştir'),
            value: true, // Mock value
            onChanged: (bool value) {
              // Handle push notifications
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Akıllı Bildirimler'),
            subtitle: const Text('Kişiselleştirilmiş müzik önerileri'),
            value: true, // Mock value
            onChanged: (bool value) {
              // Handle smart notifications
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Günlük Özet'),
            subtitle: const Text('Günlük dinleme özeti bildirimleri'),
            value: false, // Mock value
            onChanged: (bool value) {
              // Handle daily summary
            },
            // ignore: deprecated_member_use
        activeColor: themeColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Geri Bildirim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Geri Bildirim Gönder'),
            subtitle: const Text('Görüşlerinizi paylaşın'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showFeedbackDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Hata Bildir'),
            subtitle: const Text('Sorunları bildirin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showFeedbackDialog(context, 'bug'),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Özellik Öner'),
            subtitle: const Text('Yeni özellikler önerin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showFeedbackDialog(context, 'feature'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Uygulamayı Değerlendir'),
            subtitle: const Text('Play Store\'da puanlayın'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => AppRatingService.showManualRatingDialog(context),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, [String? type]) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(initialType: type),
    );
  }

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: themeColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Hakkında',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Bilgileri'),
            subtitle: const Text('Versiyon 1.0.0'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Gizlilik Politikası'),
            subtitle: const Text('Veri kullanımınız hakkında'),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Kullanım Şartları'),
            subtitle: const Text('Hizmet şartları'),
            onTap: () {
              // Navigate to terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text('Destek'),
            subtitle: const Text('Yardım ve destek'),
            onTap: () {
              _showSupportDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _getAnimationSpeedText(Duration duration) {
    if (duration.inMilliseconds <= 200) {
      return 'Hızlı';
    } else if (duration.inMilliseconds <= 400) {
      return 'Normal';
    } else {
      return 'Yavaş';
    }
  }

  void _showAboutDialog(BuildContext context) {
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'MüzikBoxd',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versiyon 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Müzik deneyiminizi geliştiren akıllı platform',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            EnhancedButton(
              text: 'Tamam',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destek',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yardıma mı ihtiyacınız var? İşte size yardımcı olabilecek bilgiler:',
            ),
            const SizedBox(height: 16),
            const Text('📧 E-posta: destek@muzikboxd.com'),
            const Text('📱 Telefon: +90 (212) 555-0123'),
            const Text('🌐 Web: www.muzikboxd.com/destek'),
            const SizedBox(height: 24),
            EnhancedButton(
              text: 'Tamam',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return EnhancedCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.logout,
                color: ModernDesignSystem.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Hesap',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.logout, color: ModernDesignSystem.error),
            title: Text(
              'Çıkış Yap',
              style: TextStyle(color: ModernDesignSystem.error),
            ),
            subtitle: const Text('Hesabınızdan çıkış yapın'),
            trailing: Icon(Icons.arrow_forward_ios, color: ModernDesignSystem.error),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              size: 64,
              color: ModernDesignSystem.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Çıkış Yap',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EnhancedButton(
                    text: 'İptal',
                    type: ButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnhancedButton(
                    text: 'Çıkış Yap',
                    type: ButtonType.primary,
                    onPressed: () => _handleLogout(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Close dialog first
      Navigator.of(context).pop();

      // Disconnect from Spotify
      await EnhancedSpotifyService.disconnect();

      // Sign out from Google
      await GoogleSignInService.signOut();

      // Sign out from Firebase
      await FirebaseBypassAuthService.signOut();

      // Show success message
      if (context.mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Başarıyla çıkış yapıldı',
          type: SnackbarType.success,
        );
      }

      // Navigate to login page
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Çıkış yapılırken hata oluştu',
          type: SnackbarType.error,
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../shared/widgets/auth/enhanced_auth_components.dart';
import '../../../../shared/widgets/animations/enhanced_animations.dart';
import '../../../../shared/widgets/responsive/responsive_layout.dart';
import '../../../../shared/widgets/ui/enhanced_components.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/google_sign_in_service.dart';
import '../../../../core/utils/result.dart';

class EnhancedLoginPage extends ConsumerStatefulWidget {
  const EnhancedLoginPage({super.key});

  @override
  ConsumerState<EnhancedLoginPage> createState() => _EnhancedLoginPageState();
}

class _EnhancedLoginPageState extends ConsumerState<EnhancedLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          child: ResponsivePadding(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                
                // Header
                EnhancedAnimations.fadeIn(
                  child: _buildHeader(context, isDark),
                ),
                
                const Spacer(flex: 2),
                
                // Form
                EnhancedAnimations.slideIn(
                  child: _buildForm(context, isDark),
                ),
                
                const SizedBox(height: ModernDesignSystem.spacingL),
                
                // Social Login
                EnhancedAnimations.fadeIn(
                  child: _buildSocialLogin(context, isDark),
                ),
                
                const SizedBox(height: ModernDesignSystem.spacingM),
                
                // Signup Link
                EnhancedAnimations.fadeIn(
                  child: _buildSignupLink(context, isDark),
                ),
                
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Logo (daha küçük)
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: ModernDesignSystem.primaryGradient,
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXL),
            boxShadow: [
              BoxShadow(
                color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note,
            size: 35,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: ModernDesignSystem.spacingM),
        
        // Title (daha küçük)
        Text(
          'Hoş Geldiniz',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? ModernDesignSystem.textOnDark : ModernDesignSystem.textPrimary,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Subtitle (daha küçük)
        Text(
          'Hesabınıza giriş yapın',
          style: TextStyle(
            fontSize: 14,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isDark) {
    return EnhancedCard(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email or Username
            TextFormField(
              controller: _emailOrUsernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateLoginUsername,
              decoration: InputDecoration(
                labelText: 'E-posta veya Kullanıcı Adı',
                hintText: 'ornek@email.com veya kullanici_adi',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.primaryGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingM,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: AuthValidators.validateLoginPassword,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                hintText: 'Şifrenizi giriniz',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.primaryGreen, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                  borderSide: BorderSide(color: ModernDesignSystem.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingM,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Remem            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: ModernDesignSystem.primaryGreen,
                      ),
                    ),
                    Text(
                      'Beni Hatırla',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark 
                            ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
                            : ModernDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Şifremi Unuttum',
                    style: TextStyle(
                      fontSize: 12,
                      color: ModernDesignSystem.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Login Button
            EnhancedButton(
              text: 'Giriş Yap',
              type: ButtonType.primary,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.2)
                    : ModernDesignSystem.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingM),
              child: Text(
                'veya',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  color: isDark 
                      ? ModernDesignSystem.textOnDark.withValues(alpha: 0.6)
                      : ModernDesignSystem.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark 
                    ? ModernDesignSystem.textOnDark.withValues(alpha: 0.2)
                    : ModernDesignSystem.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Spotify Sign In Button
        _buildSocialButton(
          context: context,
          isDark: isDark,
          icon: Icons.music_note,
          label: 'Spotify ile Giriş Yap',
          color: const Color(0xFF1DB954), // Spotify green
          onPressed: _handleSpotifySignIn,
        ),
        
        const SizedBox(height: 10),
        
        // Google Sign In Button
        _buildSocialButton(
          context: context,
          isDark: isDark,
          icon: Icons.g_mobiledata,
          label: 'Google ile Giriş Yap',
          color: const Color(0xFF4285F4), // Google blue
          onPressed: _handleGoogleSignIn,
        ),
      ],
    );
  }
  
  Widget _buildSocialButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            SizedBox(width: ModernDesignSystem.spacingM),
            Text(
              label,
              style: const TextStyle(
                fontSize: ModernDesignSystem.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu? ',
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: Text(
            'Kayıt Ol',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeM,
              fontWeight: FontWeight.w600,
              color: ModernDesignSystem.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseBypassAuthService.signIn(
        emailOrUsername: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
      );

      if (result.isSuccess) {
        // Show success message
        EnhancedSnackbar.show(
          context,
          message: 'Başarıyla giriş yapıldı!',
          type: SnackbarType.success,
        );
        
        // Navigate to home page
        context.go('/');
      } else {
        _showErrorDialog(result is Failure ? (result as Failure).message : 'Giriş yaparken bir hata oluştu');
      }
    } catch (e) {
      _showErrorDialog('Beklenmeyen bir hata oluştu: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSpotifySignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Start Spotify OAuth flow
      final success = await EnhancedSpotifyService.authenticate();
      
      if (success) {
        // Note: The actual token exchange will be handled in a deep link handler
        // For now, we just show a message
        EnhancedSnackbar.show(
          context,
          message: 'Spotify yetkilendirmesi başlatıldı. Lütfen tarayıcıda işlemi tamamlayın.',
          type: SnackbarType.info,
        );
      } else {
        EnhancedSnackbar.show(
          context,
          message: 'Spotify bağlantısı başlatılamadı',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      EnhancedSnackbar.show(
        context,
        message: 'Spotify ile giriş yapılırken hata oluştu: ${e.toString()}',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Google Sign-In
      final userCredential = await GoogleSignInService.signInWithGoogle();
      
      if (userCredential != null) {
        // Başarılı giriş
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Google ile başarıyla giriş yapıldı!',
            type: SnackbarType.success,
          );
          
          // Ana sayfaya yönlendir
          context.go('/');
        }
      } else {
        // Kullanıcı iptal etti
        if (mounted) {
          EnhancedSnackbar.show(
            context,
            message: 'Google girişi iptal edildi',
            type: SnackbarType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        EnhancedSnackbar.show(
          context,
          message: 'Google ile giriş yapılırken hata oluştu: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_reset,
              size: 64,
              color: ModernDesignSystem.primaryGreen,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            Text(
              'Şifre Sıfırlama',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              'E-posta adresinizi girin, şifre sıfırlama bağlantısı gönderelim.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.validateEmail,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingXL),
            Row(
              children: [
                Expanded(
                  child: EnhancedButton(
                    text: 'İptal',
                    type: ButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: ModernDesignSystem.spacingM),
                Expanded(
                  child: EnhancedButton(
                    text: 'Gönder',
                    onPressed: () => _handleForgotPassword(emailController.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword(String email) async {
    if (email.isEmpty) {
      EnhancedSnackbar.show(
        context,
        message: 'Lütfen e-posta adresinizi giriniz',
        type: SnackbarType.error,
      );
      return;
    }

    try {
      final result = await FirebaseBypassAuthService.resetPassword(email);
      
      if (result.isSuccess) {
        Navigator.of(context).pop();
        EnhancedSnackbar.show(
          context,
          message: 'Şifre sıfırlama e-postası gönderildi',
          type: SnackbarType.success,
        );
      } else {
        _showErrorDialog(result is Failure ? result.message : 'Şifre sıfırlama e-postası gönderilemedi');
      }
    } catch (e) {
      _showErrorDialog('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    EnhancedDialog.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ModernDesignSystem.error,
            ),
            SizedBox(height: ModernDesignSystem.spacingL),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ModernDesignSystem.spacingXL),
            EnhancedButton(
              text: 'Tamam',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

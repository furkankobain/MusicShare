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
import '../../../../core/utils/result.dart';

class EnhancedSignupPage extends ConsumerStatefulWidget {
  const EnhancedSignupPage({super.key});

  @override
  ConsumerState<EnhancedSignupPage> createState() => _EnhancedSignupPageState();
}

class _EnhancedSignupPageState extends ConsumerState<EnhancedSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _showPasswordRequirements = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: ModernDesignSystem.spacingXL),
                  
                  // Header
                  EnhancedAnimations.fadeIn(
                    child: _buildHeader(context, isDark),
                  ),
                  
                  SizedBox(height: ModernDesignSystem.spacingXXL),
                  
                  // Form
                  EnhancedAnimations.slideIn(
                    child: _buildForm(context, isDark),
                  ),
                  
                  SizedBox(height: ModernDesignSystem.spacingXL),
                  
                  // Social Login
                  EnhancedAnimations.fadeIn(
                    child: _buildSocialLogin(context, isDark),
                  ),
                  
                  SizedBox(height: ModernDesignSystem.spacingXL),
                  
                  // Login Link
                  EnhancedAnimations.fadeIn(
                    child: _buildLoginLink(context, isDark),
                  ),
                  
                  SizedBox(height: ModernDesignSystem.spacingXXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
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
            size: 40,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: ModernDesignSystem.spacingL),
        
        // Title
        Text(
          'Hesap Oluştur',
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeXXXL,
            fontWeight: FontWeight.bold,
            color: isDark ? ModernDesignSystem.textOnDark : ModernDesignSystem.textPrimary,
          ),
        ),
        
        SizedBox(height: ModernDesignSystem.spacingS),
        
        // Subtitle
        Text(
          'Müzik deneyiminize başlayın',
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
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
      padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email
            EnhancedEmailField(
              controller: _emailController,
              checkAvailability: true,
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Username
            EnhancedUsernameField(
              controller: _usernameController,
              checkAvailability: true,
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Password
            EnhancedPasswordField(
              controller: _passwordController,
              showStrengthIndicator: true,
              onChanged: () {
                setState(() {
                  _showPasswordRequirements = _passwordController.text.isNotEmpty;
                });
              },
            ),
            
            // Password Requirements
            if (_showPasswordRequirements) ...[
              SizedBox(height: ModernDesignSystem.spacingM),
              PasswordRequirements(password: _passwordController.text),
            ],
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Confirm Password
            EnhancedPasswordField(
              controller: _confirmPasswordController,
              labelText: 'Şifre Tekrarı',
              hintText: 'Şifrenizi tekrar giriniz',
              validator: (value) => AuthValidators.validateConfirmPassword(
                value, 
                _passwordController.text,
              ),
            ),
            
            SizedBox(height: ModernDesignSystem.spacingL),
            
            // Terms and Conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: ModernDesignSystem.primaryGreen,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeS,
                            color: isDark 
                                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.8)
                                : ModernDesignSystem.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Kabul ediyorum: '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/terms'),
                                child: Text(
                                  'Kullanım Şartları',
                                  style: TextStyle(
                                    color: ModernDesignSystem.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' ve '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/privacy'),
                                child: Text(
                                  'Gizlilik Politikası',
                                  style: TextStyle(
                                    color: ModernDesignSystem.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ModernDesignSystem.spacingXL),
            
            // Sign Up Button
            EnhancedButton(
              text: 'Hesap Oluştur',
              type: ButtonType.primary,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: _isLoading,
              onPressed: _acceptTerms ? _handleSignUp : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context, bool isDark) {
    return const SizedBox.shrink(); // Remove social login entirely
  }

  Widget _buildLoginLink(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı? ',
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeM,
            color: isDark 
                ? ModernDesignSystem.textOnDark.withValues(alpha: 0.7)
                : ModernDesignSystem.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Giriş Yap',
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

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showErrorDialog('Lütfen kullanım şartlarını kabul ediniz');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
        final result = await FirebaseBypassAuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        displayName: _usernameController.text.trim(),
      );

      if (result.isSuccess) {
        // Send email verification for new users
        await FirebaseBypassAuthService.sendEmailVerification();
        
        // Show success message with email verification info
        _showSuccessDialogWithEmailVerification();
        
        // Navigate to home page
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.go('/');
          }
        });
      } else {
        _showErrorDialog(result is Failure ? (result as Failure).message : 'Kayıt olurken bir hata oluştu');
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

  // Google and Apple Sign In methods removed

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı!'),
        content: const Text(
          'Hesabınız başarıyla oluşturuldu. E-posta adresinizi doğrulamak için gönderilen e-postayı kontrol edin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialogWithEmailVerification() {
    final currentUser = FirebaseBypassAuthService.currentUser;
    final verificationCode = currentUser?.emailVerificationCode ?? '123456';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt Başarılı!'),
        content: Text(
          'E-posta doğrulama kodu gönderildi!\n\nDoğrulama kodu: $verificationCode\n\n(Geliştirme modunda konsola da yazdırılmıştır)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

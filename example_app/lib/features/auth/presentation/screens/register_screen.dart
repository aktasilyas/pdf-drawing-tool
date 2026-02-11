/// Modern registration screen with responsive layout and design system.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/utils/validators.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/widgets/auth_branding_panel.dart';
import 'package:example_app/features/auth/presentation/widgets/auth_phone_header.dart';
import 'package:example_app/features/auth/presentation/widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor:
          isTablet ? AppColors.backgroundLight : AppColors.surfaceLight,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: Branding Panel (45%)
        const Expanded(
          flex: 45,
          child: AuthBrandingPanel(),
        ),
        // Right: Form Panel (55%)
        Expanded(
          flex: 55,
          child: Container(
            color: AppColors.surfaceLight,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Top Logo
            const AuthPhoneHeader(),
            const SizedBox(height: AppSpacing.xxl),
            // Form
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Kayıt Ol',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yeni hesap oluştur',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Display Name Field
          AppTextField(
            controller: _displayNameController,
            label: 'Ad Soyad',
            hint: 'Adınız ve soyadınız',
            prefixIcon: Icons.person_outlined,
            validator: Validators.displayName,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email Field
          AppTextField(
            controller: _emailController,
            label: 'E-posta',
            hint: 'ornek@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Password Field
          AppPasswordField(
            controller: _passwordController,
            label: 'Şifre',
            hint: 'En az 6 karakter',
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Confirm Password Field
          AppPasswordField(
            controller: _confirmPasswordController,
            label: 'Şifre Tekrar',
            hint: 'Şifrenizi tekrar girin',
            validator: Validators.confirmPassword(_passwordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Register Button
          AppButton(
            label: 'Kayıt Ol',
            onPressed: _isLoading ? null : _handleRegister,
            isLoading: _isLoading,
            isExpanded: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Dev Skip Button (only in dev mode)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            AppButton(
              label: 'Atla (Geliştirme)',
              variant: AppButtonVariant.outline,
              onPressed: _skipRegister,
              isExpanded: true,
            ),
          const SizedBox(height: AppSpacing.xl),

          // Divider with "veya"
          Row(
            children: [
              const Expanded(child: AppDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'veya',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const Expanded(child: AppDivider()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Google Sign-In Button
          GoogleSignInButton(
            onPressed: _isLoading ? null : _handleGoogleRegister,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Terms Text
          Text(
            'Hesap oluşturarak Kullanım Koşullarını ve Gizlilik Politikasını kabul etmiş olursunuz',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Login Link
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zaten hesabın var mı? ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _goToLogin,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Giriş Yap',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      AppToast.error(context, 'Şifreler eşleşmiyor');
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _displayNameController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        AppToast.error(context, error);
      }
    } else {
      if (mounted) {
        _showSuccessModal();
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isLoading = true);

    final error =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        AppToast.error(context, error);
      }
    } else {
      if (mounted) {
        context.go(RouteNames.documents);
      }
    }
  }

  void _goToLogin() {
    context.go(RouteNames.login);
  }

  void _skipRegister() {
    debugPrint('🚀 [DEV] Skipping register - going to documents');
    context.go(RouteNames.documents);
  }

  Future<void> _showSuccessModal() async {
    await AppModal.show(
      context: context,
      title: 'Kayıt Başarılı!',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: AppIconSize.huge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'E-posta adresinize doğrulama bağlantısı gönderdik. '
            'Lütfen e-postanızı kontrol edin ve hesabınızı doğrulayın.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Giriş Ekranına Dön',
          onPressed: () {
            Navigator.pop(context);
            context.go(RouteNames.login);
          },
        ),
      ],
      isDismissible: false,
    );
  }
}

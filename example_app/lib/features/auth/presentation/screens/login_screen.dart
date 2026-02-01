/// Modern login screen with responsive layout and design system.
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

const Key loginEmailFieldKey = Key('login_email_field');
const Key loginPasswordFieldKey = Key('login_password_field');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            'Giriş Yap',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hesabınıza giriş yapın',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

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
            hint: '••••••••',
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.sm,
                ),
              ),
              child: Text(
                'Şifremi Unuttum',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Login Button
          AppButton(
            label: 'Giriş Yap',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            isExpanded: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Dev Skip Button (only in dev mode)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            AppButton(
              label: 'Atla (Geliştirme)',
              variant: AppButtonVariant.outline,
              onPressed: _skipLogin,
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
            onPressed: _isLoading ? null : _handleGoogleLogin,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Sign Up Link
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hesabın yok mu? ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _goToRegister,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Kayıt Ol',
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

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

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

  Future<void> _handleGoogleLogin() async {
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

  void _goToRegister() {
    context.go(RouteNames.register);
  }

  void _skipLogin() {
    debugPrint('🚀 [DEV] Skipping login - going to documents');
    context.go(RouteNames.documents);
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);

    await AppModal.show<bool>(
      context: context,
      title: 'Şifre Sıfırlama',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: emailController,
            label: 'E-posta',
            hint: 'ornek@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'İptal',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppButton(
          label: 'Gönder',
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              AppToast.error(context, 'Geçerli bir e-posta girin');
              return;
            }

            final error = await ref
                .read(authControllerProvider.notifier)
                .resetPassword(email);

            if (mounted) {
              Navigator.pop(context, true);
              if (error != null) {
                AppToast.error(context, error);
              } else {
                AppToast.success(
                    context, 'Şifre sıfırlama e-postası gönderildi');
              }
            }
          },
        ),
      ],
    );

    emailController.dispose();
  }
}

/// Simplified login screen with centered logo and form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/core/utils/validators.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/constants/auth_strings.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildContent(textColor, textSecondary),
                ),
              ),
            ),
          ),
          if (const bool.fromEnvironment('dart.vm.product') == false)
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: SafeArea(
                child: TextButton(
                  onPressed: _skipLogin,
                  child: Text(
                    AuthStrings.devSkip,
                    style: AppTypography.labelMedium.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor, Color textSecondary) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/elyanotes_logo_transparent_logo.png',
            width: 120,
            height: 120,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.edit_note_rounded,
              size: 120,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'elyanotes',
            style: TextStyle(
              fontFamily: 'ComicRelief',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _emailController,
            label: AuthStrings.emailLabel,
            hint: AuthStrings.emailHint,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPasswordField(
            controller: _passwordController,
            label: AuthStrings.passwordLabel,
            hint: '••••••••',
            validator: Validators.password,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xs),
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
                AuthStrings.forgotPassword,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: AuthStrings.signInTitle,
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            isExpanded: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(child: AppDivider()),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  AuthStrings.orDivider,
                  style: AppTypography.labelMedium.copyWith(
                    color: textSecondary,
                  ),
                ),
              ),
              const Expanded(child: AppDivider()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GoogleSignInButton(
            onPressed: _isLoading ? null : _handleGoogleLogin,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AuthStrings.noAccount,
                style:
                    AppTypography.bodyMedium.copyWith(color: textSecondary),
              ),
              TextButton(
                onPressed: _isLoading ? null : _goToRegister,
                child: Text(
                  AuthStrings.signUp,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final error = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) AppToast.error(context, error);
    } else {
      if (mounted) context.go(RouteNames.documents);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final error =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) AppToast.error(context, error);
    } else {
      if (mounted) context.go(RouteNames.documents);
    }
  }

  void _goToRegister() => context.go(RouteNames.register);

  void _skipLogin() {
    logger.d('[DEV] Skipping login - going to documents');
    context.go(RouteNames.documents);
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);

    await AppModal.show<bool>(
      context: context,
      title: AuthStrings.resetPasswordTitle,
      content: _ForgotPasswordContent(emailController: emailController),
      actions: [
        AppButton(
          label: AuthStrings.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppButton(
          label: AuthStrings.send,
          onPressed: () async {
            final email = emailController.text.trim();
            if (Validators.email(email) != null) {
              AppToast.error(context, AuthStrings.enterValidEmail);
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
                AppToast.success(context, AuthStrings.resetEmailSent);
              }
            }
          },
        ),
      ],
    );

    emailController.dispose();
  }
}

class _ForgotPasswordContent extends StatelessWidget {
  final TextEditingController emailController;

  const _ForgotPasswordContent({required this.emailController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AuthStrings.resetPasswordDescription,
          style: AppTypography.bodyMedium.copyWith(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: emailController,
          label: AuthStrings.emailLabel,
          hint: AuthStrings.emailHint,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
      ],
    );
  }
}

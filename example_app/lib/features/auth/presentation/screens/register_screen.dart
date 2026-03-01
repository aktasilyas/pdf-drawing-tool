/// Modern registration screen with responsive layout and design system.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/utils/validators.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/constants/auth_strings.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: isTablet ? bgColor : surfaceColor,
      body: isTablet ? _buildTabletLayout(surfaceColor) : _buildPhoneLayout(),
    );
  }

  Widget _buildTabletLayout(Color surfaceColor) {
    return Row(
      children: [
        const Expanded(flex: 45, child: AuthBrandingPanel()),
        Expanded(
          flex: 55,
          child: Container(
            color: surfaceColor,
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
            const AuthPhoneHeader(),
            const SizedBox(height: AppSpacing.xxl),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AuthStrings.signUpTitle,
            style: AppTypography.headlineLarge.copyWith(color: textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AuthStrings.signUpSubtitle,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _displayNameController,
            label: AuthStrings.displayNameLabel,
            hint: AuthStrings.displayNameHint,
            prefixIcon: Icons.person_outlined,
            textInputAction: TextInputAction.next,
            validator: Validators.displayName,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.lg),
          AppPasswordField(
            controller: _passwordController,
            label: AuthStrings.passwordLabel,
            hint: AuthStrings.passwordHint,
            validator: Validators.password,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPasswordField(
            controller: _confirmPasswordController,
            label: AuthStrings.confirmPasswordLabel,
            hint: AuthStrings.confirmPasswordHint,
            validator: (value) =>
                Validators.confirmPassword(_passwordController.text)(value),
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: AuthStrings.signUpTitle,
            onPressed: _isLoading ? null : _handleRegister,
            isLoading: _isLoading,
            isExpanded: true,
          ),
          const SizedBox(height: AppSpacing.md),
          if (const bool.fromEnvironment('dart.vm.product') == false)
            AppButton(
              label: AuthStrings.devSkip,
              variant: AppButtonVariant.outline,
              onPressed: _skipRegister,
              isExpanded: true,
            ),
          const SizedBox(height: AppSpacing.xl),
          _buildOrDivider(textSecondary),
          const SizedBox(height: AppSpacing.xl),
          GoogleSignInButton(
            onPressed: _isLoading ? null : _handleGoogleRegister,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AuthStrings.termsText,
            style: AppTypography.caption.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildLoginLink(textSecondary),
        ],
      ),
    );
  }

  Widget _buildOrDivider(Color textSecondary) {
    return Row(
      children: [
        const Expanded(child: AppDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AuthStrings.orDivider,
            style: AppTypography.labelMedium.copyWith(color: textSecondary),
          ),
        ),
        const Expanded(child: AppDivider()),
      ],
    );
  }

  Widget _buildLoginLink(Color textSecondary) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AuthStrings.alreadyHaveAccount,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
          ),
          TextButton(
            onPressed: _isLoading ? null : _goToLogin,
            child: Text(
              AuthStrings.signIn,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
      if (mounted) AppToast.error(context, error);
    } else {
      if (mounted) _showSuccessModal();
    }
  }

  Future<void> _handleGoogleRegister() async {
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

  void _goToLogin() => context.go(RouteNames.login);

  void _skipRegister() {
    logger.d('[DEV] Skipping register - going to documents');
    context.go(RouteNames.documents);
  }

  Future<void> _showSuccessModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    await AppModal.show(
      context: context,
      title: AuthStrings.registrationSuccess,
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
            AuthStrings.verificationMessage,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        AppButton(
          label: AuthStrings.backToLogin,
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

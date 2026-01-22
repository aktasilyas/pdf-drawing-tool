/// Login screen for email/password and social auth.
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/presentation/constants/auth_strings.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AuthStrings.signInTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  key: loginEmailFieldKey,
                  decoration:
                      const InputDecoration(labelText: AuthStrings.emailLabel),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  key: loginPasswordFieldKey,
                  decoration: const InputDecoration(
                    labelText: AuthStrings.passwordLabel,
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 20),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: state.isLoading ? null : _handleLogin,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AuthStrings.signInButton),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: state.isLoading ? null : _goToRegister,
                  child: const Text(AuthStrings.createAccount),
                ),
                const SizedBox(height: 24),
                SocialLoginButtons(
                  isLoading: state.isLoading,
                  onGooglePressed: _handleGoogleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final result = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    result.fold(
      (_) => null,
      (_) => context.go(RouteNames.documents),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final result =
        await ref.read(authControllerProvider.notifier).loginWithGoogle();
    result.fold(
      (_) => null,
      (_) => context.go(RouteNames.documents),
    );
  }

  void _goToRegister() {
    context.go(RouteNames.register);
  }
}

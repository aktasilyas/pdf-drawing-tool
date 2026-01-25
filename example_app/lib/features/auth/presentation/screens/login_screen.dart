/// Modern login screen with Supabase auth.
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/widgets/auth_layout.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Hoş Geldiniz',
      subtitle: 'Hesabınıza giriş yapın ve notlarınıza erişin',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            ModernTextField(
              fieldKey: loginEmailFieldKey,
              controller: _emailController,
              label: 'E-posta',
              hint: 'ornek@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),

            // Password field
            ModernTextField(
              fieldKey: loginPasswordFieldKey,
              controller: _passwordController,
              label: 'Şifre',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: const Text(
                  'Şifremi Unuttum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Login button
            ModernButton(
              onPressed: _handleLogin,
              text: 'Giriş Yap',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),

            // Dev skip button
            ModernButton(
              onPressed: _skipLogin,
              text: 'Atla (Geliştirme)',
              isOutlined: true,
            ),
            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'veya',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 24),

            // Social login buttons
            _SocialLoginButton(
              icon: Icons.g_mobiledata,
              label: 'Google ile Giriş Yap',
              onPressed: _isLoading ? null : _handleGoogleLogin,
            ),
            const SizedBox(height: 32),

            // Sign up link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hesabınız yok mu? ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _goToRegister,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        _showErrorSnackBar(error);
      }
    } else {
      if (mounted) {
        context.go(RouteNames.documents);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final error = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        _showErrorSnackBar(error);
      }
    } else {
      // Success - navigate to documents
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir e-posta girin')),
                );
                return;
              }

              final error = await ref
                  .read(authControllerProvider.notifier)
                  .resetPassword(email);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'Şifre sıfırlama e-postası gönderildi',
                    ),
                    backgroundColor: error != null ? Colors.red : Colors.green,
                  ),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

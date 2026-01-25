/// Modern registration screen with Supabase auth.
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Hesap Oluştur',
      subtitle: 'Yeni bir hesap oluşturun ve notlarınızı paylaşın',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display Name field
            ModernTextField(
              controller: _displayNameController,
              label: 'Ad Soyad',
              hint: 'Adınız ve soyadınız',
              icon: Icons.person_outline,
              validator: Validators.displayName,
            ),
            const SizedBox(height: 16),

            // Email field
            ModernTextField(
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
              controller: _passwordController,
              label: 'Şifre',
              hint: 'En az 6 karakter',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 10),

            // Password requirements
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Şifreniz en az 6 karakter olmalıdır',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Register button
            ModernButton(
              onPressed: _handleRegister,
              text: 'Hesap Oluştur',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),

            // Dev skip button
            ModernButton(
              onPressed: _skipRegister,
              text: 'Atla (Geliştirme)',
              isOutlined: true,
            ),
            const SizedBox(height: 24),

            // Terms and privacy
            Text(
              'Hesap oluşturarak Kullanım Koşullarını ve Gizlilik Politikasını kabul etmiş olursunuz',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Login link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zaten hesabınız var mı? ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _goToLogin,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Giriş Yap',
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

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
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
        _showErrorSnackBar(error);
      }
    } else {
      if (mounted) {
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Kayıt Başarılı!'),
          ],
        ),
        content: const Text(
          'E-posta adresinize doğrulama bağlantısı gönderdik. '
          'Lütfen e-postanızı kontrol edin ve hesabınızı doğrulayın.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.login);
            },
            child: const Text('Giriş Ekranına Dön'),
          ),
        ],
      ),
    );
  }
}

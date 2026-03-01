/// Simplified Riverpod auth providers for Supabase.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:example_app/core/utils/logger.dart';

// Current auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

// Current session
final sessionProvider = Provider<Session?>((ref) {
  return Supabase.instance.client.auth.currentSession;
});

// Auth controller for sign in/up/out
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncValue.data(null));

  final _supabase = Supabase.instance.client;

  /// Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      state = const AsyncValue.data(null);

      if (response.user == null) {
        return 'Kayıt başarısız';
      }

      logger.i('Sign up successful: ${response.user?.email}');
      return null; // Success
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Sign up error: ${e.message}');
      return _friendlyErrorMessage(e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Sign up error: $e');
      return e.toString();
    }
  }

  /// Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      state = const AsyncValue.data(null);

      if (response.user == null) {
        return 'Giriş başarısız';
      }

      logger.i('Sign in successful: ${response.user?.email}');
      return null; // Success
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Sign in error: ${e.message}');
      return _friendlyErrorMessage(e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Sign in error: $e');
      return e.toString();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signOut();
      state = const AsyncValue.data(null);
      logger.i('Sign out successful');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Sign out error: $e');
    }
  }

  /// Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      logger.i('Password reset email sent to: $email');
      return null; // Success
    } on AuthException catch (e) {
      logger.e('Reset password error: ${e.message}');
      return _friendlyErrorMessage(e.message);
    } catch (e) {
      logger.e('Reset password error: $e');
      return e.toString();
    }
  }

  /// Google sign in with native Google Sign-In
  Future<String?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '129947293915-lrn645esmtn61bv1icstcimhtr2rorv8.apps.googleusercontent.com',
      );

      logger.d('[GOOGLE] Starting sign in flow...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null);
        logger.w('Google sign in cancelled by user');
        return 'Google girişi iptal edildi';
      }

      logger.d('[GOOGLE] User selected: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      logger.d('[GOOGLE] idToken: ${idToken != null ? "exists" : "NULL"}');
      logger.d(
          '[GOOGLE] accessToken: ${accessToken != null ? "exists" : "NULL"}');

      if (idToken == null) {
        state = const AsyncValue.data(null);
        logger.e('[GOOGLE] idToken is null - possible causes: '
            'Web OAuth Client ID missing, SHA-1 mismatch, '
            'user not in test users list');
        return 'Google token alınamadı';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      state = const AsyncValue.data(null);

      if (response.user == null) {
        logger.e('Supabase user is null after Google sign in');
        return 'Google girişi başarısız';
      }

      logger.i('Google sign in successful: ${response.user?.email}');
      return null; // Success
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Google sign in error (AuthException): ${e.message}');
      return _friendlyErrorMessage(e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.e('Google sign in error: $e');
      return e.toString();
    }
  }

  /// Convert technical error messages to user-friendly Turkish
  String _friendlyErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid credentials')) {
      return 'E-posta veya şifre hatalı';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'E-posta adresinizi doğrulamanız gerekiyor';
    }
    if (lowerMessage.contains('user already registered') ||
        lowerMessage.contains('already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı';
    }
    if (lowerMessage.contains('invalid email')) {
      return 'Geçersiz e-posta adresi';
    }
    if (lowerMessage.contains('password') && lowerMessage.contains('short')) {
      return 'Şifre çok kısa (en az 6 karakter)';
    }

    return message; // Fallback to original
  }
}

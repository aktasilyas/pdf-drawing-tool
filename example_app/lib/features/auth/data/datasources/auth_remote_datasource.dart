/// Remote datasource for Supabase auth operations.
library;

import 'package:example_app/core/core.dart' as core;
import 'package:example_app/features/auth/data/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> loginWithGoogle();

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> watchAuthState();

  Future<void> sendPasswordReset(String email);

  Future<bool> isEmailRegistered(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
  })  : _client = client ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const core.AuthException('Oturum açma başarısız');
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const core.AuthException('Google giriş işlemi iptal edildi');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const core.AuthException('Google kimlik doğrulaması başarısız');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      final user = response.user;
      if (user == null) {
        throw const core.AuthException('Google ile giriş başarısız');
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const core.AuthException('Kayıt işlemi başarısız');
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return null;
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Stream<UserModel?> watchAuthState() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) {
        return null;
      }
      return UserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (error) {
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return true;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('not found') || message.contains('user')) {
        return false;
      }
      throw core.AuthException(
        error.message,
        code: error.statusCode?.toString(),
        originalError: error,
      );
    } catch (error) {
      throw core.AuthException(error.toString(), originalError: error);
    }
  }
}

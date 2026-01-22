/// Failure classes for error handling with Either pattern.
/// 
/// Usage:
/// ```dart
/// Future<Either<Failure, User>> login() async {
///   try {
///     final user = await api.login();
///     return Right(user);
///   } on ServerException catch (e) {
///     return Left(ServerFailure(e.message));
///   }
/// }
/// ```
library;

import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/API related failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Sunucu hatası oluştu']) : super(message);
}

/// Local cache/database failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Yerel veri hatası']) : super(message);
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'İnternet bağlantısı yok']) : super(message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
  
  factory AuthFailure.invalidCredentials() => 
      const AuthFailure('E-posta veya şifre hatalı', code: 'invalid_credentials');
  
  factory AuthFailure.emailInUse() => 
      const AuthFailure('Bu e-posta zaten kullanımda', code: 'email_in_use');
  
  factory AuthFailure.weakPassword() => 
      const AuthFailure('Şifre çok zayıf', code: 'weak_password');
  
  factory AuthFailure.userNotFound() => 
      const AuthFailure('Kullanıcı bulunamadı', code: 'user_not_found');
  
  factory AuthFailure.sessionExpired() => 
      const AuthFailure('Oturum süresi doldu', code: 'session_expired');
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
  
  factory ValidationFailure.emptyField(String fieldName) => 
      ValidationFailure('$fieldName boş olamaz');
  
  factory ValidationFailure.invalidEmail() => 
      const ValidationFailure('Geçersiz e-posta adresi');
  
  factory ValidationFailure.passwordTooShort() => 
      const ValidationFailure('Şifre en az 6 karakter olmalı');
}

/// Premium/subscription failures
class PremiumFailure extends Failure {
  const PremiumFailure(super.message, {super.code});
  
  factory PremiumFailure.required(String feature) => 
      PremiumFailure('$feature için Premium gerekli', code: 'premium_required');
  
  factory PremiumFailure.limitExceeded(String limit) => 
      PremiumFailure('$limit sınırına ulaştınız', code: 'limit_exceeded');
  
  factory PremiumFailure.purchaseFailed() => 
      const PremiumFailure('Satın alma başarısız', code: 'purchase_failed');
}

/// Sync failures
class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});
  
  factory SyncFailure.conflict() => 
      const SyncFailure('Senkronizasyon çakışması', code: 'conflict');
  
  factory SyncFailure.offline() => 
      const SyncFailure('Çevrimdışı - senkronizasyon bekliyor', code: 'offline');
}

/// Document operation failures
class DocumentFailure extends Failure {
  const DocumentFailure(super.message, {super.code});
  
  factory DocumentFailure.notFound() => 
      const DocumentFailure('Belge bulunamadı', code: 'not_found');
  
  factory DocumentFailure.accessDenied() => 
      const DocumentFailure('Bu belgeye erişim izniniz yok', code: 'access_denied');
  
  factory DocumentFailure.corrupted() => 
      const DocumentFailure('Belge hasarlı', code: 'corrupted');
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Beklenmeyen bir hata oluştu']) : super(message);
}

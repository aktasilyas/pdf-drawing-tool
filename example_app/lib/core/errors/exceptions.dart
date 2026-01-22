/// Exception classes for throwing errors in data layer.
/// 
/// Exceptions are thrown in data layer and caught in repository,
/// then converted to Failure objects.
/// 
/// Usage:
/// ```dart
/// Future<UserModel> login() async {
///   final response = await client.post('/login');
///   if (response.statusCode != 200) {
///     throw ServerException(response.body);
///   }
///   return UserModel.fromJson(response.data);
/// }
/// ```
library;

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server/API exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    final defaultMessage = switch (statusCode) {
      400 => 'Geçersiz istek',
      401 => 'Yetkilendirme hatası',
      403 => 'Erişim reddedildi',
      404 => 'Bulunamadı',
      500 => 'Sunucu hatası',
      503 => 'Servis kullanılamıyor',
      _ => 'Bilinmeyen hata',
    };

    return ServerException(
      message ?? defaultMessage,
      statusCode: statusCode,
    );
  }
}

/// Local cache/database exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError});

  factory CacheException.notFound([String? key]) =>
      CacheException('Cache bulunamadı${key != null ? ': $key' : ''}', code: 'not_found');

  factory CacheException.writeError([String? message]) =>
      CacheException(message ?? 'Cache yazma hatası', code: 'write_error');

  factory CacheException.readError([String? message]) =>
      CacheException(message ?? 'Cache okuma hatası', code: 'read_error');
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});

  factory NetworkException.noConnection() =>
      const NetworkException('İnternet bağlantısı yok', code: 'no_connection');

  factory NetworkException.timeout() =>
      const NetworkException('Bağlantı zaman aşımı', code: 'timeout');
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  factory AuthException.invalidCredentials() =>
      const AuthException('E-posta veya şifre hatalı', code: 'invalid_credentials');

  factory AuthException.emailInUse() =>
      const AuthException('Bu e-posta zaten kullanımda', code: 'email_in_use');

  factory AuthException.weakPassword() =>
      const AuthException('Şifre çok zayıf', code: 'weak_password');

  factory AuthException.userNotFound() =>
      const AuthException('Kullanıcı bulunamadı', code: 'user_not_found');

  factory AuthException.notAuthenticated() =>
      const AuthException('Oturum açılmamış', code: 'not_authenticated');
}

/// Parse/serialization exceptions
class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});

  factory ParseException.invalidJson([String? details]) =>
      ParseException('Geçersiz JSON${details != null ? ': $details' : ''}', code: 'invalid_json');

  factory ParseException.missingField(String fieldName) =>
      ParseException('Eksik alan: $fieldName', code: 'missing_field');
}

/// Document exceptions
class DocumentException extends AppException {
  const DocumentException(super.message, {super.code, super.originalError});

  factory DocumentException.notFound(String id) =>
      DocumentException('Belge bulunamadı: $id', code: 'not_found');

  factory DocumentException.corrupted(String id) =>
      DocumentException('Belge hasarlı: $id', code: 'corrupted');
}

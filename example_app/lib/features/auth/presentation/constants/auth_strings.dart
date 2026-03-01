/// String constants for the auth feature UI.
library;

abstract class AuthStrings {
  // Login
  static const String signInTitle = 'Giriş Yap';
  static const String signInSubtitle = 'Hesabınıza giriş yapın';
  static const String forgotPassword = 'Şifremi Unuttum';
  static const String noAccount = 'Hesabın yok mu? ';
  static const String signUp = 'Kayıt Ol';
  static const String orDivider = 'veya';
  static const String googleSignIn = 'Google ile Giriş Yap';
  static const String devSkip = 'Atla (Geliştirme)';

  // Register
  static const String signUpTitle = 'Kayıt Ol';
  static const String signUpSubtitle = 'Yeni hesap oluştur';
  static const String displayNameLabel = 'Ad Soyad';
  static const String displayNameHint = 'Adınız ve soyadınız';
  static const String confirmPasswordLabel = 'Şifre Tekrar';
  static const String confirmPasswordHint = 'Şifrenizi tekrar girin';
  static const String passwordHint = 'En az 6 karakter';
  static const String termsText =
      'Hesap oluşturarak Kullanım Koşullarını ve Gizlilik Politikasını kabul etmiş olursunuz';
  static const String alreadyHaveAccount = 'Zaten hesabın var mı? ';
  static const String signIn = 'Giriş Yap';

  // Success modal
  static const String registrationSuccess = 'Kayıt Başarılı!';
  static const String verificationMessage =
      'E-posta adresinize doğrulama bağlantısı gönderdik. '
      'Lütfen e-postanızı kontrol edin ve hesabınızı doğrulayın.';
  static const String backToLogin = 'Giriş Ekranına Dön';

  // Forgot password
  static const String resetPasswordTitle = 'Şifre Sıfırlama';
  static const String resetPasswordDescription =
      'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.';
  static const String send = 'Gönder';
  static const String cancel = 'İptal';
  static const String resetEmailSent =
      'Şifre sıfırlama e-postası gönderildi';
  static const String enterValidEmail = 'Geçerli bir e-posta girin';

  // Common
  static const String emailLabel = 'E-posta';
  static const String emailHint = 'ornek@email.com';
  static const String passwordLabel = 'Şifre';
}

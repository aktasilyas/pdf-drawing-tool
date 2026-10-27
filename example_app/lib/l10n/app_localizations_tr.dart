// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonConfirm => 'Onayla';

  @override
  String get commonCreate => 'Oluştur';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonDone => 'Bitti';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonRename => 'Yeniden Adlandır';

  @override
  String get commonMove => 'Taşı';

  @override
  String get commonDuplicate => 'Çoğalt';

  @override
  String get commonRestore => 'Kurtar';

  @override
  String get commonMenu => 'Menü';

  @override
  String commonErrorDetail(String error) {
    return 'Hata: $error';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSectionAppearance => 'GÖRÜNÜM';

  @override
  String get settingsSectionAccount => 'HESAP';

  @override
  String get settingsSectionPrivacy => 'GİZLİLİK';

  @override
  String get settingsSectionAbout => 'HAKKINDA';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeDialogTitle => 'Tema Seçin';

  @override
  String get settingsCanvasTheme => 'Canvas Teması';

  @override
  String get settingsPinFavorites => 'Favorileri üste sabitle';

  @override
  String get settingsChangePassword => 'Şifre değiştir';

  @override
  String get settingsChangePasswordSoon => 'Şifre değiştirme özelliği yakında';

  @override
  String get settingsAccountInfo => 'Hesap bilgileri';

  @override
  String get settingsAccountInfoTitle => 'Hesap Bilgileri';

  @override
  String settingsAccountEmail(String email) {
    return 'Email: $email';
  }

  @override
  String settingsAccountId(String id) {
    return 'ID: $id';
  }

  @override
  String get settingsUserFallbackName => 'Kullanıcı';

  @override
  String get settingsEditName => 'İsim Düzenle';

  @override
  String get settingsEditNameHint => 'Adı düzenle';

  @override
  String get settingsNameLabel => 'Adınız';

  @override
  String get settingsLogout => 'Çıkış Yap';

  @override
  String get settingsLogoutConfirm =>
      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';

  @override
  String get settingsCrashReports => 'Çökme raporlarını gönder';

  @override
  String get settingsCrashReportsSubtitle =>
      'Anonim hata raporları; not içeriği gönderilmez';

  @override
  String get settingsVersion => 'Sürüm';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get settingsPrivacyPolicyLoadError => 'Gizlilik politikası açılamadı';

  @override
  String get settingsLicenses => 'Açık kaynak lisansları';

  @override
  String get settingsFeedback => 'Geri bildirim gönder';

  @override
  String get settingsCopy => 'Kopyala';

  @override
  String get settingsEmailCopied => 'E-posta adresi kopyalandı';
}

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

  @override
  String get libraryErrorCreateDocument => 'Belge oluşturulamadı';

  @override
  String get libraryErrorImportDocument => 'Belge içe aktarılamadı';

  @override
  String get libraryErrorMoveDocument => 'Belge taşınamadı';

  @override
  String get libraryErrorToggleFavorite => 'Favori durumu değiştirilemedi';

  @override
  String get libraryErrorTrashDocument => 'Belge çöpe taşınamadı';

  @override
  String get libraryErrorDeleteDocument => 'Belge silinemedi';

  @override
  String get libraryErrorRenameDocument => 'Belge adı değiştirilemedi';

  @override
  String get libraryErrorRestoreDocument => 'Belge geri yüklenemedi';

  @override
  String get libraryErrorDuplicateDocument => 'Belge çoğaltılamadı';

  @override
  String get libraryErrorDeleteDocumentForever =>
      'Belge kalıcı olarak silinemedi';

  @override
  String get libraryErrorTrashDocuments => 'Belgeler çöpe taşınamadı';

  @override
  String get libraryErrorDeleteDocumentsForever =>
      'Belgeler kalıcı olarak silinemedi';

  @override
  String get libraryErrorDuplicateDocuments => 'Belgeler çoğaltılamadı';

  @override
  String get libraryErrorMoveDocuments => 'Belgeler taşınamadı';

  @override
  String get libraryErrorTrashPage => 'Sayfa çöpe taşınamadı';

  @override
  String get libraryErrorDeletePageForever => 'Sayfa kalıcı olarak silinemedi';

  @override
  String get libraryErrorEmptyTrash => 'Çöp kutusu boşaltılamadı';

  @override
  String get libraryErrorCreateFolder => 'Klasör oluşturulamadı';

  @override
  String get libraryErrorRenameFolder => 'Klasör adı değiştirilemedi';

  @override
  String get libraryErrorRecolorFolder => 'Klasör rengi değiştirilemedi';

  @override
  String get libraryErrorSaveFolderOrder => 'Sıralama kaydedilemedi';

  @override
  String get libraryErrorMoveFolder => 'Klasör taşınamadı';

  @override
  String get libraryErrorDeleteFolder => 'Klasör silinemedi';

  @override
  String get libraryRuleFolderDepth =>
      'Alt klasörlerin altına klasör oluşturulamaz';

  @override
  String get libraryRuleFolderIntoOwnSubfolder =>
      'Klasör kendi alt klasörüne taşınamaz';

  @override
  String get libraryRuleFolderMoveDepth =>
      'Alt klasörlerin altına klasör taşınamaz';

  @override
  String get libraryRuleFolderWithSubfoldersMove =>
      'Alt klasörleri olan bir klasör başka klasörün altına taşınamaz';

  @override
  String get libraryRuleDocumentLimit =>
      'Ücretsiz sınıra ulaştınız. Premium\'a geçin.';

  @override
  String get libraryRuleFolderLimit =>
      'Klasör sınırına ulaştınız. Premium\'a geçin.';

  @override
  String get librarySortByDate => 'Tarihe göre';

  @override
  String get librarySortByName => 'İsme göre';

  @override
  String get librarySortBySize => 'Boyuta göre';

  @override
  String get librarySectionAll => 'Tüm Notlar';

  @override
  String get librarySectionFavorites => 'Favoriler';

  @override
  String get librarySectionTrash => 'Son Silinenler';

  @override
  String get libraryFolderFallback => 'Klasör';

  @override
  String get libraryPaperSquare => 'Kare';

  @override
  String get libraryPaperWide => 'Geniş';

  @override
  String get libraryPaperCustom => 'Özel';
}

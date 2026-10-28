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

  @override
  String get libraryBreadcrumbRoot => 'Belgelerim';

  @override
  String get libraryFolders => 'Klasörler';

  @override
  String get libraryDocuments => 'Belgeler';

  @override
  String get libraryManage => 'Yönet';

  @override
  String get libraryNewFolder => 'Yeni Klasör';

  @override
  String get libraryNoFolders => 'Klasör yok';

  @override
  String get librarySidebarCollapse => 'Daralt';

  @override
  String get libraryOpenSidebar => 'Kenar çubuğunu aç';

  @override
  String get librarySearchHint => 'Ara...';

  @override
  String get libraryListView => 'Liste görünümü';

  @override
  String get libraryGridView => 'Grid görünümü';

  @override
  String get librarySelectMode => 'Seçim modu';

  @override
  String get libraryNewDocument => 'Yeni Belge';

  @override
  String get libraryNewDocumentLocked => 'Belge limiti doldu';

  @override
  String get libraryNew => 'Yeni';

  @override
  String get libraryTrashInfo =>
      'Silinen notlar 30 gün sonra kalıcı olarak silinir';

  @override
  String get libraryEmptyTrash => 'Çöpü Boşalt';

  @override
  String get libraryEmptyTrashConfirmMessage =>
      'Çöp kutusundaki tüm belgeler ve sayfalar kalıcı olarak silinecek. Bu işlem geri alınamaz!';

  @override
  String get libraryEmptyTrashConfirm => 'Boşalt';

  @override
  String get libraryTrashEmptied => 'Çöp kutusu boşaltıldı';

  @override
  String get libraryOpenFailed => 'Belge açılamadı';

  @override
  String get libraryTrashCountsTowardsLimit =>
      'Çöp kutusundaki belgeler limite dahildir. Yer açmak için kalıcı olarak silin veya';

  @override
  String libraryRemainingDocuments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge hakkınız kaldı',
    );
    return '$_temp0';
  }

  @override
  String get librarySortTitle => 'Sıralama';

  @override
  String get librarySortNewestFirst => 'Yeniden eskiye';

  @override
  String get librarySortOldestFirst => 'Eskiden yeniye';

  @override
  String get libraryEmptyTitle => 'Henüz not yok';

  @override
  String get libraryEmptyMessage =>
      'Yeni bir defter oluşturun ya da bir PDF içe aktarın.';

  @override
  String get libraryEmptyAction => 'Yeni not';

  @override
  String get libraryEmptyFavoritesTitle => 'Favori not yok';

  @override
  String get libraryEmptyFavoritesMessage =>
      'Notlarınızı favorilere eklemek için yıldız ikonuna tıklayın';

  @override
  String get libraryEmptyFolderTitle => 'Bu klasör boş';

  @override
  String get libraryEmptyFolderMessage =>
      'Notlarınızı buraya taşıyın veya yeni not oluşturun';

  @override
  String get libraryTrashEmptyTitle => 'Çöp kutusu boş';

  @override
  String get libraryTrashEmptyMessage => 'Silinen notlar burada görünecek';

  @override
  String get libraryNoResultsTitle => 'Sonuç bulunamadı';

  @override
  String libraryNoResultsMessage(String query) {
    return '\"$query\" için eşleşen not bulunamadı';
  }

  @override
  String get libraryClearSearch => 'Aramayı temizle';

  @override
  String librarySelectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get librarySelectAll => 'Tümü';

  @override
  String get libraryDeleteForever => 'Kalıcı Sil';

  @override
  String get libraryDeleteForeverTitle => 'Kalıcı Olarak Sil';

  @override
  String get libraryDeleteDocumentsTitle => 'Belgeleri Sil';

  @override
  String get libraryDocumentLimitReached => 'Belge Limitine Ulaştınız';

  @override
  String libraryDocumentsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentsTrashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge çöpe taşındı',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge silindi',
    );
    return '$_temp0';
  }

  @override
  String libraryDeleteDocumentsForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge kalıcı olarak silinecek. Bu işlem geri alınamaz!',
    );
    return '$_temp0';
  }

  @override
  String libraryTrashDocumentsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge çöp kutusuna taşınacak.',
    );
    return '$_temp0';
  }

  @override
  String libraryPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa',
    );
    return '$_temp0';
  }

  @override
  String libraryDocumentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge',
    );
    return '$_temp0';
  }

  @override
  String libraryDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün',
    );
    return '$_temp0';
  }

  @override
  String get libraryRemoveFavoriteBadge => 'Favorilerden çıkar';

  @override
  String get libraryRemoveFromFavorites => 'Favorilerden Kaldır';

  @override
  String get libraryAddToFavorites => 'Favorilere Ekle';

  @override
  String get libraryMoveToTrash => 'Çöpe Taşı';

  @override
  String get libraryDocumentDuplicated => 'Belge çoğaltıldı';

  @override
  String get libraryDocumentMoved => 'Belge taşındı';

  @override
  String get libraryDocumentRestored => 'Belge geri yüklendi';

  @override
  String get libraryDeleteDocumentForeverMessage =>
      'Bu belge kalıcı olarak silinecek. Bu işlem geri alınamaz!';

  @override
  String get libraryDocumentNameLabel => 'Belge Adı';

  @override
  String get libraryChangeColor => 'Renk Değiştir';

  @override
  String get libraryFolderMoved => 'Klasör taşındı';

  @override
  String get libraryFolderColorChanged => 'Klasör rengi değiştirildi';

  @override
  String get libraryDeleteFolderTitle => 'Klasörü Sil';

  @override
  String libraryDeleteFolderNonEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu klasörde $count belge var. Klasörü silmek belgelerini de siler. Devam etmek istiyor musunuz?',
    );
    return '$_temp0';
  }

  @override
  String get libraryDeleteFolderMessage =>
      'Bu klasörü silmek istediğinize emin misiniz?';

  @override
  String get libraryFolderDeleted => 'Klasör silindi';

  @override
  String get libraryRenameFolderTitle => 'Klasörü Yeniden Adlandır';

  @override
  String get libraryFolderNameLabel => 'Klasör adı';

  @override
  String libraryFolderRenamed(String name) {
    return 'Klasör \"$name\" olarak yeniden adlandırıldı';
  }

  @override
  String libraryPageNumber(int page) {
    return 'Sayfa $page';
  }

  @override
  String libraryTrashedPageTitle(String document, int page) {
    return '$document — Sayfa $page';
  }

  @override
  String get librarySourceDocumentMissing => 'Kaynak belge bulunamadı';

  @override
  String get libraryPageRestored => 'Sayfa geri yüklendi';

  @override
  String get libraryPageRestoreFailed => 'Sayfa geri yüklenemedi';

  @override
  String get libraryDeletePageForeverMessage =>
      'Bu sayfa kalıcı olarak silinecek. Bu işlem geri alınamaz!';

  @override
  String libraryCopyTitle(String title) {
    return '$title (kopya)';
  }

  @override
  String get libraryNewNotebook => 'Not Defteri';

  @override
  String get libraryNewWhiteboard => 'Beyaz Tahta';

  @override
  String get libraryNewQuickNote => 'Hızlı Not';

  @override
  String get libraryImportPdf => 'PDF İçe Aktar';

  @override
  String get libraryImportImage => 'Resim İçe Aktar';

  @override
  String libraryQuickNoteTitle(String date) {
    return 'Hızlı Not - $date';
  }

  @override
  String libraryWhiteboardTitle(String date) {
    return 'Beyaz Tahta - $date';
  }

  @override
  String get libraryPdfReadFailed => 'PDF dosyası okunamadı';

  @override
  String get libraryImageReadFailed => 'Resim dosyası okunamadı';

  @override
  String get libraryImageLoading => 'Resim yükleniyor...';

  @override
  String get libraryImageTooLarge =>
      'Resim çok büyük! Maksimum boyut: 4096x4096';

  @override
  String get libraryPdfTooLarge =>
      'PDF dosyası çok büyük! Maksimum boyut: 200MB';

  @override
  String get libraryPdfOpening => 'PDF açılıyor...';

  @override
  String get libraryPdfImportFailed => 'PDF import başarısız';

  @override
  String libraryOpening(String title) {
    return '$title açılıyor';
  }

  @override
  String libraryOpeningWithPages(String title, String pages) {
    return '$title açılıyor ($pages)';
  }

  @override
  String get libraryFormat => 'Format';

  @override
  String get libraryOrientation => 'Yön';

  @override
  String get libraryPortrait => 'Dikey';

  @override
  String get libraryLandscape => 'Yatay';

  @override
  String get librarySize => 'Boyut';

  @override
  String libraryFormatSummary(String orientation, String size) {
    return '$orientation, $size';
  }

  @override
  String get libraryCover => 'Kapak';

  @override
  String get libraryPaper => 'Kağıt';

  @override
  String get libraryTitle => 'Başlık';

  @override
  String get libraryNoteTitleHint => 'Not Başlığı';

  @override
  String get libraryTemplateCategoryAll => 'Hepsi';

  @override
  String get libraryNoTemplatesInCategory => 'Bu kategoride şablon yok';

  @override
  String get libraryCreateNoteTitle => 'Yeni not oluştur';

  @override
  String get libraryTemplate => 'Şablon';

  @override
  String get libraryUntitledNote => 'İsimsiz Not';
}

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
  String libraryErrorBulkPartial(String message, int failed, int total) {
    return '$message ($total belgeden $failed tanesi başarısız)';
  }

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
  String get editorToolFountainPen => 'Dolma Kalem';

  @override
  String get editorToolPencil => 'Kurşun Kalem';

  @override
  String get editorToolHardPencil => 'Sert Kalem';

  @override
  String get editorToolBallpointPen => 'Tükenmez Kalem';

  @override
  String get editorToolGelPen => 'Jel Kalem';

  @override
  String get editorToolDashedPen => 'Kesik Çizgi';

  @override
  String get editorToolHighlighter => 'Fosforlu Kalem';

  @override
  String get editorToolBrushPen => 'Fırça Kalem';

  @override
  String get editorToolNeonHighlighter => 'Neon Fosforlu';

  @override
  String get editorToolRulerPen => 'Cetvelli Kalem';

  @override
  String get editorToolPixelEraser => 'Silgi';

  @override
  String get editorToolStrokeEraser => 'Çizgi Silgisi';

  @override
  String get editorToolLassoEraser => 'Kement Silgisi';

  @override
  String get editorToolShapes => 'Şekiller';

  @override
  String get editorToolText => 'Metin';

  @override
  String get editorToolSticker => 'Çıkartma';

  @override
  String get editorToolImage => 'Resim';

  @override
  String get editorToolSelection => 'Seçim';

  @override
  String get editorToolPanZoom => 'Kaydır/Yakınlaştır';

  @override
  String get editorToolLaserPointer => 'Lazer İşaretçi';

  @override
  String get editorToolStickyNote => 'Yapışkan Not';

  @override
  String get editorToolToolbarSettings => 'Araç Çubuğu Ayarları';

  @override
  String get editorToolPenGroup => 'Kalem';

  @override
  String get editorToolbarHome => 'Ana Sayfa';

  @override
  String get editorToolbarPages => 'Sayfa Paneli';

  @override
  String get editorToolbarRuler => 'Cetvel';

  @override
  String get editorToolbarAudio => 'Ses Kaydı';

  @override
  String get editorToolbarReaderMode => 'Okuyucu Modu';

  @override
  String get editorToolbarEditMode => 'Düzenleme Modu';

  @override
  String get editorToolbarMore => 'Daha Fazla';

  @override
  String get editorToolbarLayers => 'Katmanlar';

  @override
  String get editorToolbarAddPage => 'Sayfa Ekle';

  @override
  String get editorToolbarExport => 'Dışa Aktar';

  @override
  String get editorToolbarAi => 'Yapay Zeka';

  @override
  String get editorToolbarUntitled => 'İsimsiz Not';

  @override
  String get editorToolbarMoreColors => 'Daha Fazla Renk';

  @override
  String get editorToolbarColorSetHighlighter => 'Vurgulayıcı';

  @override
  String get editorToolbarColorSetPastel => 'Pastel';

  @override
  String editorToolbarSelectedColor(String hex) {
    return 'Seçili renk $hex';
  }

  @override
  String editorToolbarColor(String hex) {
    return 'Renk $hex';
  }

  @override
  String editorToolbarThickness(String value) {
    return 'Kalınlık $value';
  }

  @override
  String get editorToolbarMoreTools => 'Daha fazla araç';

  @override
  String get editorToolbarReadOnlyActive => 'Salt okunur mod aktif';

  @override
  String get editorToolbarReadOnly => 'Salt okunur';

  @override
  String get editorToolbarUndo => 'Geri al';

  @override
  String get editorToolbarRedo => 'İleri al';

  @override
  String get editorToolbarRecordingInProgress => 'Kayıt devam ediyor…';

  @override
  String get editorToolbarRecord => 'Kaydet';

  @override
  String get editorToolbarMicPermissionRequired =>
      'Mikrofon izni gerekli. Lütfen ayarlardan izin verin.';

  @override
  String get editorToolbarShowRecordings => 'Kayıtları göster';

  @override
  String get editorToolbarSettingsTabTools => 'Araçlar';

  @override
  String get editorToolbarSettingsTabExtraTools => 'Ek Araçlar';

  @override
  String get editorToolbarSettingsToolsHint => 'Araçları sıralayın ve gizleyin';

  @override
  String get editorToolbarSettingsExtraToolsHint =>
      'Ek araçları sıralayın ve gizleyin';

  @override
  String get editorToolbarSettingsReset => 'Varsayılana Sıfırla';

  @override
  String get editorToolbarColorSetBasic => 'Temel';

  @override
  String get editorToolbarColorSetNeon => 'Neon';

  @override
  String get editorPanelClose => 'Kapat';

  @override
  String get editorPanelThickness => 'Kalınlık';

  @override
  String get editorPanelPressureSensitivity => 'Basınç Duyarlılığı';

  @override
  String get editorPanelStabilization => 'Çizgi Stabilizasyonu';

  @override
  String get editorPanelPenType => 'Kalem türü';

  @override
  String get editorPanelGlow => 'Parlaklık';

  @override
  String get editorPanelStraightLine => 'Düz çizgi';

  @override
  String get editorPanelSize => 'Boyut';

  @override
  String get editorPanelEraserPixel => 'Piksel Silgi';

  @override
  String get editorPanelEraserPressure => 'Basınç hassasiyeti';

  @override
  String get editorPanelEraserHighlighterOnly => 'Sadece vurgulayıcı sil';

  @override
  String get editorPanelEraserAutoLift => 'Otomatik kaldır';

  @override
  String get editorPanelClearPage => 'Sayfayı Temizle';

  @override
  String get editorPanelClearPageTitle => 'Sayfayı Temizle?';

  @override
  String get editorPanelClearPageMessage =>
      'Bu sayfa içeriğini tamamen silecek. Bu işlem geri alınamaz.';

  @override
  String get editorPanelCancel => 'İptal';

  @override
  String get editorPanelClearPageConfirm => 'Temizle';

  @override
  String get editorPanelLaserDot => 'Lazer Nokta';

  @override
  String get editorPanelLaserLine => 'Lazer Çizgi';

  @override
  String get editorPanelLaserHollow => 'Lazer Çizgi (Boş)';

  @override
  String get editorPanelLaserRainbow => 'Lazer Gökkuşağı';

  @override
  String get editorPanelLaserDuration => 'Süre';

  @override
  String get editorPanelTextTitle => 'Metin Aracı';

  @override
  String get editorPanelTextHint => 'Tuvale dokunarak metin kutusu ekleyin.';

  @override
  String get editorPanelTextColor => 'Renk';

  @override
  String get editorPanelTextStyle => 'Stil';

  @override
  String get editorPanelAddNote => 'Not Ekle';

  @override
  String get editorPanelColorHex => 'Altıgen';

  @override
  String get editorPanelColorRed => 'Kırmızı';

  @override
  String get editorPanelColorGreen => 'Yeşil';

  @override
  String get editorPanelColorBlue => 'Mavi';

  @override
  String get editorPanelColorCancel => 'İptal et';

  @override
  String get editorPanelColorDone => 'Bitti';

  @override
  String get editorPanelColorSwatches => 'Kartelalar';

  @override
  String get editorPanelColorSpectrum => 'Spektrum';

  @override
  String get editorCatalogShapesTitle => 'Şekil';

  @override
  String get editorCatalogStrokeWidth => 'Kontur Kalınlığı';

  @override
  String get editorCatalogStrokeColor => 'Kontur Rengi';

  @override
  String get editorCatalogFillShape => 'Şekil dolgusu';

  @override
  String get editorCatalogFillColor => 'Dolgu Rengi';

  @override
  String get editorCatalogShapeLine => 'Çizgi';

  @override
  String get editorCatalogShapeArrow => 'Ok';

  @override
  String get editorCatalogShapeRectangle => 'Dikdörtgen';

  @override
  String get editorCatalogShapeEllipse => 'Elips';

  @override
  String get editorCatalogShapeTriangle => 'Üçgen';

  @override
  String get editorCatalogShapeDiamond => 'Eşkenar dörtgen';

  @override
  String get editorCatalogShapeStar => 'Yıldız';

  @override
  String get editorCatalogShapePentagon => 'Beşgen';

  @override
  String get editorCatalogShapeHexagon => 'Altıgen';

  @override
  String get editorCatalogShapePlus => 'Artı';

  @override
  String get editorCatalogStickersTitle => 'Çıkartmalar';

  @override
  String get editorCatalogAddSticker => 'Çıkartma Ekle';

  @override
  String get editorCatalogStickerEmoji => 'Emoji';

  @override
  String get editorCatalogStickerAnimals => 'Hayvanlar';

  @override
  String get editorCatalogStickerFood => 'Yiyecek';

  @override
  String get editorCatalogStickerTravel => 'Seyahat';

  @override
  String get editorCatalogStickerObjects => 'Nesneler';

  @override
  String get editorCatalogStickerSymbols => 'Semboller';

  @override
  String get editorCatalogStickerHands => 'Eller';

  @override
  String get editorCatalogStickerNature => 'Doğa';

  @override
  String get editorSelectionLassoFreeform => 'Serbest Seçim';

  @override
  String get editorSelectionLassoRectangle => 'Dikdörtgen Seçim';

  @override
  String get editorSelectionLassoSelectable => 'Seçilebilir';

  @override
  String get editorSelectionTypeHandwriting => 'El yazısı';

  @override
  String get editorSelectionTypeShape => 'Şekil';

  @override
  String get editorSelectionTypeImage => 'Resim';

  @override
  String get editorSelectionTypeHighlighter => 'Vurgulayıcı';

  @override
  String get editorSelectionTypeText => 'Metin';

  @override
  String get editorSelectionTypeTape => 'Bant';

  @override
  String get editorSelectionTypeLink => 'Link';

  @override
  String get editorSelectionTypeLabel => 'Etiket';

  @override
  String get editorSelectionAi => 'AI Asistan';

  @override
  String get editorSelectionColor => 'Renk';

  @override
  String get editorSelectionScreenshot => 'Ekran Resmi';

  @override
  String get editorSelectionCut => 'Kes';

  @override
  String get editorSelectionDuplicate => 'Çoğalt';

  @override
  String get editorSelectionDelete => 'Sil';

  @override
  String get editorSelectionBringToFront => 'Öne Getir';

  @override
  String get editorSelectionSendToBack => 'Arkaya Gönder';

  @override
  String get editorSelectionCopy => 'Kopyala';

  @override
  String get editorSelectionPaste => 'Yapıştır';

  @override
  String get editorSelectionAskAi => 'Yapay zekaya sor';

  @override
  String get editorSelectionTakeScreenshot => 'Ekran Resmi Çek';

  @override
  String get editorSelectionMore => 'Daha fazla';

  @override
  String get editorSelectionSave => 'Kaydet';

  @override
  String get editorSelectionScreenshotCaptureFailed =>
      'Ekran resmi oluşturulamadı';

  @override
  String get editorSelectionScreenshotSavedAndCopied =>
      'Ekran resmi galeriye kaydedildi ve panoya kopyalandı';

  @override
  String get editorSelectionScreenshotSaved =>
      'Ekran resmi galeriye kaydedildi';

  @override
  String get editorSelectionScreenshotCopied => 'Ekran resmi panoya kopyalandı';

  @override
  String get editorSelectionScreenshotSaveFailed => 'Ekran resmi kaydedilemedi';

  @override
  String get editorSelectionContextEdit => 'Düzenle';

  @override
  String get editorSelectionContextStyle => 'Stil';

  @override
  String get editorSelectionContextMove => 'Taşı';

  @override
  String get editorDocumentNameLabel => 'Belge Adı';

  @override
  String get editorMoveToTrashTitle => 'Çöpe Taşı';

  @override
  String get editorMoveToTrashMessage =>
      'Bu belge çöpe taşınacak. Daha sonra geri yükleyebilirsiniz.';

  @override
  String get editorLoadErrorTitle => 'Belge açılamadı';

  @override
  String get editorLoadErrorMessage => 'Belge bulunamadı ya da okunamadı.';

  @override
  String get editorLoadErrorBack => 'Geri dön';

  @override
  String get editorSaveFailedMessage =>
      'Kaydedilemedi. Değişiklikleriniz henüz kaydedilmedi.';

  @override
  String get startupErrorTitle => 'Uygulama başlatılamadı';

  @override
  String get startupErrorMessage =>
      'Notlarınız güvende, hiçbir şey silinmedi. Veriler açılırken bir sorun oluştu. Tekrar deneyin; sorun sürerse uygulamayı kapatıp yeniden açın.';

  @override
  String get commonPasswordLabel => 'Şifre';

  @override
  String get commonSelectItemTitle => 'Bir öğe seçin';

  @override
  String get commonSelectItemDescription =>
      'Detayları görmek için sol taraftan bir öğe seçin';

  @override
  String get commonUnderConstruction => 'Bu ekran henüz yapım aşamasında';

  @override
  String get routerForgotPasswordTitle => 'Şifremi unuttum';

  @override
  String get routerProfileTitle => 'Profil';

  @override
  String get routerSubscriptionTitle => 'Abonelik';

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

  @override
  String get libraryPaperColorWhite => 'Beyaz kağıt';

  @override
  String get libraryPaperColorBlack => 'Siyah kağıt';

  @override
  String get libraryPaperColorCream => 'Krem kağıt';

  @override
  String get libraryPaperColorGray => 'Gri kağıt';

  @override
  String get libraryPaperColorGreen => 'Yeşil kağıt';

  @override
  String get libraryPaperColorBlue => 'Mavi kağıt';

  @override
  String get libraryPaperColorYellow => 'Sarı kağıt';

  @override
  String get librarySelectColor => 'Renk Seç';

  @override
  String get editorPageRename => 'Yeniden Adlandır';

  @override
  String get editorPageMoveDocumentToTrash => 'Çöpe Taşı';

  @override
  String get editorPageDocumentOptions => 'Doküman Seçenekleri';

  @override
  String editorPagePageNumber(int number) {
    return 'Sayfa $number';
  }

  @override
  String get editorPageBookmarkPage => 'Yer imi koy';

  @override
  String get editorPageRemoveBookmark => 'Yer imini kaldır';

  @override
  String get editorPageCopyPage => 'Sayfayı kopyala';

  @override
  String get editorPagePastePage => 'Sayfayı yapıştır';

  @override
  String get editorPageDuplicatePage => 'Sayfayı çoğalt';

  @override
  String get editorPageChangeTemplate => 'Şablonu değiştir';

  @override
  String get editorPageGoToPageMenu => 'Sayfaya git';

  @override
  String get editorPageExportPagePdf => 'PDF olarak dışa aktar';

  @override
  String get editorPageClearPageMenu => 'Sayfayı temizle';

  @override
  String get editorPageMovePageToTrash => 'Çöpe taşı';

  @override
  String get editorPageSettings => 'Ayarlar';

  @override
  String get editorPageEditToolbar => 'Araç Çubuğunu Düzenle';

  @override
  String get editorPageScrollDirection => 'Kaydırma yönü';

  @override
  String get editorPageScrollHorizontal => 'Yatay';

  @override
  String get editorPageScrollVertical => 'Dikey';

  @override
  String get editorPagePageCopied => 'Sayfa kopyalandı';

  @override
  String get editorPagePagePasted => 'Sayfa yapıştırıldı';

  @override
  String get editorPagePageDuplicated => 'Sayfa çoğaltıldı';

  @override
  String get editorPageLastPageCannotDelete => 'Son sayfa silinemez';

  @override
  String get editorPagePageDeleted => 'Sayfa silindi';

  @override
  String editorPageClearPageQuestion(int page) {
    return 'Sayfa $page temizlensin mi?\nBu işlem geri alınabilir.';
  }

  @override
  String get editorPagePageAdded => 'Sayfa eklendi';

  @override
  String get editorPagePageMoved => 'Sayfa taşındı';

  @override
  String get editorPageGoToPage => 'Sayfaya Git';

  @override
  String get editorPageGo => 'Git';

  @override
  String editorPageListPageOf(int page, int count) {
    return 'Sayfa $page / $count';
  }

  @override
  String editorPageListPageRangeOf(int first, int last, int count) {
    return 'Sayfa $first-$last / $count';
  }

  @override
  String get editorPageListPreviousPage => 'Önceki Sayfa';

  @override
  String get editorPageListNextPage => 'Sonraki Sayfa';

  @override
  String editorPageListGoToPageHint(String pageLabel) {
    return '$pageLabel, Sayfaya gitmek için dokunun';
  }

  @override
  String get editorPageListAddPage => 'Sayfa ekle';

  @override
  String get editorPageListAddBookmark => 'Yer imi ekle';

  @override
  String get editorPageListNoBookmarks => 'Henüz yer imi yok';

  @override
  String get editorPageListNoBookmarksHint =>
      'Bir sayfayı işaretlemek için küçük resmindeki yer imi simgesine dokunun.';

  @override
  String get editorPageListFilterAllPages => 'Tüm sayfalar';

  @override
  String get editorPageListFilterBookmarks => 'Yer imleri';

  @override
  String get editorPageListFilterRecordings => 'Ses kayıtları';

  @override
  String get editorPageListPageOptions => 'Sayfa seçenekleri';

  @override
  String get editorPageListThumbnailFailed => 'Önizleme\noluşturulamadı';

  @override
  String get editorPageListDropToAddPage =>
      'Yeni sayfa eklemek için\nsürükleyip bırakın';

  @override
  String get editorPageListPositionBefore => 'Önce';

  @override
  String get editorPageListPositionAfter => 'Sonra';

  @override
  String get editorPageListLastPage => 'Son sayfa';

  @override
  String get editorPageListMoreTemplates => 'Daha Fazla Şablon';

  @override
  String get editorPageListTakePhoto => 'Fotoğraf çek';

  @override
  String get editorPageListImportFile => 'İçe aktar';

  @override
  String get editorExportScopeAll => 'Tümü';

  @override
  String get editorExportScopeCurrent => 'Bu sayfa';

  @override
  String get editorExportScopeRange => 'Aralık';

  @override
  String get editorExportFrom => 'Başlangıç';

  @override
  String get editorExportTo => 'Bitiş';

  @override
  String get editorExportIncludeTemplate => 'Sayfa şablonunu dahil et';

  @override
  String get editorExportExportPng => 'PNG Olarak Dışa Aktar';

  @override
  String get editorExportExportPdf => 'PDF Olarak Dışa Aktar';

  @override
  String get editorExportSharePdf => 'PDF Paylaş';

  @override
  String editorExportInvalidRange(int count) {
    return 'Sayfa aralığı 1 ile $count arasında olmalı.';
  }

  @override
  String get editorExportSavePdfDialog => 'PDF Kaydet';

  @override
  String get editorExportSavePngDialog => 'PNG Kaydet';

  @override
  String get editorExportFallbackFileName => 'doküman';

  @override
  String editorExportPageFileName(String title, int page) {
    return '${title}_sayfa$page';
  }

  @override
  String get editorExportExporting => 'PDF Dışa Aktarılıyor...';

  @override
  String editorExportPercent(int percent) {
    return '%$percent';
  }

  @override
  String editorExportRemainingSeconds(int seconds) {
    return '~$seconds sn';
  }

  @override
  String editorExportRemainingMinutes(int minutes) {
    return '~$minutes dk';
  }

  @override
  String get editorExportSaved => 'PDF Kaydedildi';

  @override
  String editorExportSavedWithSize(String size) {
    return 'PDF Kaydedildi ($size)';
  }

  @override
  String get editorExportCancelled => 'İptal edildi';

  @override
  String editorExportPagesWithoutPdfBackground(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa PDF arka planı olmadan dışa aktarıldı',
    );
    return '$_temp0';
  }

  @override
  String get editorTemplateAllCategories => 'Tümü';

  @override
  String get editorTemplateCoverTab => 'Kapak';

  @override
  String get editorTemplatePaperTab => 'Kâğıt';

  @override
  String get editorTemplateApply => 'Uygula';

  @override
  String get editorTemplatePortrait => 'Dikey';

  @override
  String get editorTemplateLandscape => 'Yatay';

  @override
  String get editorTemplatePaperSquare => 'Kare';

  @override
  String get editorTemplatePaperWidescreen => 'Geniş (16:9)';

  @override
  String get editorTemplateCustom => 'Özel';

  @override
  String get editorTemplateColorWhite => 'Beyaz';

  @override
  String get editorTemplateColorCream => 'Krem';

  @override
  String get editorTemplateColorBlack => 'Siyah';

  @override
  String get editorTemplateColorYellow => 'Sarı';

  @override
  String get editorTemplateTemplatesHeader => 'Şablonlar';

  @override
  String get editorTemplateBackground => 'Arka Plan';

  @override
  String get editorTemplateBackgroundPattern => 'Arka Plan Deseni';

  @override
  String get editorTemplatePatternPlain => 'Düz';

  @override
  String get editorTemplatePatternDotted => 'Noktalı';

  @override
  String get editorTemplatePatternGrid => 'Izgara';

  @override
  String get editorTemplateBackgroundColor => 'Arka Plan Rengi';

  @override
  String get editorCoverSolidNavy => 'Lacivert';

  @override
  String get editorCoverSolidBurgundy => 'Bordo';

  @override
  String get editorCoverMinimalGray => 'Gri Çerçeve';

  @override
  String get editorCoverPatternDots => 'Noktalı';

  @override
  String get editorCoverPatternLines => 'Çizgili';

  @override
  String get editorCoverGradientSunset => 'Gün Batımı';

  @override
  String get editorCoverGradientOcean => 'Okyanus';

  @override
  String get editorCoverGradientForest => 'Orman';

  @override
  String get editorCoverGradientPurple => 'Lavanta';

  @override
  String get editorCoverImgKraft => 'Kraft';

  @override
  String get editorCoverImgGeometric => 'Geometrik';

  @override
  String get editorCoverImgTerrazzo => 'Terrazzo';

  @override
  String get editorCoverImgDinosaur => 'Dinozor';

  @override
  String get editorCoverImgSpace => 'Uzay';

  @override
  String get editorCoverImgFloral => 'Çiçekli';

  @override
  String get editorCoverImgNavyGold => 'Lacivert Gold';

  @override
  String get editorCoverImgLeather => 'Deri';

  @override
  String get editorCoverLinenSage => 'Adaçayı Keten';

  @override
  String get editorCoverLinenSand => 'Kum Keten';

  @override
  String get editorCoverLinenSlate => 'Arduvaz Keten';

  @override
  String get editorCoverLeatherOxblood => 'Vişne Deri';

  @override
  String get editorCoverLeatherCognac => 'Konyak Deri';

  @override
  String get editorCoverLeatherNavy => 'Lacivert Deri';

  @override
  String get editorCoverKraftNatural => 'Doğal Kraft';

  @override
  String get editorCoverKraftCharcoal => 'Füme Kraft';

  @override
  String get editorCoverFeltMustard => 'Hardal Keçe';

  @override
  String get editorCoverFeltDustyRose => 'Gül Kurusu Keçe';

  @override
  String get editorErrorExportStorageFull =>
      'Dışa aktarma için yeterli depolama alanı yok. Yer açıp tekrar deneyin.';

  @override
  String get editorErrorExportCannotWrite =>
      'Dosya yazılamadı. Tekrar deneyin.';

  @override
  String get editorErrorExportFailed => 'Dışa aktarılamadı. Tekrar deneyin.';

  @override
  String get editorErrorExportNoPages => 'Dışa aktarılacak sayfa yok';

  @override
  String get editorErrorPdfPasswordProtected =>
      'Bu PDF parola korumalı. Parolayı kaldırıp tekrar deneyin.';

  @override
  String get editorErrorPdfFileAccess => 'PDF dosyasına erişilemedi.';

  @override
  String get editorErrorPdfStorageFull =>
      'PDF içe aktarmak için yeterli depolama alanı yok. Yer açıp tekrar deneyin.';

  @override
  String get editorErrorPdfOpenFailed => 'PDF açılamadı. Dosya bozuk olabilir.';

  @override
  String get editorErrorPdfPagesUnreadable =>
      'PDF sayfaları okunamadı. Dosya bozuk olabilir.';

  @override
  String editorErrorPdfTooManyPages(int count, int max) {
    return 'PDF çok fazla sayfa içeriyor ($count). Maksimum $max sayfa destekleniyor.';
  }

  @override
  String get editorErrorPdfPagePlaceholder => 'PDF Sayfası';

  @override
  String get editorErrorPdfSourceMissing => 'Kaynak PDF bulunamadı';

  @override
  String get editorErrorPdfLoadFailed => 'PDF Yüklenemedi';

  @override
  String editorErrorPdfPagesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa okunamadı ve atlandı',
    );
    return '$_temp0';
  }

  @override
  String get editorCanvasAddLayer => 'Katman Ekle';

  @override
  String editorCanvasDefaultLayerName(int number) {
    return 'Katman $number';
  }

  @override
  String get editorCanvasDeleteLayer => 'Katmanı Sil';

  @override
  String get editorCanvasDuplicateLayer => 'Katmanı Kopyala';

  @override
  String get editorCanvasHideLayer => 'Gizle';

  @override
  String get editorCanvasShowLayer => 'Göster';

  @override
  String get editorCanvasLockLayer => 'Kilitle';

  @override
  String get editorCanvasUnlockLayer => 'Kilidi Aç';

  @override
  String get editorCanvasZoomLock => 'Yakınlaştırma kilidi';

  @override
  String editorCanvasZoomLevel(int percent) {
    return 'Yakınlaştırma $percent%, favori düzeyler';
  }

  @override
  String get editorCanvasFavoriteZoom => 'Favori yakınlaştırma';

  @override
  String editorCanvasPenBox(int count) {
    return 'Kalem kutusu, $count kalem';
  }

  @override
  String get editorCanvasFinishEditing => 'Düzenlemeyi bitir';

  @override
  String get editorCanvasEditPenBox => 'Kalem kutusunu düzenle';

  @override
  String get editorCanvasCollapsePenBox => 'Kalem kutusunu daralt';

  @override
  String get editorCanvasRemovePen => 'Kalemi kaldır';

  @override
  String get editorCanvasAddImage => 'Resim Ekle';

  @override
  String get editorCanvasAddImageHint =>
      'Galeriden veya kamerayla resim ekleyin';

  @override
  String get editorCanvasFromGallery => 'Galeriden Seç';

  @override
  String get editorCanvasFromGalleryHint => 'Albümden bir resim seçin';

  @override
  String get editorCanvasTakePhoto => 'Fotoğraf Çek';

  @override
  String get editorCanvasTakePhotoHint => 'Kamera ile yeni fotoğraf çekin';

  @override
  String get editorCanvasTapToPlace => 'Yerleştirmek için dokunun';

  @override
  String get editorCanvasTapToPlaceImage => 'Resmi yerleştirmek için dokunun';

  @override
  String get editorCanvasAddColor => 'Renk ekle';

  @override
  String get editorCanvasTextStyleTitle => 'Metin Stili';

  @override
  String get editorCanvasEmojiSize => 'Emoji Boyutu';

  @override
  String get editorCanvasTextPreviewSample => 'Merhaba';

  @override
  String get libraryManageFolders => 'Klasörleri Yönet';

  @override
  String get libraryNoFoldersYet => 'Henüz klasör yok';

  @override
  String get libraryNoFoldersHint =>
      'Yeni bir klasör oluşturmak için aşağıdaki butona tıklayın';

  @override
  String get libraryNoFoldersStartHint => 'Yeni klasör oluşturarak başlayın';

  @override
  String get libraryFolderOrderSaved => 'Sıralama kaydedildi';

  @override
  String get libraryAddSubfolder => 'Alt Klasör Ekle';

  @override
  String libraryAddSubfolderTitle(String parent) {
    return '$parent altına klasör ekle';
  }

  @override
  String libraryDeleteFolderConfirm(String name) {
    return '\"$name\" klasörünü silmek istediğinize emin misiniz?\nİçindeki notlar çöp kutusuna taşınacak.';
  }

  @override
  String get libraryFolderManagement => 'Klasör Yönetimi';

  @override
  String get libraryMoveFolderTitle => 'Klasörü Taşı';

  @override
  String get libraryMoveToFolderTitle => 'Klasöre Taşı';

  @override
  String get libraryFoldersLoadFailed => 'Klasörler yüklenemedi';

  @override
  String get libraryFolderNameEmpty => 'Klasör adı boş olamaz';

  @override
  String libraryFolderCreated(String name) {
    return 'Klasör \"$name\" oluşturuldu';
  }

  @override
  String get libraryRootFolders => 'Ana Klasörler';

  @override
  String get libraryNoFolderRoot => 'Belgeler (Klasörsüz)';

  @override
  String get libraryFolderNameHint => 'Klasör adı girin';

  @override
  String get libraryColor => 'Renk';

  @override
  String get libraryFolderColorEmerald => 'Zümrüt';

  @override
  String get libraryFolderColorPurple => 'Mor';

  @override
  String get libraryFolderColorPink => 'Pembe';

  @override
  String get libraryFolderColorRed => 'Kırmızı';

  @override
  String get libraryFolderColorOrange => 'Turuncu';

  @override
  String get libraryFolderColorAmber => 'Kehribar';

  @override
  String get libraryFolderColorGreen => 'Yeşil';

  @override
  String get libraryFolderColorTeal => 'Turkuaz';

  @override
  String get libraryFolderColorCyan => 'Camgöbeği';

  @override
  String get libraryFolderColorBlue => 'Mavi';

  @override
  String get libraryFolderColorGray => 'Gri';

  @override
  String get libraryFolderColorStone => 'Taş';
}

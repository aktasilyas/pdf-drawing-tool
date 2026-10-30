import '../services/pdf_page_range.dart' show PdfPageRangeError;

/// User-facing copy of the page options menu, page actions and the go-to dialog.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class PageStrings {
  const PageStrings();

  String get rename;
  String get moveDocumentToTrash;
  String get documentOptions;
  String pageNumber(int number);
  String get bookmarkPage;
  String get removeBookmark;
  String get copyPage;
  String get pastePage;
  String get duplicatePage;
  String get changeTemplate;
  String get goToPageMenu;
  String get exportPagePdf;
  String get clearPageMenu;
  String get movePageToTrash;
  String get settings;
  String get editToolbar;
  String get scrollDirection;
  String get scrollHorizontal;
  String get scrollVertical;
  String get pageCopied;
  String get pagePasted;

  /// SnackBar when a paste is refused because a copied file is gone.
  String get pasteFilesMissing;
  String get pageDuplicated;
  String get lastPageCannotDelete;
  String get pageDeleted;
  String clearPageQuestion(int page);
  String get pageAdded;
  String get pageMoved;
  String get cannotUndo;

  /// SnackBar after a template replaced a PDF or cover background.
  String get backgroundReplaced;
  String get goToPage;
  String get go;

  /// Title of the page range sheet for a PDF with [count] pages.
  String pdfRangeTitle(int count);
  String pdfRangeLimitHint(int max);
  String pdfRangeImportFirst(int max);
  String get pdfRangeChoose;
  String get pdfRangeStart;
  String get pdfRangeEnd;
  String get pdfRangeImport;
  String get pdfRangeCancel;

  /// Error shown under the range fields for [error].
  String pdfRangeError(PdfPageRangeError error, int total, int max);

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'rename': rename,
        'moveDocumentToTrash': moveDocumentToTrash,
        'documentOptions': documentOptions,
        'pageNumber': pageNumber(1),
        'bookmarkPage': bookmarkPage,
        'removeBookmark': removeBookmark,
        'copyPage': copyPage,
        'pastePage': pastePage,
        'duplicatePage': duplicatePage,
        'changeTemplate': changeTemplate,
        'goToPageMenu': goToPageMenu,
        'exportPagePdf': exportPagePdf,
        'clearPageMenu': clearPageMenu,
        'movePageToTrash': movePageToTrash,
        'settings': settings,
        'editToolbar': editToolbar,
        'scrollDirection': scrollDirection,
        'scrollHorizontal': scrollHorizontal,
        'scrollVertical': scrollVertical,
        'pageCopied': pageCopied,
        'pagePasted': pagePasted,
        'pasteFilesMissing': pasteFilesMissing,
        'pageDuplicated': pageDuplicated,
        'lastPageCannotDelete': lastPageCannotDelete,
        'pageDeleted': pageDeleted,
        'clearPageQuestion': clearPageQuestion(1),
        'pageAdded': pageAdded,
        'pageMoved': pageMoved,
        'cannotUndo': cannotUndo,
        'backgroundReplaced': backgroundReplaced,
        'goToPage': goToPage,
        'go': go,
        'pdfRangeTitle': pdfRangeTitle(640),
        'pdfRangeLimitHint': pdfRangeLimitHint(500),
        'pdfRangeImportFirst': pdfRangeImportFirst(500),
        'pdfRangeChoose': pdfRangeChoose,
        'pdfRangeStart': pdfRangeStart,
        'pdfRangeEnd': pdfRangeEnd,
        'pdfRangeImport': pdfRangeImport,
        'pdfRangeCancel': pdfRangeCancel,
        for (final e in PdfPageRangeError.values)
          'pdfRangeError.${e.name}': pdfRangeError(e, 640, 500),
      };
}

/// Turkish copy: the default when no scope is installed.
class PageStringsTr extends PageStrings {
  const PageStringsTr();

  @override
  String get rename => 'Yeniden Adlandır';

  @override
  String get moveDocumentToTrash => 'Çöpe Taşı';

  @override
  String get documentOptions => 'Doküman Seçenekleri';

  @override
  String pageNumber(int number) => 'Sayfa $number';

  @override
  String get bookmarkPage => 'Yer imi koy';

  @override
  String get removeBookmark => 'Yer imini kaldır';

  @override
  String get copyPage => 'Sayfayı kopyala';

  @override
  String get pastePage => 'Sayfayı yapıştır';

  @override
  String get duplicatePage => 'Sayfayı çoğalt';

  @override
  String get changeTemplate => 'Şablonu değiştir';

  @override
  String get goToPageMenu => 'Sayfaya git';

  @override
  String get exportPagePdf => 'PDF olarak dışa aktar';

  @override
  String get clearPageMenu => 'Sayfayı temizle';

  @override
  String get movePageToTrash => 'Çöpe taşı';

  @override
  String get settings => 'Ayarlar';

  @override
  String get editToolbar => 'Araç Çubuğunu Düzenle';

  @override
  String get scrollDirection => 'Kaydırma yönü';

  @override
  String get scrollHorizontal => 'Yatay';

  @override
  String get scrollVertical => 'Dikey';

  @override
  String get pageCopied => 'Sayfa kopyalandı';

  @override
  String get pagePasted => 'Sayfa yapıştırıldı';

  @override
  String get pasteFilesMissing =>
      'Yapıştırılamadı: kopyalanan dosyalar artık yok';

  @override
  String get pageDuplicated => 'Sayfa çoğaltıldı';

  @override
  String get lastPageCannotDelete => 'Son sayfa silinemez';

  @override
  String get pageDeleted => 'Sayfa silindi';

  @override
  String clearPageQuestion(int page) =>
      'Sayfa $page temizlensin mi?\nBu işlem geri alınabilir.';

  @override
  String get pageAdded => 'Sayfa eklendi';

  @override
  String get pageMoved => 'Sayfa taşındı';

  @override
  String get cannotUndo => 'Geri alınamadı';

  @override
  String get backgroundReplaced => 'Sayfa arka planı değiştirildi';

  @override
  String get goToPage => 'Sayfaya Git';

  @override
  String get go => 'Git';

  @override
  String pdfRangeTitle(int count) => 'Bu PDF $count sayfa';

  @override
  String pdfRangeLimitHint(int max) =>
      'Bir seferde en fazla $max sayfa içe aktarılabilir.';

  @override
  String pdfRangeImportFirst(int max) => 'İlk $max sayfayı içe aktar';

  @override
  String get pdfRangeChoose => 'Aralık seç';

  @override
  String get pdfRangeStart => 'Başlangıç';

  @override
  String get pdfRangeEnd => 'Bitiş';

  @override
  String get pdfRangeImport => 'İçe aktar';

  @override
  String get pdfRangeCancel => 'Vazgeç';

  @override
  String pdfRangeError(PdfPageRangeError error, int total, int max) =>
      switch (error) {
        PdfPageRangeError.startBelowOne => 'Başlangıç en az 1 olmalı',
        PdfPageRangeError.startAfterEnd => 'Başlangıç, bitişten büyük olamaz',
        PdfPageRangeError.endAfterTotal => 'Bitiş $total sayfadan büyük olamaz',
        PdfPageRangeError.tooLong => 'En fazla $max sayfa seçilebilir',
      };
}

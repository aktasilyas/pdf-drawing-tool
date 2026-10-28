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
  String get pageDuplicated;
  String get lastPageCannotDelete;
  String get pageDeleted;
  String clearPageQuestion(int page);
  String get pageAdded;
  String get pageMoved;
  String get goToPage;
  String get go;

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
        'pageDuplicated': pageDuplicated,
        'lastPageCannotDelete': lastPageCannotDelete,
        'pageDeleted': pageDeleted,
        'clearPageQuestion': clearPageQuestion(1),
        'pageAdded': pageAdded,
        'pageMoved': pageMoved,
        'goToPage': goToPage,
        'go': go,
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
  String get goToPage => 'Sayfaya Git';

  @override
  String get go => 'Git';
}

/// User-facing copy of the page indicator, sidebar, thumbnails and add-page panel.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class PageListStrings {
  const PageListStrings();

  String pageOf(int page, int count);
  String pageRangeOf(int first, int last, int count);
  String get previousPage;
  String get nextPage;
  String goToPageHint(String pageLabel);
  String get addPage;
  String get addBookmark;
  String get noBookmarks;
  String get noBookmarksHint;
  String get filterAllPages;
  String get filterBookmarks;
  String get filterRecordings;
  String get pageOptions;
  String get thumbnailFailed;
  String get dropToAddPage;
  String get positionBefore;
  String get positionAfter;
  String get lastPage;
  String get moreTemplates;
  String get takePhoto;
  String get importFile;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'pageOf': pageOf(1, 2),
        'pageRangeOf': pageRangeOf(1, 2, 10),
        'previousPage': previousPage,
        'nextPage': nextPage,
        'goToPageHint': goToPageHint('Notes'),
        'addPage': addPage,
        'addBookmark': addBookmark,
        'noBookmarks': noBookmarks,
        'noBookmarksHint': noBookmarksHint,
        'filterAllPages': filterAllPages,
        'filterBookmarks': filterBookmarks,
        'filterRecordings': filterRecordings,
        'pageOptions': pageOptions,
        'thumbnailFailed': thumbnailFailed,
        'dropToAddPage': dropToAddPage,
        'positionBefore': positionBefore,
        'positionAfter': positionAfter,
        'lastPage': lastPage,
        'moreTemplates': moreTemplates,
        'takePhoto': takePhoto,
        'importFile': importFile,
      };
}

/// Turkish copy: the default when no scope is installed.
class PageListStringsTr extends PageListStrings {
  const PageListStringsTr();

  @override
  String pageOf(int page, int count) => 'Sayfa $page / $count';

  @override
  String pageRangeOf(int first, int last, int count) =>
      'Sayfa $first-$last / $count';

  @override
  String get previousPage => 'Önceki Sayfa';

  @override
  String get nextPage => 'Sonraki Sayfa';

  @override
  String goToPageHint(String pageLabel) =>
      '$pageLabel, Sayfaya gitmek için dokunun';

  @override
  String get addPage => 'Sayfa ekle';

  @override
  String get addBookmark => 'Yer imi ekle';

  @override
  String get noBookmarks => 'Henüz yer imi yok';

  @override
  String get noBookmarksHint =>
      'Bir sayfayı işaretlemek için küçük resmindeki yer imi simgesine dokunun.';

  @override
  String get filterAllPages => 'Tüm sayfalar';

  @override
  String get filterBookmarks => 'Yer imleri';

  @override
  String get filterRecordings => 'Ses kayıtları';

  @override
  String get pageOptions => 'Sayfa seçenekleri';

  @override
  String get thumbnailFailed => 'Önizleme\noluşturulamadı';

  @override
  String get dropToAddPage => 'Yeni sayfa eklemek için\nsürükleyip bırakın';

  @override
  String get positionBefore => 'Önce';

  @override
  String get positionAfter => 'Sonra';

  @override
  String get lastPage => 'Son sayfa';

  @override
  String get moreTemplates => 'Daha Fazla Şablon';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get importFile => 'İçe aktar';
}

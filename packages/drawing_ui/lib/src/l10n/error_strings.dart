/// User-facing copy of export and PDF import failures and PDF page placeholders.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class ErrorStrings {
  const ErrorStrings();

  String get exportStorageFull;
  String get exportCannotWrite;
  String get exportFailed;
  String get exportNoPages;
  String get pdfPasswordProtected;
  String get pdfFileAccess;
  String get pdfOpenFailed;
  String get pdfPagesUnreadable;
  String pdfTooManyPages(int count, int max);
  String get pdfPagePlaceholder;
  String get pdfSourceMissing;
  String get pdfLoadFailed;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'exportStorageFull': exportStorageFull,
        'exportCannotWrite': exportCannotWrite,
        'exportFailed': exportFailed,
        'exportNoPages': exportNoPages,
        'pdfPasswordProtected': pdfPasswordProtected,
        'pdfFileAccess': pdfFileAccess,
        'pdfOpenFailed': pdfOpenFailed,
        'pdfPagesUnreadable': pdfPagesUnreadable,
        'pdfTooManyPages': pdfTooManyPages(1, 2),
        'pdfPagePlaceholder': pdfPagePlaceholder,
        'pdfSourceMissing': pdfSourceMissing,
        'pdfLoadFailed': pdfLoadFailed,
      };
}

/// Turkish copy: the default when no scope is installed.
class ErrorStringsTr extends ErrorStrings {
  const ErrorStringsTr();

  @override
  String get exportStorageFull =>
      'Dışa aktarma için yeterli depolama alanı yok. Yer açıp tekrar deneyin.';

  @override
  String get exportCannotWrite => 'Dosya yazılamadı. Tekrar deneyin.';

  @override
  String get exportFailed => 'Dışa aktarılamadı. Tekrar deneyin.';

  @override
  String get exportNoPages => 'Dışa aktarılacak sayfa yok';

  @override
  String get pdfPasswordProtected =>
      'Bu PDF parola korumalı. Parolayı kaldırıp tekrar deneyin.';

  @override
  String get pdfFileAccess => 'PDF dosyasına erişilemedi.';

  @override
  String get pdfOpenFailed => 'PDF açılamadı. Dosya bozuk olabilir.';

  @override
  String get pdfPagesUnreadable =>
      'PDF sayfaları okunamadı. Dosya bozuk olabilir.';

  @override
  String pdfTooManyPages(int count, int max) =>
      'PDF çok fazla sayfa içeriyor ($count). Maksimum $max sayfa destekleniyor.';

  @override
  String get pdfPagePlaceholder => 'PDF Sayfası';

  @override
  String get pdfSourceMissing => 'Kaynak PDF bulunamadı';

  @override
  String get pdfLoadFailed => 'PDF Yüklenemedi';
}

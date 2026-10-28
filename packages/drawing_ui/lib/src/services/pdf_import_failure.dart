/// Why a PDF import failed.
enum PdfImportError {
  passwordProtected,
  fileAccess,

  /// The device has no space left for the copy in app storage.
  storageFull,
  openFailed,
  pagesUnreadable,
  tooManyPages,
}

/// A PDF import failure, mapped to copy by `PdfImportFailureLabel.message`.
///
/// [pageCount] and [maxPages] are only set for [PdfImportError.tooManyPages].
final class PdfImportFailure {
  const PdfImportFailure(this.error, {this.pageCount = 0, this.maxPages = 0});

  final PdfImportError error;
  final int pageCount;
  final int maxPages;

  @override
  bool operator ==(Object other) =>
      other is PdfImportFailure &&
      other.error == error &&
      other.pageCount == pageCount &&
      other.maxPages == maxPages;

  @override
  int get hashCode => Object.hash(error, pageCount, maxPages);

  @override
  String toString() => 'PdfImportFailure($error, $pageCount, $maxPages)';
}

import 'pdf_import_models.dart';
import 'pdf_import_service.dart';

/// Why a 1-based, inclusive PDF page range cannot be imported.
enum PdfPageRangeError { startBelowOne, startAfterEnd, endAfterTotal, tooLong }

/// A 1-based, inclusive range of PDF pages.
class PdfPageRange {
  const PdfPageRange(this.start, this.end);

  final int start;
  final int end;

  /// The import config that selects exactly this range.
  PDFImportConfig toConfig() =>
      PDFImportConfig.pageRange(startPage: start, endPage: end);

  @override
  bool operator ==(Object other) =>
      other is PdfPageRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PdfPageRange($start-$end)';
}

/// Asks the user which pages of a [pageCount]-page PDF to import, at most
/// [maxPages]. Returns null when the user cancels.
typedef ChoosePdfPageRange = Future<PdfPageRange?> Function(
  int pageCount,
  int maxPages,
);

/// Checks [start]..[end] against a PDF of [total] pages; null means valid.
PdfPageRangeError? validatePdfPageRange(
  int start,
  int end, {
  required int total,
  int max = PDFImportService.maxPageCount,
}) {
  if (start < 1) return PdfPageRangeError.startBelowOne;
  if (start > end) return PdfPageRangeError.startAfterEnd;
  if (end > total) return PdfPageRangeError.endAfterTotal;
  if (end - start + 1 > max) return PdfPageRangeError.tooLong;
  return null;
}

import 'pdf_import_service.dart';
import 'pdf_page_range.dart';

/// Imports a whole PDF; when it has too many pages, lets the user pick a
/// range and imports that instead.
///
/// [importWith] must use a fresh service per call. Returns the result, or
/// null when the user cancelled the range choice. Without [chooseRange] a
/// `tooManyPages` failure is returned as is.
Future<PDFImportServiceResult?> importPdfWithPageLimit({
  required Future<PDFImportServiceResult> Function(PDFImportConfig) importWith,
  ChoosePdfPageRange? chooseRange,
}) async {
  final first = await importWith(PDFImportConfig.all());
  final failure = first.failure;
  if (failure?.error != PdfImportError.tooManyPages || chooseRange == null) {
    return first;
  }
  final range = await chooseRange(failure!.pageCount, failure.maxPages);
  if (range == null) return null;
  return importWith(range.toConfig());
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:drawing_ui/src/services/pdf_import_service.dart';

/// Opens a file picker for PDF/image files, then converts the selected file
/// into one or more [Page] objects ready to insert into a document.
///
/// Returns an empty list if the user cancels or an error occurs. When some
/// PDF pages could not be read, [onPagesSkipped] gets their count.
Future<List<Page>> pickAndImportFile({
  required int insertIndex,
  required PageSize defaultPageSize,
  void Function(PdfImportFailure failure)? onError,
  void Function(int count)? onPagesSkipped,
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    withData: false,
  );
  if (result == null || result.files.isEmpty) return [];
  final filePath = result.files.first.path;
  if (filePath == null) return [];

  final ext = filePath.split('.').last.toLowerCase();
  if (ext == 'pdf') {
    return importPdfAsPages(
      filePath,
      insertIndex,
      onError: onError,
      onPagesSkipped: onPagesSkipped,
      createService: () => PDFImportService(pdfPaths: pdfPaths),
    );
  }
  return _importImage(filePath, insertIndex);
}

/// Imports the PDF at [path] as pages numbered from [insertIndex].
///
/// Failures go to [onError] and give an empty list. Pages that could not be
/// read are left out and their count goes to [onPagesSkipped].
Future<List<Page>> importPdfAsPages(
  String path,
  int insertIndex, {
  void Function(PdfImportFailure failure)? onError,
  void Function(int count)? onPagesSkipped,
  PDFImportService Function()? createService,
}) async {
  PDFImportService? svc;
  try {
    svc = createService?.call() ?? PDFImportService();
    final r = await svc.importFromFile(
      filePath: path,
      config: PDFImportConfig.all(),
    );
    if (!r.isSuccess || r.pages.isEmpty) {
      onError?.call(
        r.failure ?? const PdfImportFailure(PdfImportError.openFailed),
      );
      return [];
    }
    if (r.hasSkippedPages) onPagesSkipped?.call(r.skippedPages.length);
    return [
      for (int i = 0; i < r.pages.length; i++)
        r.pages[i].copyWith(index: insertIndex + i),
    ];
  } catch (e) {
    onError?.call(pdfImportFailureFor(e));
    return [];
  } finally {
    svc?.dispose();
  }
}

Future<List<Page>> _importImage(String path, int insertIndex) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/elyanotes_images');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}'
        '.${path.split('.').last}';
    await File(path).copy(dest);
    final bytes = await File(dest).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final w = frame.image.width.toDouble();
    final h = frame.image.height.toDouble();
    frame.image.dispose();
    return [
      Page.create(
        index: insertIndex,
        size: PageSize(width: w, height: h),
        background: PageBackground(
          type: BackgroundType.pdf,
          pdfData: bytes,
          pdfPageIndex: 1,
        ),
      ),
    ];
  } catch (_) {
    return [];
  }
}

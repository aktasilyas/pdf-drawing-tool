import 'package:drawing_core/drawing_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:drawing_ui/src/l10n/error_strings.dart';
import 'package:drawing_ui/src/services/image_page_import.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';

/// Signature of [pickAndImportFile], so tests can supply a fake importer.
typedef PageFileImporter = Future<List<Page>> Function({
  required int insertIndex,
  required PageSize defaultPageSize,
  void Function(PdfImportFailure failure)? onError,
  void Function(int count)? onPagesSkipped,
  void Function(ImagePageImportError error)? onImageError,
  PdfPathResolver pdfPaths,
});

/// Importer used by the "Add page" panel; [pickAndImportFile] by default.
final pageFileImporterProvider =
    Provider<PageFileImporter>((ref) => pickAndImportFile);

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
  void Function(ImagePageImportError error)? onImageError,
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
  return importImageAsPage(
    filePath,
    insertIndex,
    pdfPaths: pdfPaths,
    onImageError: onImageError,
  );
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

/// Imports the image at [path] as one page. Failures go to [onImageError]
/// and give an empty list; an image with an edge above [maxImagePageEdge] is
/// rejected as [ImagePageImportError.tooLarge]. [documentsRoot] defaults to
/// the app documents directory.
Future<List<Page>> importImageAsPage(
  String path,
  int insertIndex, {
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  void Function(ImagePageImportError error)? onImageError,
  String? documentsRoot,
}) async {
  try {
    final root =
        documentsRoot ?? (await getApplicationDocumentsDirectory()).path;
    final image = await importImagePage(
      path,
      documentsRoot: root,
      paths: pdfPaths,
      maxDimension: maxImagePageEdge,
    );
    return [
      Page.create(
        index: insertIndex,
        size: image.size,
        background: image.background,
      ),
    ];
  } on ImagePageImportException catch (e) {
    onImageError?.call(e.error);
    return [];
  } catch (_) {
    onImageError?.call(ImagePageImportError.unreadable);
    return [];
  }
}

/// Picks a camera or gallery photo for an image page, downscaled by the
/// picker so neither edge exceeds [maxImagePageEdge].
Future<XFile?> pickImagePagePhoto(ImagePicker picker, ImageSource source) =>
    picker.pickImage(
      source: source,
      maxWidth: maxImagePageEdge.toDouble(),
      maxHeight: maxImagePageEdge.toDouble(),
      imageQuality: 85,
    );

/// The message for a failed image page import.
String imagePageImportMessage(ErrorStrings strings, ImagePageImportError e) =>
    switch (e) {
      ImagePageImportError.tooLarge => strings.imageTooLarge,
      ImagePageImportError.unreadable => strings.imageReadFailed,
    };

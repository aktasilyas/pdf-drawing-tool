/// PDF export actions behind the export panel and page/document menus.
import 'dart:io';

import 'package:drawing_core/drawing_core.dart'
    show DrawingDocument, Page, PdfPathResolver;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/export_file_name.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/services/pdf_share_service.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';

/// Runs the full-document PDF export behind [ExportPanel] (tablet popover and
/// phone sheet). Replaced in tests to observe the export without file pickers.
class PDFExportRunner {
  const PDFExportRunner({
    this.shareService = const PdfShareService(),
    this.pdfPaths = PdfPathResolver.passthrough,
  });

  final PdfShareService shareService;
  final PdfPathResolver pdfPaths;

  Future<void> run(
    ExportProgressNotifier progress,
    DrawingDocument document, {
    required ExportStrings strings,
    bool addWatermark = false,
    bool share = false,
    ExportOptions options = const ExportOptions(),
    int currentPageIndex = 0,
  }) {
    return performPDFExport(
      progress,
      document,
      strings: strings,
      options: options,
      currentPageIndex: currentPageIndex,
      addWatermark: addWatermark,
      share: share,
      shareService: shareService,
      pdfPaths: pdfPaths,
    );
  }
}

/// The [PDFExportRunner] used by [ExportPanel].
final pdfExportRunnerProvider = Provider<PDFExportRunner>(
  (ref) => PDFExportRunner(
    shareService: ref.watch(pdfShareServiceProvider),
    pdfPaths: ref.watch(pdfPathResolverProvider),
  ),
);

/// Exports all pages of [document] to PDF using the floating progress overlay.
///
/// Shared by [ExportPanel] and `DocumentOptionsPanel`.
Future<void> performPDFExport(
  ExportProgressNotifier progress,
  DrawingDocument document, {
  required ExportStrings strings,
  bool isInfiniteCanvas = false,
  bool addWatermark = false,
  bool share = false,
  ExportOptions options = const ExportOptions(),
  int currentPageIndex = 0,
  PdfShareService shareService = const PdfShareService(),
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  @visibleForTesting PDFExporter? exporter,
}) {
  return performPagesPDFExport(
    progress,
    strings: strings,
    pages: options.select(document.pages, currentPageIndex),
    includeBackground: options.includeTemplate,
    title: document.title,
    isInfiniteCanvas: isInfiniteCanvas,
    addWatermark: addWatermark,
    share: share,
    shareService: shareService,
    pdfPaths: pdfPaths,
    exporter: exporter,
  );
}

/// Exports the given [pages] to PDF with [title] as filename base.
///
/// Used by [performPDFExport] for full-document export and by
/// `PageOptionsPanel` for single-page export.
Future<void> performPagesPDFExport(
  ExportProgressNotifier progress, {
  required ExportStrings strings,
  required List<Page> pages,
  required String title,
  bool isInfiniteCanvas = false,
  bool addWatermark = false,
  bool share = false,
  bool includeBackground = true,
  PdfShareService shareService = const PdfShareService(),
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  @visibleForTesting PDFExporter? exporter,
}) async {
  progress.start(pages.length);

  try {
    exporter ??= PDFExporter(pdfPaths: pdfPaths);
    final result = await exporter.exportPages(
      pages: pages,
      metadata: PDFDocumentMetadata(title: title),
      options: PDFExportOptions(
        isInfiniteCanvas: isInfiniteCanvas,
        addWatermark: addWatermark,
        includeBackground: includeBackground,
      ),
      onProgress: progress.updateProgress,
      isCancelled: () => progress.isCancelRequested,
    );

    if (result.wasCancelled) {
      progress.setCancelled();
      return;
    }

    if (!result.isSuccess) {
      progress.setError(result.failure ?? ExportFailure.failed);
      return;
    }

    // doc.save() already returns a Uint8List; only copy a foreign List<int>.
    final raw = result.pdfBytes;
    final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
    final filename = buildExportFilename(
      title,
      fallback: strings.fallbackFileName,
    );

    if (share) {
      final outcome =
          await shareService.sharePdf(bytes, fileName: '$filename.pdf');
      if (outcome == PdfShareOutcome.shared) {
        progress.complete(result.fileSizeFormatted);
      } else {
        progress.dismiss();
      }
      return;
    }

    // Let user pick save location
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: strings.savePdfDialog,
      fileName: '$filename.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );

    if (savedPath != null) {
      // Desktop: saveFile returns path but may not write bytes
      final file = File(savedPath);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
      progress.complete(result.fileSizeFormatted);
    } else {
      // User cancelled file picker
      progress.dismiss();
    }
  } catch (e) {
    DrawingLog.e('PDF export failed', e);
    progress.setError(exportFailureFor(e));
  }
}

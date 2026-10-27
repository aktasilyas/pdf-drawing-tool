/// Export options panel shown as a popover below the export toolbar button.
import 'dart:developer' as developer;
import 'dart:io';

import 'package:drawing_core/drawing_core.dart'
    show DrawingDocument, Page, PdfPathResolver;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/export_file_name.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/panels/png_export_action.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/services/pdf_share_service.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Export panel with PDF and PNG export options.
class ExportPanel extends ConsumerWidget {
  const ExportPanel({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isInfinite = ref.watch(isInfiniteCanvasProvider);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelHeader(cs: cs),
        if (isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.image,
            label: 'PNG Olarak Dışa Aktar',
            onTap: () => _exportPNG(context, ref),
          )
        else
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pdfFile,
            label: 'PDF Olarak Dışa Aktar',
            onTap: () => _exportPDF(context, ref),
          ),
        if (!isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.share,
            label: 'PDF Paylaş',
            onTap: () => _exportPDF(context, ref, share: true),
          ),
      ],
    );

    if (!embedded) {
      content = Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 260, child: content),
      );
    }
    return content;
  }

  void _exportPDF(BuildContext context, WidgetRef ref, {bool share = false}) {
    onClose();
    final document = ref.read(documentProvider);
    final notifier = ref.read(exportProgressProvider.notifier);
    final watermark = ref.read(exportWatermarkProvider);
    final runner = ref.read(pdfExportRunnerProvider);
    runner.run(notifier, document, addWatermark: watermark, share: share);
  }

  /// Renders the current page off-screen and saves it as PNG.
  void _exportPNG(BuildContext context, WidgetRef ref) {
    onClose();
    exportCurrentPageAsPNG(ref);
  }
}

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
    bool addWatermark = false,
    bool share = false,
  }) {
    return performPDFExport(
      progress,
      document,
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
  bool isInfiniteCanvas = false,
  bool addWatermark = false,
  bool share = false,
  PdfShareService shareService = const PdfShareService(),
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
}) {
  return performPagesPDFExport(
    progress,
    pages: document.pages,
    title: document.title,
    isInfiniteCanvas: isInfiniteCanvas,
    addWatermark: addWatermark,
    share: share,
    shareService: shareService,
    pdfPaths: pdfPaths,
  );
}

/// Exports the given [pages] to PDF with [title] as filename base.
///
/// Used by [performPDFExport] for full-document export and by
/// `PageOptionsPanel` for single-page export.
Future<void> performPagesPDFExport(
  ExportProgressNotifier progress, {
  required List<Page> pages,
  required String title,
  bool isInfiniteCanvas = false,
  bool addWatermark = false,
  bool share = false,
  PdfShareService shareService = const PdfShareService(),
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
}) async {
  progress.start(pages.length);

  try {
    final exporter = PDFExporter(pdfPaths: pdfPaths);
    final result = await exporter.exportPages(
      pages: pages,
      metadata: PDFDocumentMetadata(title: title),
      options: PDFExportOptions(
        isInfiniteCanvas: isInfiniteCanvas,
        addWatermark: addWatermark,
      ),
      onProgress: progress.updateProgress,
      isCancelled: () => progress.isCancelRequested,
    );

    if (result.wasCancelled) {
      progress.setCancelled();
      return;
    }

    if (!result.isSuccess) {
      progress.setError(result.errorMessage ?? 'PDF oluşturulamadı');
      return;
    }

    // doc.save() already returns a Uint8List; only copy a foreign List<int>.
    final raw = result.pdfBytes;
    final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
    final filename = buildExportFilename(title);

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
      dialogTitle: 'PDF Kaydet',
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
    developer.log('PDF export failed', name: _logName, error: e);
    progress.setError('PDF dışa aktarılamadı: $e');
  }
}

const _logName = 'drawing_ui.export';

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Dışa Aktar',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ),
    );
  }
}

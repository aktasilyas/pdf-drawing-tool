/// PNG export of the current page.
library;

import 'dart:io';

import 'package:drawing_core/drawing_core.dart' show Page, PdfPathResolver;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/export_file_name.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:drawing_ui/src/services/page_png_exporter.dart';
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';

/// Signature of [PagePngExporter.export]; replaced in tests.
typedef PngExportRenderer = Future<PageRasterPng> Function(
  Page page, {
  required bool infiniteCanvas,
  PdfPathResolver pdfPaths,
});

/// Exports the current page of the open document as PNG (see
/// [performPNGExport]).
void exportCurrentPageAsPNG(
  WidgetRef ref, {
  required ExportStrings strings,
}) {
  final document = ref.read(documentProvider);
  final page = document.currentPage;
  final progress = ref.read(exportProgressProvider.notifier);
  // Never overwrite the state of an export that is still running (#491).
  // Silent here: UI callers show the message via rejectIfExportRunning.
  if (progress.isBusy) return;
  if (page == null) {
    progress.setError(ExportFailure.noPages);
    return;
  }
  performPNGExport(
    progress,
    page,
    strings: strings,
    title: document.title,
    infiniteCanvas: ref.read(isInfiniteCanvasProvider),
    pdfPaths: ref.read(pdfPathResolverProvider),
  );
}

/// Renders [page] off-screen with [PagePngExporter] (independent of zoom,
/// pan and overlays) and saves it as PNG.
Future<void> performPNGExport(
  ExportProgressNotifier progress,
  Page page, {
  required ExportStrings strings,
  required String title,
  required bool infiniteCanvas,
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  PngExportRenderer render = PagePngExporter.export,
}) async {
  // One export at a time (#491).
  if (!progress.tryBegin(1)) return;

  try {
    final rendered = await render(
      page,
      infiniteCanvas: infiniteCanvas,
      pdfPaths: pdfPaths,
    );
    final bytes = rendered.bytes;
    final filename = buildExportFilename(
      title,
      fallback: strings.fallbackFileName,
    );

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: strings.savePngDialog,
      fileName: '$filename.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
      bytes: bytes,
    );

    if (savedPath != null) {
      final file = File(savedPath);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
      final sizeMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      progress.complete(
        '$sizeMB MB',
        pagesMissingBackground: rendered.pdfBackgroundMissing ? 1 : 0,
      );
    } else {
      progress.dismiss();
    }
  } catch (e) {
    DrawingLog.e('PNG export failed', e);
    progress.setError(exportFailureFor(e));
  } finally {
    progress.end();
  }
}

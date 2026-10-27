/// PNG export of the current page.
library;

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show Page, PdfPathResolver;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/export_file_name.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/page_png_exporter.dart';

const _logName = 'drawing_ui.export';

/// Exports the current page of the open document as PNG (see
/// [performPNGExport]).
void exportCurrentPageAsPNG(WidgetRef ref) {
  final document = ref.read(documentProvider);
  final page = document.currentPage;
  final progress = ref.read(exportProgressProvider.notifier);
  if (page == null) {
    progress.setError('Dışa aktarılacak sayfa yok');
    return;
  }
  performPNGExport(
    progress,
    page,
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
  required String title,
  required bool infiniteCanvas,
  PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  PngExportRenderer render = PagePngExporter.export,
}) async {
  progress.start(1);

  try {
    final bytes = await render(
      page,
      infiniteCanvas: infiniteCanvas,
      pdfPaths: pdfPaths,
    );
    final filename = buildExportFilename(title);

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'PNG Kaydet',
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
      progress.complete('$sizeMB MB');
    } else {
      progress.dismiss();
    }
  } catch (e) {
    developer.log('PNG export failed', name: _logName, error: e);
    progress.setError('PNG dışa aktarılamadı: $e');
  }
}

/// Signature of [PagePngExporter.export]; replaced in tests.
typedef PngExportRenderer = Future<Uint8List> Function(
  Page page, {
  required bool infiniteCanvas,
  PdfPathResolver pdfPaths,
});

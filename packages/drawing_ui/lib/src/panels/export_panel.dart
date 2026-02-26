/// Export options panel shown as a popover below the export toolbar button.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart' show DrawingDocument, Page;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Export panel with PDF and PNG export options.
class ExportPanel extends ConsumerWidget {
  const ExportPanel({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelHeader(cs: cs),
        // TODO: PDF export disabled — re-enable after fixing infinite mode rendering
        // _ExportOption(
        //   icon: StarNoteIcons.pdfFile,
        //   label: 'PDF Olarak Dışa Aktar',
        //   cs: cs,
        //   onTap: () => _exportPDF(context, ref),
        // ),
        _ExportOption(
          icon: StarNoteIcons.image,
          label: 'PNG Olarak Dışa Aktar',
          cs: cs,
          onTap: () => _exportPNG(context, ref),
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

  // TODO: Re-enable after fixing PDF export for infinite mode
  // void _exportPDF(BuildContext context, WidgetRef ref) {
  //   onClose();
  //   final document = ref.read(documentProvider);
  //   final notifier = ref.read(exportProgressProvider.notifier);
  //   final isInfinite = ref.read(isInfiniteCanvasProvider);
  //   performPDFExport(notifier, document, isInfiniteCanvas: isInfinite);
  // }

  /// Captures canvas screenshot and saves as PNG.
  void _exportPNG(BuildContext context, WidgetRef ref) {
    onClose();
    final document = ref.read(documentProvider);
    final notifier = ref.read(exportProgressProvider.notifier);
    final boundaryKey = ref.read(canvasBoundaryKeyProvider);
    performPNGExport(notifier, boundaryKey, title: document.title);
  }
}

/// Exports all pages of [document] to PDF using the floating progress overlay.
///
/// Shared by [ExportPanel] and `DocumentOptionsPanel`.
Future<void> performPDFExport(
  ExportProgressNotifier progress,
  DrawingDocument document, {
  bool isInfiniteCanvas = false,
}) {
  return performPagesPDFExport(
    progress,
    pages: document.pages,
    title: document.title,
    isInfiniteCanvas: isInfiniteCanvas,
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
}) async {
  progress.start(pages.length);

  try {
    final exporter = PDFExporter();
    final result = await exporter.exportPages(
      pages: pages,
      metadata: PDFDocumentMetadata(title: title),
      options: PDFExportOptions(isInfiniteCanvas: isInfiniteCanvas),
      onProgress: progress.updateProgress,
    );

    if (!result.isSuccess) {
      progress.setError(result.errorMessage ?? 'PDF oluşturulamadı');
      return;
    }

    final bytes = Uint8List.fromList(result.pdfBytes);
    final filename = _buildExportFilename(title);

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
    debugPrint('PDF export error: $e');
    progress.setError('PDF dışa aktarılamadı: $e');
  }
}

/// Captures the canvas via RepaintBoundary and saves as PNG.
Future<void> performPNGExport(
  ExportProgressNotifier progress,
  GlobalKey boundaryKey, {
  required String title,
}) async {
  progress.start(1);

  try {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      progress.setError('Tuval yakalanamadı');
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      progress.setError('Görüntü oluşturulamadı');
      return;
    }

    final bytes = byteData.buffer.asUint8List();
    final filename = _buildExportFilename(title);

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

    progress.updateProgress(1, 1);
  } catch (e) {
    debugPrint('PNG export error: $e');
    progress.setError('PNG dışa aktarılamadı: $e');
  }
}

/// Builds an export filename with title + date/time stamp.
String _buildExportFilename(String title) {
  final base = sanitizeFilename(title);
  final now = DateTime.now();
  final stamp = '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  return '${base}_$stamp';
}

/// Sanitizes a string for use as a filename.
String sanitizeFilename(String title) {
  var name = title.isEmpty ? 'doküman' : title;
  name = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
  if (name.length > 200) name = name.substring(0, 200);
  return name;
}

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
        child: Text('Dışa Aktar', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon, required this.label,
    required this.cs, required this.onTap,
  });
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            PhosphorIcon(icon, size: 20, color: cs.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(
                fontSize: 14, color: cs.onSurface))),
          ]),
        ),
      ),
    );
  }
}

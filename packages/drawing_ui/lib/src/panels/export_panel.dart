/// Export options panel shown as a popover below the export toolbar button.
import 'dart:io';

import 'package:drawing_core/drawing_core.dart' show DrawingDocument;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Export panel with PDF export option.
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
        _ExportOption(
          icon: StarNoteIcons.pdfFile,
          label: 'PDF Olarak Dışa Aktar',
          cs: cs,
          onTap: () => _exportPDF(context, ref),
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

  /// Directly exports all pages to PDF — no dialog.
  void _exportPDF(BuildContext context, WidgetRef ref) {
    onClose();
    final document = ref.read(documentProvider);
    final notifier = ref.read(exportProgressProvider.notifier);
    performPDFExport(notifier, document);
  }
}

/// Exports all pages of [document] to PDF using the floating progress overlay.
///
/// Shared by [ExportPanel] and `DocumentOptionsPanel`.
Future<void> performPDFExport(
  ExportProgressNotifier progress,
  DrawingDocument document,
) async {
  progress.start(document.pages.length);

  try {
    final exporter = PDFExporter();
    final result = await exporter.exportPages(
      pages: document.pages,
      metadata: PDFDocumentMetadata(title: document.title),
      onProgress: progress.updateProgress,
    );

    if (!result.isSuccess) {
      progress.setError(result.errorMessage ?? 'PDF oluşturulamadı');
      return;
    }

    final bytes = Uint8List.fromList(result.pdfBytes);
    final filename = _sanitizeFilename(document.title);

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

String _sanitizeFilename(String title) {
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

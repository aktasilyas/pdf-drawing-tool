import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/pdf_import_dialog.dart';
import 'package:drawing_ui/src/widgets/pdf_export_dialog.dart';

/// Shows export/share bottom sheet menu.
///
/// Options: PDF export, image export (future), share (future).
void showExportMenu(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.exportIcon,
              color: colorScheme.onSurface,
            ),
            title: const Text('PDF İçe Aktar'),
            onTap: () {
              Navigator.pop(ctx);
              _showPDFImportDialog(context, ref);
            },
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.pdfFile,
              color: colorScheme.onSurface,
            ),
            title: const Text('PDF Olarak Dışa Aktar'),
            onTap: () {
              Navigator.pop(ctx);
              _showPDFExportDialog(context, ref);
            },
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.image,
              color: colorScheme.onSurface,
              size: StarNoteIcons.navSize,
            ),
            title: const Text('Resim Olarak Dışa Aktar'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.share,
              color: colorScheme.onSurface,
              size: StarNoteIcons.navSize,
            ),
            title: const Text('Paylaş'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Shows "more" bottom sheet menu.
///
/// Options: template, page settings, document settings.
void showMoreMenu(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.template,
              color: colorScheme.onSurface,
            ),
            title: const Text('Şablon Değiştir'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.page,
              color: colorScheme.onSurface,
            ),
            title: const Text('Sayfa Ayarları'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.sliders,
              color: colorScheme.onSurface,
            ),
            title: const Text('Belge Ayarları'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Private helpers ──

void _showPDFImportDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) => PDFImportDialog(
      onImportComplete: (result) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.pageCount} sayfa içe aktarıldı'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
  );
}

void _showPDFExportDialog(BuildContext context, WidgetRef ref) {
  final pageCount = ref.read(pageCountProvider);

  showDialog<void>(
    context: context,
    builder: (context) => PDFExportDialog(
      totalPages: pageCount,
      onExport: (config) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF dışa aktarılıyor...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ),
  );
}

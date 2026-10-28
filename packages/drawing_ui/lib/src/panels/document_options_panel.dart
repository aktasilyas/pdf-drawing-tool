/// Document options popover panel — Rename, PDF Export, Delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/pdf_export_action.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/panels/png_export_action.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Popover menu for document-level actions (rename, export, trash).
class DocumentOptionsPanel extends ConsumerWidget {
  const DocumentOptionsPanel({
    super.key,
    required this.onRename,
    required this.onDelete,
    required this.onClose,
  });

  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final isInfinite = ref.watch(isInfiniteCanvasProvider);
    final s = context.drawingStrings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PageOptionsMenuItem(
          icon: ElyanotesIcons.editPencil,
          label: s.pages.rename,
          onTap: () {
            onClose();
            onRename();
          },
        ),
        if (isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.image,
            label: s.export.exportPng,
            onTap: () {
              onClose();
              exportCurrentPageAsPNG(ref, strings: s.export);
            },
          )
        else
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pdfFile,
            label: s.export.exportPdf,
            onTap: () {
              onClose();
              final document = ref.read(documentProvider);
              final notifier = ref.read(exportProgressProvider.notifier);
              performPDFExport(
                notifier,
                document,
                strings: s.export,
                isInfiniteCanvas: ref.read(isInfiniteCanvasProvider),
                pdfPaths: ref.read(pdfPathResolverProvider),
              );
            },
          ),
        pageOptionsDivider(cs),
        PageOptionsMenuItem(
          icon: ElyanotesIcons.trash,
          label: s.pages.moveDocumentToTrash,
          isDestructive: true,
          onTap: () {
            onClose();
            onDelete();
          },
        ),
      ],
    );
  }
}

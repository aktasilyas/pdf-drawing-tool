/// Document options popover panel — Rename, PDF Export, Delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PageOptionsMenuItem(
          icon: ElyanotesIcons.editPencil,
          label: 'Yeniden Adlandır',
          onTap: () { onClose(); onRename(); },
        ),
        if (isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.image,
            label: 'PNG Olarak Dışa Aktar',
            onTap: () {
              onClose();
              final document = ref.read(documentProvider);
              final notifier = ref.read(exportProgressProvider.notifier);
              final boundaryKey = ref.read(canvasBoundaryKeyProvider);
              performPNGExport(notifier, boundaryKey, title: document.title);
            },
          )
        else
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pdfFile,
            label: 'PDF Olarak Dışa Aktar',
            onTap: () {
              onClose();
              final document = ref.read(documentProvider);
              final notifier = ref.read(exportProgressProvider.notifier);
              performPDFExport(notifier, document);
            },
          ),
        pageOptionsDivider(cs),
        PageOptionsMenuItem(
          icon: ElyanotesIcons.trash,
          label: 'Çöpe Taşı',
          isDestructive: true,
          onTap: () { onClose(); onDelete(); },
        ),
      ],
    );
  }
}


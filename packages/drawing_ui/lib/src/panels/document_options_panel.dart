/// Document options popover panel — Rename, PDF Export, Delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/panels/export_panel.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OptionTile(
          icon: StarNoteIcons.editPencil,
          label: 'Yeniden Adlandır',
          color: cs.onSurface,
          onTap: () { onClose(); onRename(); },
        ),
        // TODO: PDF export disabled — re-enable after fixing infinite mode rendering
        // _OptionTile(
        //   icon: StarNoteIcons.pdfFile,
        //   label: 'PDF Olarak Dışa Aktar',
        //   color: cs.onSurface,
        //   onTap: () {
        //     onClose();
        //     final document = ref.read(documentProvider);
        //     final notifier = ref.read(exportProgressProvider.notifier);
        //     final isInfinite = ref.read(isInfiniteCanvasProvider);
        //     performPDFExport(notifier, document,
        //         isInfiniteCanvas: isInfinite);
        //   },
        // ),
        _OptionTile(
          icon: StarNoteIcons.image,
          label: 'PNG Olarak Dışa Aktar',
          color: cs.onSurface,
          onTap: () {
            onClose();
            final document = ref.read(documentProvider);
            final notifier = ref.read(exportProgressProvider.notifier);
            final boundaryKey = ref.read(canvasBoundaryKeyProvider);
            performPNGExport(notifier, boundaryKey, title: document.title);
          },
        ),
        Divider(height: 1, indent: 16, endIndent: 16,
            color: cs.outlineVariant.withValues(alpha: 0.5)),
        _OptionTile(
          icon: StarNoteIcons.trash,
          label: 'Çöpe Taşı',
          color: cs.error,
          onTap: () { onClose(); onDelete(); },
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
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
            PhosphorIcon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
                style: GoogleFonts.sourceSerif4(fontSize: 14, color: color))),
          ]),
        ),
      ),
    );
  }
}

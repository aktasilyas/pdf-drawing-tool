import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Settings panel for the sticky note tool.
///
/// Displays a single button to add a sticky note to the canvas center.
class StickyNotePanel extends ConsumerWidget {
  const StickyNotePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yapışkan Not',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _addStickyNote(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFFF3CD).withValues(alpha: 0.8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(StarNoteIcons.stickyNote,
                        size: 22, color: const Color(0xFFD4A017)),
                    const SizedBox(height: 4),
                    const Text(
                      'Not Ekle',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD4A017),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addStickyNote(BuildContext context, WidgetRef ref) {
    final page = ref.read(currentPageProvider);
    final transform = ref.read(canvasTransformProvider);

    // Place at visible center of the viewport
    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportSize = renderBox?.size ?? const Size(400, 600);
    final center = transform.screenToCanvas(
      Offset(viewportSize.width / 2, viewportSize.height / 2),
    );

    const noteWidth = 200.0;
    const noteHeight = 200.0;

    // Clamp to page bounds
    final maxX = (page.size.width - noteWidth).clamp(0.0, page.size.width);
    final maxY = (page.size.height - noteHeight).clamp(0.0, page.size.height);
    final clampedX = (center.dx - noteWidth / 2).clamp(0.0, maxX);
    final clampedY = (center.dy - noteHeight / 2).clamp(0.0, maxY);

    final stickyNote = StickyNote.create(
      x: clampedX,
      y: clampedY,
      width: noteWidth,
      height: noteHeight,
    );

    final document = ref.read(documentProvider);
    final command = AddStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      stickyNote: stickyNote,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Close the panel
    ref.read(activePanelProvider.notifier).state = null;
  }
}

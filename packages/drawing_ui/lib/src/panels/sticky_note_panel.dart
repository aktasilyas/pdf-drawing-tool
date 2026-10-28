import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/theme/theme.dart';

// content: mirrors the StickyNote default colour (document ink, not chrome).
const Color _kDefaultNoteColor = Color(0xFFFFF3CD);

/// Settings panel for the sticky note tool.
///
/// Displays a single button to add a sticky note to the canvas center.
class StickyNotePanel extends ConsumerWidget {
  const StickyNotePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChromePalette.of(context);
    final str = context.drawingStrings;
    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: str.tools.stickyNote,
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          Semantics(
            button: true,
            label: str.panels.addNote,
            excludeSemantics: true,
            onTap: () => _addStickyNote(context, ref),
            child: GestureDetector(
              key: const ValueKey('sticky-note-add'),
              onTap: () => _addStickyNote(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: ChromeSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChromeRadius.lg),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _kDefaultNoteColor,
                        borderRadius: BorderRadius.circular(ChromeRadius.sm),
                        border: Border.all(color: palette.border),
                      ),
                    ),
                    const SizedBox(width: ChromeSpacing.sm),
                    Text(
                      str.panels.addNote,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: palette.textPrimary,
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

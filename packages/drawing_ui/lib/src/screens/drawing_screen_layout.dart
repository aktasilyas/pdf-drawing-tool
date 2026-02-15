/// Layout builders and helpers for the drawing screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/canvas/canvas.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/infinite_background_painter.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

/// Build the canvas area with all layers.
Widget buildDrawingCanvasArea({
  required BuildContext context,
  required WidgetRef ref,
  required core.Page currentPage,
  required CanvasTransform transform,
  required core.CanvasMode? canvasMode,
  required Offset penBoxPosition,
  required ValueChanged<Offset> onPenBoxPositionChanged,
  required VoidCallback onClosePanel,
  required VoidCallback onOpenAIPanel,
  CanvasColorScheme? colorScheme,
  bool isReadOnly = false,
}) {
  const double swipeVelocityThreshold = 300;
  final canvasStack = ClipRect(
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: InfiniteBackgroundPainter(
                background: currentPage.background,
                zoom: transform.zoom,
                offset: transform.offset,
                colorScheme: colorScheme,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        Positioned.fill(
          child: DrawingCanvas(
            canvasMode: canvasMode,
            isReadOnly: isReadOnly,
          ),
        ),
        // Always present to prevent Stack position shifting when
        // activePanelProvider toggles between tool and null.
        if (!isReadOnly)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: ref.watch(activePanelProvider) == null,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onClosePanel,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        if (!isReadOnly)
          Positioned(
            left: penBoxPosition.dx,
            top: penBoxPosition.dy,
            child: FloatingPenBox(
              position: penBoxPosition,
              onPositionChanged: (delta) {
                final newPosition = penBoxPosition + delta;
                final clampedPosition = Offset(
                  newPosition.dx.clamp(0, MediaQuery.of(context).size.width - 60),
                  newPosition.dy.clamp(0, MediaQuery.of(context).size.height - 200),
                );
                onPenBoxPositionChanged(clampedPosition);
              },
            ),
          ),
        if (!isReadOnly) const FloatingUndoRedo(),
        if (!isReadOnly) const FloatingQuickColors(),
        if (!isReadOnly)
          Positioned(right: 16, bottom: 16, child: AskAIButton(onTap: onOpenAIPanel)),
        if (ref.watch(isZoomingProvider))
          Positioned.fill(
            child: Center(
              key: const ValueKey('zoom-indicator'),
              child: ZoomIndicator(zoomPercentage: ref.watch(zoomPercentageProvider)),
            ),
          ),
        // Floating page indicator bar
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PageIndicatorBar(),
        ),
      ],
    ),
  );

  // In reader mode, wrap with horizontal swipe for page navigation
  if (isReadOnly) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -swipeVelocityThreshold) {
          ref.read(pageManagerProvider.notifier).nextPage();
        } else if (velocity > swipeVelocityThreshold) {
          ref.read(pageManagerProvider.notifier).previousPage();
        }
      },
      child: canvasStack,
    );
  }

  return canvasStack;
}

/// Build the page navigator sidebar.
Widget buildPageSidebar({required BuildContext context, required WidgetRef ref, required ThumbnailCache thumbnailCache}) {
  final pageManager = ref.watch(pageManagerProvider);
  final pageCount = ref.watch(pageCountProvider);
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: 140,
    constraints: const BoxConstraints(minWidth: 100),
    decoration: BoxDecoration(
      color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
      border: Border(right: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
    ),
    child: Column(children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 16),
          itemCount: pageCount,
          itemBuilder: (context, index) => _buildThumbnailItem(context, ref, pageManager, thumbnailCache, index, colorScheme, isDark),
        ),
      ),
      _buildAddPageButton(context, ref),
    ]),
  );
}

/// Build a single thumbnail item.
Widget _buildThumbnailItem(BuildContext context, WidgetRef ref, dynamic pageManager,
    ThumbnailCache thumbnailCache, int index, ColorScheme cs, bool isDark) {
  final page = pageManager.pages[index];
  final sel = index == pageManager.currentIndex;
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: GestureDetector(
      onTap: () {
        ref.read(pageManagerProvider.notifier).goToPage(index);
        final doc = ref.read(documentProvider);
        if (doc.isMultiPage && doc.currentPageIndex != index) {
          ref.read(documentProvider.notifier).updateDocument(doc.setCurrentPage(index));
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 152,
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainer : cs.surface, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: sel ? 0.12 : 0.06), blurRadius: sel ? 8 : 4, offset: Offset(0, sel ? 2 : 1))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(7),
            child: PageThumbnail(page: page, cache: thumbnailCache, width: 116, height: 152, isSelected: sel, showPageNumber: false)),
        ),
        const SizedBox(height: 6),
        Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
            color: sel ? cs.primary : cs.onSurfaceVariant, letterSpacing: -0.2)),
      ]),
    ),
  );
}

/// Build add page button.
Widget _buildAddPageButton(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return LayoutBuilder(builder: (context, constraints) {
    final w = constraints.maxWidth;
    if (w < 30) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5))),
      child: GestureDetector(
        onTap: () => ref.read(pageManagerProvider.notifier).addPage(),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: w < 80 ? 2.0 : 8.0),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Center(child: PhosphorIcon(StarNoteIcons.plus, size: w < 50 ? 16 : 20, color: colorScheme.primary)),
        ),
      ),
    );
  });
}

/// Floating AI button.
class AskAIButton extends StatelessWidget {
  const AskAIButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 80.0 / 255.0), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: PhosphorIcon(StarNoteIcons.sparkle, color: cs.onPrimary, size: 24),
      ),
    );
  }
}

/// Zoom indicator shown in center while zooming.
class ZoomIndicator extends StatelessWidget {
  const ZoomIndicator({super.key, required this.zoomPercentage});
  final String zoomPercentage;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(zoomPercentage, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 1)),
    ),
  );
}

/// Handle panel state changes - show/hide overlay.
void handlePanelChange({
  required BuildContext context,
  required ToolType? panel,
  required PopoverController panelController,
  required Map<ToolType, GlobalKey> toolButtonKeys,
  required GlobalKey penGroupButtonKey,
  required GlobalKey highlighterGroupButtonKey,
  required GlobalKey settingsButtonKey,
  required VoidCallback onClosePanel,
  bool isPenPickerMode = false,
  ValueChanged<ToolType>? onPenSelected,
}) {
  final w = MediaQuery.of(context).size.width;
  if (w < ToolbarLayoutMode.compactBreakpoint) return;
  if (panel == null) {
    panelController.hide();
  } else if (panel != ToolType.panZoom) {
    final anchorKey = panel == ToolType.toolbarSettings
        ? settingsButtonKey
        : penToolsSet.contains(panel)
            ? penGroupButtonKey
            : highlighterToolsSet.contains(panel)
                ? highlighterGroupButtonKey
                : toolButtonKeys[panel] ?? GlobalKey();
    final isPicker = isPenPickerMode && penToolsSet.contains(panel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      panelController.show(
        context: context,
        anchorKey: anchorKey,
        onDismiss: onClosePanel,
        maxWidth: isPicker ? 300 : 380,
        child: buildActivePanel(
          panel: panel,
          isPenPickerMode: isPenPickerMode,
          onPenSelected: onPenSelected,
        ),
      );
    });
  }
}

/// Open AI panel as bottom sheet.
void openAIPanel(BuildContext context) {
  final surface = Theme.of(context).colorScheme.surface;
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
      builder: (_, __) => Container(
        decoration: BoxDecoration(color: surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: const AIAssistantPanel(),
      ),
    ),
  );
}

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
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

export 'page_sidebar.dart' show PageSidebar, kPageSidebarWidth;

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
  GlobalKey<PageSlideTransitionState>? pageTransitionKey,
  ValueChanged<int>? onPageChanged,
  CanvasColorScheme? colorScheme,
  bool isReadOnly = false,
  Axis scrollDirection = Axis.horizontal,
  bool isDualPage = false,
  core.Page? secondaryPage,
}) {
  const double swipeVelocityThreshold = 300;

  // Core canvas content: background + drawing canvas (wrapped in transition)
  Widget canvasContent = Stack(
    children: [
      Positioned.fill(child: RepaintBoundary(child: CustomPaint(
        painter: InfiniteBackgroundPainter(background: currentPage.background,
            zoom: transform.zoom, offset: transform.offset, colorScheme: colorScheme),
        size: Size.infinite))),
      Positioned.fill(child: DrawingCanvas(
        canvasMode: canvasMode,
        isReadOnly: isReadOnly,
        onPageSwipe: isReadOnly ? null : (direction) {
          final idx = ref.read(currentPageIndexProvider);
          final count = ref.read(pageCountProvider);
          final target = idx + direction;
          if (target >= 0 && target < count) {
            (onPageChanged ?? (_) {})(target);
          }
        },
      )),
    ],
  );

  if (pageTransitionKey != null) {
    canvasContent = PageSlideTransition(
      key: pageTransitionKey,
      scrollDirection: scrollDirection,
      child: canvasContent,
    );
  }

  final canvasStack = ClipRect(
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: canvasContent),
        if (!isReadOnly)
          Positioned.fill(child: IgnorePointer(
            ignoring: ref.watch(activePanelProvider) == null,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onClosePanel,
                child: const SizedBox.expand()),
          )),
        if (!isReadOnly)
          Positioned(left: penBoxPosition.dx, top: penBoxPosition.dy, child: FloatingPenBox(
            position: penBoxPosition,
            onPositionChanged: (delta) {
              final p = penBoxPosition + delta;
              onPenBoxPositionChanged(Offset(
                p.dx.clamp(0, MediaQuery.of(context).size.width - 60),
                p.dy.clamp(0, MediaQuery.of(context).size.height - 200)));
            },
          )),
        if (!isReadOnly) const FloatingUndoRedo(),
        if (!isReadOnly) const FloatingRecordingBar(),
        if (!isReadOnly)
          Positioned(right: 16, bottom: 16, child: AskAIButton(onTap: onOpenAIPanel)),
        if (!isReadOnly && canvasMode != null && !canvasMode.isInfinite)
          const Positioned.fill(child: Center(child: ZoomControlBar()))
        else if (ref.watch(isZoomingProvider))
          Positioned.fill(
            child: Center(
              key: const ValueKey('zoom-indicator'),
              child: ZoomIndicator(zoomPercentage: ref.watch(zoomPercentageProvider)),
            ),
          ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: PageIndicatorBar(onPageChanged: onPageChanged),
        ),
      ],
    ),
  );

  if (isReadOnly) {
    void handleSwipe(DragEndDetails details) {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity < -swipeVelocityThreshold) {
        final idx = ref.read(currentPageIndexProvider);
        final count = ref.read(pageCountProvider);
        if (idx < count - 1) {
          (onPageChanged ?? (_) => ref.read(pageManagerProvider.notifier).nextPage())(idx + 1);
        }
      } else if (velocity > swipeVelocityThreshold) {
        final idx = ref.read(currentPageIndexProvider);
        if (idx > 0) {
          (onPageChanged ?? (_) => ref.read(pageManagerProvider.notifier).previousPage())(idx - 1);
        }
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: scrollDirection == Axis.horizontal ? handleSwipe : null,
      onVerticalDragEnd: scrollDirection == Axis.vertical ? handleSwipe : null,
      child: canvasStack,
    );
  }

  return canvasStack;
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

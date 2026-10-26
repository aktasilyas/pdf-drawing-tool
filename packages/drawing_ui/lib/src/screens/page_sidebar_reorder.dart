/// Long-press drag reordering for page sidebar cells
/// (docs/plans/156-page-reorder-undo.md, section 3 "Drag UX").
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';

/// Opacity of the source cell while its thumbnail is being dragged.
const double kReorderSourceOpacity = 0.4;

/// Half-size of the pointer rect used to trigger edge auto-scroll.
const double _autoScrollProbe = ChromeSpacing.sm;

/// Scroll speed (logical px/s scale) of the edge auto-scroller during a drag.
const double _autoScrollVelocityScalar = 48;

/// Wraps a page cell so it can be long-press dragged onto another cell.
///
/// Dropping on a cell takes that cell's slot: [onMove] gets
/// `(fromIndex, toIndex)` with `List.removeAt` + `insert` semantics. The
/// enclosing [Scrollable] auto-scrolls while the pointer is near its edge.
class ReorderablePageCell extends StatefulWidget {
  const ReorderablePageCell({
    super.key,
    required this.index,
    required this.onMove,
    required this.child,
  });

  /// Page index of this cell (the drag payload and drop slot).
  final int index;

  /// Called when another cell is dropped on this one.
  final void Function(int from, int to) onMove;

  final Widget child;

  @override
  State<ReorderablePageCell> createState() => _ReorderablePageCellState();
}

class _ReorderablePageCellState extends State<ReorderablePageCell> {
  EdgeDraggingAutoScroller? _autoScroller;

  void _onDragStarted() {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    _autoScroller = EdgeDraggingAutoScroller(
      scrollable,
      velocityScalar: _autoScrollVelocityScalar,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final scroller = _autoScroller;
    if (scroller == null) return;
    final p = details.globalPosition;
    scroller.startAutoScrollIfNecessary(
      Rect.fromCenter(
        center: p,
        width: _autoScrollProbe * 2,
        height: _autoScrollProbe * 2,
      ),
    );
  }

  void _stopAutoScroll() {
    _autoScroller?.stopAutoScroll();
    _autoScroller = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != widget.index,
      onAcceptWithDetails: (d) => widget.onMove(d.data, widget.index),
      builder: (context, candidates, _) {
        final hovered = candidates.isNotEmpty;
        return LayoutBuilder(
          builder: (context, constraints) => LongPressDraggable<int>(
            data: widget.index,
            hapticFeedbackOnStart: true,
            onDragStarted: _onDragStarted,
            onDragUpdate: _onDragUpdate,
            onDragEnd: (_) => _stopAutoScroll(),
            onDraggableCanceled: (_, __) => _stopAutoScroll(),
            feedback: _Lifted(
              size: constraints.biggest,
              child: widget.child,
            ),
            childWhenDragging: Opacity(
              opacity: kReorderSourceOpacity,
              child: widget.child,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (hovered)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ChromeRadius.lg),
                        border: Border.all(
                          color: palette.accent,
                          width: ChromeSpacing.xxs,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Drag feedback: the cell at its own size with the chrome shadow.
class _Lifted extends StatelessWidget {
  const _Lifted({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: SizedBox.fromSize(
          size: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChromeRadius.lg),
              boxShadow: DrawingShadows.chrome(Theme.of(context).brightness),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

enum _DragMode { move, rotate }

/// Widget that handles selection interactions: live move, rotate, and tap.
///
/// Placed inside the Transform stack (canvas coordinates).
/// - Drag inside selection → live move (strokes follow finger).
/// - Drag rotation handle → live rotate.
/// - Tap inside → show context menu.
/// - Tap outside → clear selection.
class SelectionHandles extends ConsumerStatefulWidget {
  final Selection selection;
  final VoidCallback? onSelectionChanged;

  const SelectionHandles({
    super.key,
    required this.selection,
    this.onSelectionChanged,
  });

  @override
  ConsumerState<SelectionHandles> createState() => _SelectionHandlesState();
}

class _SelectionHandlesState extends ConsumerState<SelectionHandles> {
  _DragMode? _dragMode;
  Offset? _dragStart;
  BoundingBox? _originalBounds;

  static const double _hitRadius = 20.0;
  static const double _rotHandleDist = 30.0;

  @override
  Widget build(BuildContext context) {
    final selectionUi = ref.watch(selectionUiProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _SelectionHandlesPainter(
          bounds: widget.selection.bounds,
          moveDelta: selectionUi.moveDelta,
          rotation: selectionUi.rotation,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Coordinate helpers ──

  Offset _rotHandlePos(BoundingBox b) {
    final cx = (b.left + b.right) / 2;
    return Offset(cx, b.top - _rotHandleDist);
  }

  bool _isInsideBounds(Offset pt, BoundingBox b) {
    return pt.dx >= b.left &&
        pt.dx <= b.right &&
        pt.dy >= b.top &&
        pt.dy <= b.bottom;
  }

  // ── Tap handler ──

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final bounds = widget.selection.bounds;

    // Tap on rotation handle → ignore (drag intent)
    if ((pos - _rotHandlePos(bounds)).distance <= _hitRadius) return;

    // Tap inside body → show context menu
    if (_isInsideBounds(pos, bounds)) {
      ref.read(selectionUiProvider.notifier).showContextMenu();
      return;
    }

    // Outside → clear selection
    ref.read(selectionUiProvider.notifier).reset();
    ref.read(selectionProvider.notifier).clearSelection();
    widget.onSelectionChanged?.call();
  }

  // ── Pan handlers ──

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final bounds = widget.selection.bounds;

    // Hide menu on any drag
    ref.read(selectionUiProvider.notifier).hideContextMenu();

    // Rotation handle
    if ((pos - _rotHandlePos(bounds)).distance <= _hitRadius) {
      _dragMode = _DragMode.rotate;
      _dragStart = pos;
      _originalBounds = bounds;
      return;
    }

    // Inside body → move
    if (_isInsideBounds(pos, bounds)) {
      _dragMode = _DragMode.move;
      _dragStart = pos;
      _originalBounds = bounds;
      return;
    }

    // Outside → clear
    ref.read(selectionUiProvider.notifier).reset();
    ref.read(selectionProvider.notifier).clearSelection();
    widget.onSelectionChanged?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragMode == null || _originalBounds == null) return;
    final pos = details.localPosition;

    switch (_dragMode!) {
      case _DragMode.move:
        final delta = pos - _dragStart!;
        ref.read(selectionUiProvider.notifier).setMoveDelta(delta);

      case _DragMode.rotate:
        final bounds = _originalBounds!;
        final cx = (bounds.left + bounds.right) / 2;
        final cy = (bounds.top + bounds.bottom) / 2;
        final angle =
            math.atan2(pos.dy - cy, pos.dx - cx) + math.pi / 2;
        ref.read(selectionUiProvider.notifier).setRotation(angle);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragMode == null || _originalBounds == null) {
      _reset();
      return;
    }

    switch (_dragMode!) {
      case _DragMode.move:
        _commitMove();
      case _DragMode.rotate:
        _commitRotation();
    }
    _reset();
  }

  void _commitMove() {
    final delta = ref.read(selectionUiProvider).moveDelta;
    if (delta == Offset.zero) return;

    // Clamp to page bounds
    final page = ref.read(currentPageProvider);
    final ob = _originalBounds!;
    final clampedDx = delta.dx.clamp(
      -ob.left,
      page.size.width - ob.right,
    );
    final clampedDy = delta.dy.clamp(
      -ob.top,
      page.size.height - ob.bottom,
    );

    final document = ref.read(documentProvider);
    final command = MoveSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      deltaX: clampedDx,
      deltaY: clampedDy,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Update selection bounds
    final newBounds = BoundingBox(
      left: ob.left + clampedDx,
      top: ob.top + clampedDy,
      right: ob.right + clampedDx,
      bottom: ob.bottom + clampedDy,
    );
    ref.read(selectionProvider.notifier).setSelection(
          widget.selection.copyWith(
            bounds: newBounds,
            lassoPath: null,
            type: SelectionType.rectangle,
          ),
        );
    ref.read(selectionUiProvider.notifier).reset();
    widget.onSelectionChanged?.call();
  }

  void _commitRotation() {
    final angle = ref.read(selectionUiProvider).rotation;
    if (angle == 0.0) return;

    final ob = _originalBounds!;
    final cx = (ob.left + ob.right) / 2;
    final cy = (ob.top + ob.bottom) / 2;

    final document = ref.read(documentProvider);
    final command = RotateSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      centerX: cx,
      centerY: cy,
      angle: angle,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Recalculate bounds from actual stroke positions
    _recalculateBoundsAfterRotation();
    ref.read(selectionUiProvider.notifier).reset();
    widget.onSelectionChanged?.call();
  }

  void _recalculateBoundsAfterRotation() {
    final doc = ref.read(documentProvider);
    final layer = doc.layers[doc.activeLayerIndex];

    double? minX, minY, maxX, maxY;

    for (final id in widget.selection.selectedStrokeIds) {
      final stroke = layer.getStrokeById(id);
      if (stroke == null) continue;
      final b = stroke.bounds;
      if (b == null) continue;
      minX = minX == null ? b.left : math.min(minX, b.left);
      minY = minY == null ? b.top : math.min(minY, b.top);
      maxX = maxX == null ? b.right : math.max(maxX, b.right);
      maxY = maxY == null ? b.bottom : math.max(maxY, b.bottom);
    }

    for (final id in widget.selection.selectedShapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;
      final b = shape.bounds;
      minX = minX == null ? b.left : math.min(minX, b.left);
      minY = minY == null ? b.top : math.min(minY, b.top);
      maxX = maxX == null ? b.right : math.max(maxX, b.right);
      maxY = maxY == null ? b.bottom : math.max(maxY, b.bottom);
    }

    if (minX != null && minY != null && maxX != null && maxY != null) {
      ref.read(selectionProvider.notifier).setSelection(
            widget.selection.copyWith(
              bounds:
                  BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY),
              lassoPath: null,
              type: SelectionType.rectangle,
            ),
          );
    }
  }

  void _reset() {
    _dragMode = null;
    _dragStart = null;
    _originalBounds = null;
  }
}

/// Paints blue border, 4 corner circles, and rotation handle.
class _SelectionHandlesPainter extends CustomPainter {
  final BoundingBox bounds;
  final Offset moveDelta;
  final double rotation;

  static const double _r = 6.0;
  static const double _rotDist = 30.0;

  _SelectionHandlesPainter({
    required this.bounds,
    required this.moveDelta,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = (bounds.left + bounds.right) / 2;
    final cy = (bounds.top + bounds.bottom) / 2;
    final rect =
        Rect.fromLTRB(bounds.left, bounds.top, bounds.right, bounds.bottom);

    canvas.save();

    // Apply live transform
    canvas.translate(cx + moveDelta.dx, cy + moveDelta.dy);
    if (rotation != 0) canvas.rotate(rotation);
    canvas.translate(-cx, -cy);

    // Border
    final border = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, border);

    // Corner handles
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleStroke = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final c in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(c, _r, fill);
      canvas.drawCircle(c, _r, handleStroke);
    }

    // Rotation handle: line + circle above top-center
    final topCenter = Offset(cx, bounds.top);
    final rotHandle = Offset(cx, bounds.top - _rotDist);
    canvas.drawLine(topCenter, rotHandle, border);
    canvas.drawCircle(rotHandle, _r, fill);
    canvas.drawCircle(rotHandle, _r, handleStroke);

    // Circular arrow icon inside rotation handle
    _drawRotationArrow(canvas, rotHandle);

    canvas.restore();
  }

  void _drawRotationArrow(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const arcRadius = 4.0;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    canvas.drawArc(arcRect, -math.pi * 0.75, math.pi * 1.5, false, paint);

    final arrowTip = Offset(
      center.dx + arcRadius * math.cos(math.pi * 0.75),
      center.dy + arcRadius * math.sin(math.pi * 0.75),
    );
    final arrowPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(arrowTip.dx - 3, arrowTip.dy - 1);
    path.lineTo(arrowTip.dx + 1, arrowTip.dy - 3);
    path.lineTo(arrowTip.dx + 1, arrowTip.dy + 2);
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionHandlesPainter old) {
    return old.bounds != bounds ||
        old.moveDelta != moveDelta ||
        old.rotation != rotation;
  }
}

/// Widget for selection actions (delete, copy, etc.).
class SelectionActions extends ConsumerWidget {
  final Selection selection;
  final VoidCallback? onDeleted;

  const SelectionActions({
    super.key,
    required this.selection,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }

  void deleteSelection(WidgetRef ref) {
    final document = ref.read(documentProvider);
    final command = DeleteSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
      shapeIds: selection.selectedShapeIds,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionProvider.notifier).clearSelection();
    ref.read(selectionUiProvider.notifier).reset();
    onDeleted?.call();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

enum _DragMode { move, rotate, scale }

/// Handles selection interactions: live move, rotate, scale, and tap.
///
/// - Drag corner handle → uniform scale.
/// - Drag edge handle → axis-constrained scale.
/// - Drag rotation handle → live rotate.
/// - Drag inside body → live move.
/// - Tap inside → show toolbar. Tap outside → clear selection.
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

  static const double _hitR = 22.0;
  static const double _rotDist = 36.0;
  static const double _minSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(selectionUiProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: SelectionHandlesPainter(
          bounds: widget.selection.bounds,
          moveDelta: ui.moveDelta,
          rotation: ui.rotation,
          scaleX: ui.scaleX,
          scaleY: ui.scaleY,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Helpers ──

  Offset _rotHandlePos(BoundingBox b) =>
      Offset((b.left + b.right) / 2, b.top - _rotDist);

  bool _inside(Offset pt, BoundingBox b) =>
      pt.dx >= b.left && pt.dx <= b.right && pt.dy >= b.top && pt.dy <= b.bottom;

  SelectionHandle? _hitTestHandle(Offset pt, BoundingBox b) {
    final cx = (b.left + b.right) / 2;
    final cy = (b.top + b.bottom) / 2;
    // Corners
    if ((pt - Offset(b.left, b.top)).distance <= _hitR) return SelectionHandle.topLeft;
    if ((pt - Offset(b.right, b.top)).distance <= _hitR) return SelectionHandle.topRight;
    if ((pt - Offset(b.left, b.bottom)).distance <= _hitR) return SelectionHandle.bottomLeft;
    if ((pt - Offset(b.right, b.bottom)).distance <= _hitR) return SelectionHandle.bottomRight;
    // Edges
    if ((pt - Offset(cx, b.top)).distance <= _hitR) return SelectionHandle.topCenter;
    if ((pt - Offset(cx, b.bottom)).distance <= _hitR) return SelectionHandle.bottomCenter;
    if ((pt - Offset(b.left, cy)).distance <= _hitR) return SelectionHandle.middleLeft;
    if ((pt - Offset(b.right, cy)).distance <= _hitR) return SelectionHandle.middleRight;
    return null;
  }

  bool _isCorner(SelectionHandle h) =>
      h == SelectionHandle.topLeft || h == SelectionHandle.topRight ||
      h == SelectionHandle.bottomLeft || h == SelectionHandle.bottomRight;

  // ── Tap ──

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final b = widget.selection.bounds;
    if ((pos - _rotHandlePos(b)).distance <= _hitR) return;
    if (_inside(pos, b)) {
      ref.read(selectionUiProvider.notifier).showContextMenu();
      return;
    }
    _clearSelection();
  }

  // ── Pan ──

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final b = widget.selection.bounds;
    ref.read(selectionUiProvider.notifier).hideContextMenu();

    if ((pos - _rotHandlePos(b)).distance <= _hitR) {
      _startDrag(_DragMode.rotate, pos, b);
      return;
    }
    final handle = _hitTestHandle(pos, b);
    if (handle != null) {
      _startDrag(_DragMode.scale, pos, b);
      ref.read(selectionUiProvider.notifier).setActiveHandle(handle);
      return;
    }
    if (_inside(pos, b)) {
      _startDrag(_DragMode.move, pos, b);
      return;
    }
    _clearSelection();
  }

  void _startDrag(_DragMode mode, Offset pos, BoundingBox b) {
    _dragMode = mode;
    _dragStart = pos;
    _originalBounds = b;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragMode == null || _originalBounds == null) return;
    final pos = details.localPosition;
    switch (_dragMode!) {
      case _DragMode.move:
        ref.read(selectionUiProvider.notifier).setMoveDelta(pos - _dragStart!);
      case _DragMode.rotate:
        final b = _originalBounds!;
        final cx = (b.left + b.right) / 2, cy = (b.top + b.bottom) / 2;
        ref.read(selectionUiProvider.notifier)
            .setRotation(math.atan2(pos.dy - cy, pos.dx - cx) + math.pi / 2);
      case _DragMode.scale:
        _updateScale(pos);
    }
  }

  void _updateScale(Offset pos) {
    final b = _originalBounds!;
    final handle = ref.read(selectionUiProvider).activeHandle;
    if (handle == null) return;
    final cx = (b.left + b.right) / 2, cy = (b.top + b.bottom) / 2;
    final halfW = (b.right - b.left) / 2, halfH = (b.bottom - b.top) / 2;
    if (halfW < 1 || halfH < 1) return;

    double sx = 1.0, sy = 1.0;
    if (_isCorner(handle)) {
      final d0 = (_dragStart! - Offset(cx, cy)).distance;
      if (d0 < 1) return;
      final f = (pos - Offset(cx, cy)).distance / d0;
      sx = f; sy = f;
    } else {
      switch (handle) {
        case SelectionHandle.topCenter:
        case SelectionHandle.bottomCenter:
          final d0 = (_dragStart!.dy - cy).abs();
          if (d0 < 1) return;
          sy = (pos.dy - cy).abs() / d0;
        case SelectionHandle.middleLeft:
        case SelectionHandle.middleRight:
          final d0 = (_dragStart!.dx - cx).abs();
          if (d0 < 1) return;
          sx = (pos.dx - cx).abs() / d0;
        default: break;
      }
    }
    if (halfW * 2 * sx < _minSize) sx = _minSize / (halfW * 2);
    if (halfH * 2 * sy < _minSize) sy = _minSize / (halfH * 2);
    ref.read(selectionUiProvider.notifier).setScale(sx, sy);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragMode == null || _originalBounds == null) { _reset(); return; }
    switch (_dragMode!) {
      case _DragMode.move: _commitMove();
      case _DragMode.rotate: _commitRotation();
      case _DragMode.scale: _commitScale();
    }
    _reset();
  }

  // ── Commits ──

  void _commitMove() {
    final delta = ref.read(selectionUiProvider).moveDelta;
    if (delta == Offset.zero) return;
    final page = ref.read(currentPageProvider);
    final ob = _originalBounds!;
    final dx = delta.dx.clamp(-ob.left, page.size.width - ob.right);
    final dy = delta.dy.clamp(-ob.top, page.size.height - ob.bottom);

    _executeCommand(MoveSelectionCommand(
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      deltaX: dx, deltaY: dy,
    ));
    ref.read(selectionProvider.notifier).setSelection(
      widget.selection.copyWith(
        bounds: BoundingBox(
          left: ob.left + dx, top: ob.top + dy,
          right: ob.right + dx, bottom: ob.bottom + dy,
        ),
        lassoPath: null, type: SelectionType.rectangle,
      ),
    );
    _finishTransform();
  }

  void _commitRotation() {
    final angle = ref.read(selectionUiProvider).rotation;
    if (angle == 0.0) return;
    final ob = _originalBounds!;
    final cx = (ob.left + ob.right) / 2, cy = (ob.top + ob.bottom) / 2;
    _executeCommand(RotateSelectionCommand(
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      centerX: cx, centerY: cy, angle: angle,
    ));
    _recalculateBounds();
    _finishTransform();
  }

  void _commitScale() {
    final ui = ref.read(selectionUiProvider);
    if (ui.scaleX == 1.0 && ui.scaleY == 1.0) return;
    final ob = _originalBounds!;
    final cx = (ob.left + ob.right) / 2, cy = (ob.top + ob.bottom) / 2;
    _executeCommand(ScaleSelectionCommand(
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      centerX: cx, centerY: cy, scaleX: ui.scaleX, scaleY: ui.scaleY,
    ));
    _recalculateBounds();
    _finishTransform();
  }

  void _executeCommand(DrawingCommand command) {
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  void _recalculateBounds() {
    final doc = ref.read(documentProvider);
    final layer = doc.layers[doc.activeLayerIndex];
    double? minX, minY, maxX, maxY;
    void expand(BoundingBox b) {
      minX = minX == null ? b.left : math.min(minX!, b.left);
      minY = minY == null ? b.top : math.min(minY!, b.top);
      maxX = maxX == null ? b.right : math.max(maxX!, b.right);
      maxY = maxY == null ? b.bottom : math.max(maxY!, b.bottom);
    }
    for (final id in widget.selection.selectedStrokeIds) {
      final b = layer.getStrokeById(id)?.bounds;
      if (b != null) expand(b);
    }
    for (final id in widget.selection.selectedShapeIds) {
      final s = layer.getShapeById(id);
      if (s != null) expand(s.bounds);
    }
    if (minX != null) {
      ref.read(selectionProvider.notifier).setSelection(
        widget.selection.copyWith(
          bounds: BoundingBox(left: minX!, top: minY!, right: maxX!, bottom: maxY!),
          lassoPath: null, type: SelectionType.rectangle,
        ),
      );
    }
  }

  void _finishTransform() {
    ref.read(selectionUiProvider.notifier).reset();
    widget.onSelectionChanged?.call();
  }

  void _clearSelection() {
    ref.read(selectionUiProvider.notifier).reset();
    ref.read(selectionProvider.notifier).clearSelection();
    widget.onSelectionChanged?.call();
  }

  void _reset() {
    _dragMode = null;
    _dragStart = null;
    _originalBounds = null;
    ref.read(selectionUiProvider.notifier).setActiveHandle(null);
  }
}

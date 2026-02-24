import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

enum _DragMode { move, rotate, scale }

/// Handles selection interactions: live move, rotate, scale, and tap.
///
/// Uses [Listener] instead of [GestureDetector] to bypass the gesture
/// arena, which prevents the parent ScaleGestureRecognizer (zoom/pan)
/// from stealing single-finger drags on selection handles.
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
  double? _initialAngle;
  int? _activePointer;
  Offset? _pointerDownPos;

  static const double _hitR = 22.0;
  static const double _rotDist = 36.0;
  static const double _minSize = 20.0;
  static const double _tapSlop = 18.0;

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(selectionUiProvider);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
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
      pt.dx >= b.left &&
      pt.dx <= b.right &&
      pt.dy >= b.top &&
      pt.dy <= b.bottom;

  (SelectionHandle, Offset)? _hitTestHandle(Offset pt, BoundingBox b) {
    final cx = (b.left + b.right) / 2, cy = (b.top + b.bottom) / 2;
    final handles = [
      (SelectionHandle.topLeft, Offset(b.left, b.top)),
      (SelectionHandle.topRight, Offset(b.right, b.top)),
      (SelectionHandle.bottomLeft, Offset(b.left, b.bottom)),
      (SelectionHandle.bottomRight, Offset(b.right, b.bottom)),
      (SelectionHandle.topCenter, Offset(cx, b.top)),
      (SelectionHandle.bottomCenter, Offset(cx, b.bottom)),
      (SelectionHandle.middleLeft, Offset(b.left, cy)),
      (SelectionHandle.middleRight, Offset(b.right, cy)),
    ];
    handles.sort(
        (a, b) => (pt - a.$2).distance.compareTo((pt - b.$2).distance));
    return (pt - handles.first.$2).distance <= _hitR ? handles.first : null;
  }

  bool _isCorner(SelectionHandle h) =>
      h == SelectionHandle.topLeft ||
      h == SelectionHandle.topRight ||
      h == SelectionHandle.bottomLeft ||
      h == SelectionHandle.bottomRight;

  // ── Pointer events ──

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return; // Only track one pointer
    _activePointer = event.pointer;
    _pointerDownPos = event.localPosition;
    _determineDragMode(event.localPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    _handleDragUpdate(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _handlePointerUp(event.localPosition);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    // Cancel any in-progress drag
    if (_dragMode != null) {
      ref.read(selectionUiProvider.notifier).reset();
    }
    _reset();
    _activePointer = null;
    _pointerDownPos = null;
  }

  // ── Drag mode detection (on pointer down) ──

  void _determineDragMode(Offset pos) {
    final b = widget.selection.bounds;
    ref.read(selectionUiProvider.notifier).hideContextMenu();

    if ((pos - _rotHandlePos(b)).distance <= _hitR) {
      _startDrag(_DragMode.rotate, pos, b);
      _initialAngle = math.atan2(
          pos.dy - (b.top + b.bottom) / 2, pos.dx - (b.left + b.right) / 2);
      return;
    }
    final hit = _hitTestHandle(pos, b);
    if (hit != null) {
      _startDrag(_DragMode.scale, hit.$2, b);
      ref.read(selectionUiProvider.notifier).setActiveHandle(hit.$1);
      return;
    }
    if (_inside(pos, b)) {
      _startDrag(_DragMode.move, pos, b);
      return;
    }
    // Outside everything — will clear on pointer up (tap detection)
  }

  void _startDrag(_DragMode mode, Offset pos, BoundingBox b) {
    _dragMode = mode;
    _dragStart = pos;
    _originalBounds = b;
  }

  // ── Drag update ──

  void _handleDragUpdate(Offset pos) {
    if (_dragMode == null || _originalBounds == null) return;
    switch (_dragMode!) {
      case _DragMode.move:
        final d = pos - _dragStart!;
        final ob = _originalBounds!;
        final sz = ref.read(currentPageProvider).size;
        final minDx = -ob.left, maxDx = sz.width - ob.right;
        final minDy = -ob.top, maxDy = sz.height - ob.bottom;
        ref.read(selectionUiProvider.notifier).setMoveDelta(Offset(
            minDx <= maxDx ? d.dx.clamp(minDx, maxDx) : d.dx,
            minDy <= maxDy ? d.dy.clamp(minDy, maxDy) : d.dy));
      case _DragMode.rotate:
        final ob = _originalBounds!;
        final a = math.atan2(pos.dy - (ob.top + ob.bottom) / 2,
            pos.dx - (ob.left + ob.right) / 2);
        ref
            .read(selectionUiProvider.notifier)
            .setRotation(a - (_initialAngle ?? a));
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
      sx = (pos - Offset(cx, cy)).distance / d0;
      sy = sx;
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
        default:
          break;
      }
    }
    if (halfW * 2 * sx < _minSize) sx = _minSize / (halfW * 2);
    if (halfH * 2 * sy < _minSize) sy = _minSize / (halfH * 2);
    final sz = ref.read(currentPageProvider).size;
    final mxX = math.min(cx, sz.width - cx) / halfW;
    final mxY = math.min(cy, sz.height - cy) / halfH;
    if (sx > mxX) sx = mxX;
    if (sy > mxY) sy = mxY;
    if (_isCorner(handle)) {
      final f = math.min(sx, sy);
      sx = f;
      sy = f;
    }
    ref.read(selectionUiProvider.notifier).setScale(sx, sy);
  }

  // ── Pointer up: commit or tap ──

  void _handlePointerUp(Offset pos) {
    final downPos = _pointerDownPos;
    final wasDrag = _dragMode != null && _originalBounds != null;
    final moved = downPos != null && (pos - downPos).distance > _tapSlop;

    if (wasDrag && moved) {
      // Commit the drag operation
      switch (_dragMode!) {
        case _DragMode.move:
          _commitMove();
        case _DragMode.rotate:
          _commitRotation();
        case _DragMode.scale:
          _commitScale();
      }
    } else if (!moved) {
      // Treat as tap
      _handleTap(pos);
    }
    _reset();
    _activePointer = null;
    _pointerDownPos = null;
  }

  void _handleTap(Offset pos) {
    final b = widget.selection.bounds;
    if ((pos - _rotHandlePos(b)).distance <= _hitR) return;
    if (_hitTestHandle(pos, b) != null) return;
    if (_inside(pos, b)) {
      ref.read(selectionUiProvider.notifier).showContextMenu();
      return;
    }
    _clearSelection();
  }

  // ── Commits ──

  void _commitMove() {
    final delta = ref.read(selectionUiProvider).moveDelta;
    if (delta == Offset.zero) return;
    final ob = _originalBounds!;
    _executeCommand(MoveSelectionCommand(
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      shapeIds: widget.selection.selectedShapeIds,
      imageIds: widget.selection.selectedImageIds,
      textIds: widget.selection.selectedTextIds,
      deltaX: delta.dx,
      deltaY: delta.dy,
    ));
    ref.read(selectionProvider.notifier).setSelection(
          widget.selection.copyWith(
            bounds: BoundingBox(
              left: ob.left + delta.dx,
              top: ob.top + delta.dy,
              right: ob.right + delta.dx,
              bottom: ob.bottom + delta.dy,
            ),
            lassoPath: null,
            type: SelectionType.rectangle,
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
        imageIds: widget.selection.selectedImageIds,
        textIds: widget.selection.selectedTextIds,
        centerX: cx,
        centerY: cy,
        angle: angle));
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
        imageIds: widget.selection.selectedImageIds,
        textIds: widget.selection.selectedTextIds,
        centerX: cx,
        centerY: cy,
        scaleX: ui.scaleX,
        scaleY: ui.scaleY));
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
    for (final id in widget.selection.selectedImageIds) {
      final i = layer.getImageById(id);
      if (i != null) expand(i.bounds);
    }
    for (final id in widget.selection.selectedTextIds) {
      final t = layer.getTextById(id);
      if (t != null) expand(t.bounds);
    }
    if (minX != null) {
      ref.read(selectionProvider.notifier).setSelection(
            widget.selection.copyWith(
              bounds: BoundingBox(
                  left: minX!, top: minY!, right: maxX!, bottom: maxY!),
              lassoPath: null,
              type: SelectionType.rectangle,
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
    _initialAngle = null;
    ref.read(selectionUiProvider.notifier).setActiveHandle(null);
  }
}

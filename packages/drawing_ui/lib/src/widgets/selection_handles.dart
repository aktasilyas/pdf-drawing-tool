import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';
import 'package:drawing_ui/src/widgets/selection_geometry.dart';
import 'package:drawing_ui/src/widgets/selection_transform_commands.dart';

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
///
/// Handle hit areas are at least [SelectionGeometry.minScreenHitRadius]
/// logical pixels on screen at every canvas zoom.
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
  SelectionDragMode? _dragMode;
  Offset? _dragStart;
  BoundingBox? _originalBounds;
  double? _initialAngle;
  int? _activePointer;
  Offset? _pointerDownPos;

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
          selectionColor: Theme.of(context).colorScheme.primary,
          scaleX: ui.scaleX,
          scaleY: ui.scaleY,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Helpers ──

  SelectionHit? _hitTest(Offset pos) {
    final zoom = ref.read(zoomLevelProvider);
    return SelectionGeometry.hitTest(pos, widget.selection.bounds, zoom: zoom);
  }

  /// Page size for clamping, or `null` on an infinite canvas.
  Size? _pageSize() {
    if (ref.read(isInfiniteCanvasProvider)) return null;
    return ref.read(currentPageProvider).size;
  }

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
    if (!mounted) return;
    _handlePointerUp(event.localPosition);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    if (!mounted) return;
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

    final hit = _hitTest(pos);
    // Outside everything: cleared on pointer up (tap detection).
    if (hit == null) return;
    _dragMode = hit.mode;
    _dragStart = hit.anchor;
    _originalBounds = b;
    switch (hit.mode) {
      case SelectionDragMode.rotate:
        _initialAngle = SelectionGeometry.angleAround(pos, b);
      case SelectionDragMode.scale:
        ref.read(selectionUiProvider.notifier).setActiveHandle(hit.handle);
      case SelectionDragMode.move:
        break;
    }
  }

  // ── Drag update ──

  void _handleDragUpdate(Offset pos) {
    final mode = _dragMode, ob = _originalBounds, start = _dragStart;
    if (mode == null || ob == null || start == null) return;
    final notifier = ref.read(selectionUiProvider.notifier);
    switch (mode) {
      case SelectionDragMode.move:
        final d = SelectionGeometry.clampMove(pos - start, ob, _pageSize());
        notifier.setMoveDelta(d);
      case SelectionDragMode.rotate:
        final a = SelectionGeometry.angleAround(pos, ob);
        notifier.setRotation(a - (_initialAngle ?? a));
      case SelectionDragMode.scale:
        final handle = ref.read(selectionUiProvider).activeHandle;
        if (handle == null) return;
        final s = SelectionGeometry.scaleFor(
          handle: handle,
          b: ob,
          dragStart: start,
          pos: pos,
          pageSize: _pageSize(),
        );
        if (s != null) notifier.setScale(s.$1, s.$2);
    }
  }

  // ── Pointer up: commit or tap ──

  void _handlePointerUp(Offset pos) {
    final downPos = _pointerDownPos;
    final mode = _dragMode;
    final ob = _originalBounds;
    final travel = downPos == null ? 0.0 : (pos - downPos).distance;
    final moved = travel > SelectionGeometry.tapSlop;

    if (mode != null && ob != null && moved) {
      _commit(mode, ob);
    } else if (!moved) {
      _handleTap(pos);
    }
    _reset();
    _activePointer = null;
    _pointerDownPos = null;
  }

  void _handleTap(Offset pos) {
    final hit = _hitTest(pos);
    if (hit == null) {
      _clearSelection();
    } else if (hit.mode == SelectionDragMode.move) {
      ref.read(selectionUiProvider.notifier).showContextMenu();
    }
  }

  // ── Commits ──

  void _commit(SelectionDragMode mode, BoundingBox ob) {
    final ui = ref.read(selectionUiProvider);
    final selection = widget.selection;
    final command = selectionTransformCommand(
      mode: mode,
      selection: selection,
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      originalBounds: ob,
      ui: ui,
    );
    if (command == null) return;
    ref.read(historyManagerProvider.notifier).execute(command);

    final doc = ref.read(documentProvider);
    var newBounds = selectedElementBounds(doc, selection);
    if (mode == SelectionDragMode.move) {
      newBounds = SelectionGeometry.translate(ob, ui.moveDelta);
    }
    if (newBounds != null) {
      final updated = selection.copyWith(
        bounds: newBounds,
        lassoPath: null,
        type: SelectionType.rectangle,
      );
      ref.read(selectionProvider.notifier).setSelection(updated);
    }
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

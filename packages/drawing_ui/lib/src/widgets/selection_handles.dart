import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

/// Widget that handles selection drag interactions.
///
/// Provides gesture handling for:
/// - Moving selected strokes (drag inside selection)
/// - Future: Resize via corner/edge handles
class SelectionHandles extends ConsumerStatefulWidget {
  /// The current selection.
  final Selection selection;

  /// Called when selection is modified (moved, resized).
  final VoidCallback? onSelectionChanged;

  /// Called when selection is deleted.
  final VoidCallback? onSelectionDeleted;

  const SelectionHandles({
    super.key,
    required this.selection,
    this.onSelectionChanged,
    this.onSelectionDeleted,
  });

  @override
  ConsumerState<SelectionHandles> createState() => _SelectionHandlesState();
}

class _SelectionHandlesState extends ConsumerState<SelectionHandles> {
  SelectionHandle? _activeHandle;
  Offset? _dragStartPoint;
  Offset? _lastDragPosition;
  BoundingBox? _originalBounds;

  /// Hit radius for handle detection (in logical pixels).
  static const double _hitRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: const SizedBox.expand(),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    // localPosition is already in canvas coordinates (inside Transform widget)
    final localPos = details.localPosition;

    _activeHandle = _hitTestHandle(localPos);

    if (_activeHandle != null) {
      _dragStartPoint = localPos;
      _lastDragPosition = localPos;
      _originalBounds = widget.selection.bounds;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activeHandle == null ||
        _originalBounds == null ||
        _dragStartPoint == null) {
      return;
    }

    // localPosition is already in canvas coordinates (inside Transform widget)
    final localPos = details.localPosition;
    _lastDragPosition = localPos;
    final delta = localPos - _dragStartPoint!;

    if (_activeHandle == SelectionHandle.center) {
      // Move preview - update bounds without committing
      _moveSelectionPreview(delta);
    }
    // TODO: Resize for other handles (Phase 5+)
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_activeHandle == null ||
        _originalBounds == null ||
        _dragStartPoint == null ||
        _lastDragPosition == null) {
      return;
    }

    // Use the last known drag position
    final delta = _lastDragPosition! - _dragStartPoint!;

    if (_activeHandle == SelectionHandle.center &&
        (delta.dx != 0 || delta.dy != 0)) {
      // Commit the move operation
      _commitMove(delta);
    }

    _activeHandle = null;
    _dragStartPoint = null;
    _lastDragPosition = null;
    _originalBounds = null;
  }

  /// Updates selection bounds for move preview.
  void _moveSelectionPreview(Offset delta) {
    final newBounds = BoundingBox(
      left: _originalBounds!.left + delta.dx,
      top: _originalBounds!.top + delta.dy,
      right: _originalBounds!.right + delta.dx,
      bottom: _originalBounds!.bottom + delta.dy,
    );

    ref.read(selectionProvider.notifier).updateBounds(newBounds);
  }

  /// Commits the move via MoveSelectionCommand.
  void _commitMove(Offset delta) {
    final document = ref.read(documentProvider);

    final command = MoveSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      deltaX: delta.dx,
      deltaY: delta.dy,
    );

    ref.read(historyManagerProvider.notifier).execute(command);

    // Update selection bounds to match new stroke positions
    final newBounds = BoundingBox(
      left: _originalBounds!.left + delta.dx,
      top: _originalBounds!.top + delta.dy,
      right: _originalBounds!.right + delta.dx,
      bottom: _originalBounds!.bottom + delta.dy,
    );

    // Update selection with new bounds and clear lasso path (it's no longer valid after move)
    ref.read(selectionProvider.notifier).setSelection(
          widget.selection.copyWith(
            bounds: newBounds,
            // Clear lasso path after move - convert to rectangle selection
            lassoPath: null,
            type: SelectionType.rectangle,
          ),
        );

    widget.onSelectionChanged?.call();
  }

  /// Hit tests which handle (if any) was tapped.
  SelectionHandle? _hitTestHandle(Offset point) {
    final bounds = widget.selection.bounds;
    // Since we're inside Transform, coordinates are in canvas space
    // Use fixed hit radius (no zoom adjustment needed)
    const hitRadius = _hitRadius;

    // Check corner and edge handles first
    const handles = [
      SelectionHandle.topLeft,
      SelectionHandle.topCenter,
      SelectionHandle.topRight,
      SelectionHandle.middleLeft,
      SelectionHandle.middleRight,
      SelectionHandle.bottomLeft,
      SelectionHandle.bottomCenter,
      SelectionHandle.bottomRight,
    ];

    for (final handle in handles) {
      final handlePos = handle.getPosition(bounds);
      final handleOffset = Offset(handlePos.x, handlePos.y);
      if ((point - handleOffset).distance <= hitRadius) {
        return handle;
      }
    }

    // Check if inside selection bounds (for dragging)
    if (point.dx >= bounds.left &&
        point.dx <= bounds.right &&
        point.dy >= bounds.top &&
        point.dy <= bounds.bottom) {
      return SelectionHandle.center;
    }

    return null;
  }
}

/// Widget for selection actions (delete, copy, etc.).
///
/// Currently minimal - provides delete functionality.
/// Can be extended with action buttons in the future.
class SelectionActions extends ConsumerWidget {
  /// The selection to act upon.
  final Selection selection;

  /// Called when selection is deleted.
  final VoidCallback? onDeleted;

  const SelectionActions({
    super.key,
    required this.selection,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Currently returns nothing - can add floating action buttons later
    return const SizedBox.shrink();
  }

  /// Deletes the selected strokes.
  void deleteSelection(WidgetRef ref) {
    final document = ref.read(documentProvider);

    final command = DeleteSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
    );

    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionProvider.notifier).clearSelection();

    onDeleted?.call();
  }
}

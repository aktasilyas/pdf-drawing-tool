import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/sticky_note_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';

import 'sticky_note_handles_painter.dart';

enum _DragMode { resize, move }

/// Handles for resizing and moving a selected sticky note.
///
/// Top-right corner: shrink button + three-dot menu button.
/// Bottom-right corner: resize handle.
/// Body drag: move. Tap outside: deselect.
class StickyNoteResizeHandles extends ConsumerStatefulWidget {
  final StickyNote note;

  const StickyNoteResizeHandles({super.key, required this.note});

  @override
  ConsumerState<StickyNoteResizeHandles> createState() =>
      _StickyNoteResizeHandlesState();
}

class _StickyNoteResizeHandlesState
    extends ConsumerState<StickyNoteResizeHandles> {
  _DragMode? _dragMode;
  StickyNote? _originalNote;
  Offset? _lastDragPos;

  static const double _hitRadius = 20.0;
  static const double _minSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: StickyNoteHandlesPainter(note: widget.note),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Hit-test helpers ──

  Rect _shrinkBtnRect(StickyNote n) {
    final right = n.x + n.width;
    return Rect.fromLTWH(
      right - stickyNoteIconBtnSize * 2 - stickyNoteIconGap - 6,
      n.y + 6,
      stickyNoteIconBtnSize,
      stickyNoteIconBtnSize,
    );
  }

  Rect _menuBtnRect(StickyNote n) {
    final right = n.x + n.width;
    return Rect.fromLTWH(
      right - stickyNoteIconBtnSize - 6,
      n.y + 6,
      stickyNoteIconBtnSize,
      stickyNoteIconBtnSize,
    );
  }

  bool _isOnShrinkBtn(Offset pos, StickyNote n) =>
      _shrinkBtnRect(n).inflate(4).contains(pos);

  bool _isOnMenuBtn(Offset pos, StickyNote n) =>
      _menuBtnRect(n).inflate(4).contains(pos);

  bool _isInsideNote(Offset pos, StickyNote note) {
    return pos.dx >= note.x &&
        pos.dx <= note.x + note.width &&
        pos.dy >= note.y &&
        pos.dy <= note.y + note.height;
  }

  Offset _bottomRightCorner(StickyNote note) =>
      Offset(note.x + note.width, note.y + note.height);

  bool _isOnResizeHandle(Offset pos, StickyNote note) {
    return (pos - _bottomRightCorner(note)).distance <= _hitRadius;
  }

  StickyNote _clampToPage(StickyNote note) {
    final page = ref.read(currentPageProvider);
    final pw = page.size.width;
    final ph = page.size.height;
    final clampedX = note.x.clamp(0.0, (pw - note.width).clamp(0.0, pw));
    final clampedY = note.y.clamp(0.0, (ph - note.height).clamp(0.0, ph));
    return note.copyWith(x: clampedX, y: clampedY);
  }

  // ── Tap handler ──

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final note = widget.note;

    if (_isOnShrinkBtn(pos, note)) {
      _handleMinimize(note);
      return;
    }

    if (_isOnMenuBtn(pos, note)) {
      ref.read(stickyNotePlacementProvider.notifier).showContextMenu();
      return;
    }

    if (_isOnResizeHandle(pos, note)) return;

    if (_isInsideNote(pos, note)) {
      ref.read(stickyNotePlacementProvider.notifier).hideContextMenu();
      return;
    }

    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  void _handleMinimize(StickyNote note) {
    final newNote = note.copyWith(minimized: true);

    final document = ref.read(documentProvider);
    final command = UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: newNote,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  // ── Pan handlers ──

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final note = widget.note;

    if (_isOnShrinkBtn(pos, note) || _isOnMenuBtn(pos, note)) return;

    if (_isOnResizeHandle(pos, note)) {
      _dragMode = _DragMode.resize;
      _originalNote = note;
      _lastDragPos = pos;
      return;
    }

    if (_isInsideNote(pos, note)) {
      _dragMode = _DragMode.move;
      _originalNote = note;
      _lastDragPos = pos;
      return;
    }

    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragMode == null || _originalNote == null) return;
    final pos = details.localPosition;

    switch (_dragMode!) {
      case _DragMode.resize:
        final newW = math.max(_minSize, pos.dx - _originalNote!.x);
        final newH = math.max(_minSize, pos.dy - _originalNote!.y);
        final resized = _originalNote!.copyWith(width: newW, height: newH);
        ref
            .read(stickyNotePlacementProvider.notifier)
            .updateSelectedNote(resized);
        break;

      case _DragMode.move:
        final delta = pos - _lastDragPos!;
        _lastDragPos = pos;
        final cur =
            ref.read(stickyNotePlacementProvider).selectedNote ??
                _originalNote!;
        final moved =
            cur.copyWith(x: cur.x + delta.dx, y: cur.y + delta.dy);
        ref
            .read(stickyNotePlacementProvider.notifier)
            .updateSelectedNote(_clampToPage(moved));
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragMode == null || _originalNote == null) {
      _reset();
      return;
    }

    final current = ref.read(stickyNotePlacementProvider).selectedNote;
    if (current != null && current.id == _originalNote!.id) {
      final o = _originalNote!;
      final changed = current.x != o.x ||
          current.y != o.y ||
          current.width != o.width ||
          current.height != o.height;

      if (changed) {
        final document = ref.read(documentProvider);
        final command = UpdateStickyNoteCommand(
          layerIndex: document.activeLayerIndex,
          newNote: current,
        );
        ref.read(historyManagerProvider.notifier).execute(command);
      }
    }
    _reset();
  }

  void _reset() {
    _dragMode = null;
    _originalNote = null;
    _lastDragPos = null;
  }
}

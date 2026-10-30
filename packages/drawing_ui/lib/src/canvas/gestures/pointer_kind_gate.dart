part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Device-kind policy: in stylus mode touches never reach the tools, and a
/// stylus is never counted together with touches.
///
/// Ignored pointers are remembered by id so their move/up/cancel are skipped
/// even if the mode changes mid-gesture.
mixin _PointerKindGate<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, _GestureState<T> {
  /// Pointers that were accepted by [handlePointerDown] and are counted in
  /// `pointerCount`. Everything else (ignored touches, out-of-page downs) is
  /// skipped on move/up/cancel so the count can neither drift up nor down.
  final Set<int> _countedPointers = <int>{};
  int _stylusPointer = -1;

  /// Pointer id of an eraser-end stylus that is down (-1: none). While set,
  /// the canvas erases with the user's eraser settings and the selected tool
  /// stays untouched.
  int _invertedPointer = -1;

  /// True while an eraser-end stylus is down.
  bool get invertedEraserActive => _invertedPointer >= 0;

  /// Set when the pen cut a finger navigation gesture short; cleared when the
  /// next scale gesture starts or the cut one ends.
  bool navPreempted = false;

  /// True while a stylus is down (palm touches must not zoom/pan then).
  bool get isStylusActive => _stylusPointer >= 0;

  /// Whether a scale gesture with [fingers] touches navigates the canvas:
  /// two fingers always, one finger only in stylus mode (the pen draws, the
  /// finger scrolls and swipes pages). Never while the pen is down.
  bool navigatesWith(int fingers) {
    if (isStylusActive) return false;
    return fingers >= 2 || !ref.read(inputModeProvider).fingerDraws;
  }

  /// Returns true when the down event must not reach the tools.
  bool gateDown(PointerDownEvent event) {
    if (InputMode.isStylus(event.kind)) {
      ref.read(inputModeProvider.notifier).stylusSeen();
      _stylusPointer = event.pointer;
      if (InputMode.isEraserEnd(event.kind)) {
        _invertedPointer = event.pointer;
      }
      if (lastFocalPoint != null) {
        // The pen pre-empts a one-finger pan/swipe in progress: the rest of
        // that gesture neither flips the page nor jumps the canvas.
        if (_swipeDragActive) {
          onPageSwipeDragEnd?.call(0);
          _swipeDragActive = false;
        }
        navPreempted = true;
        lastFocalPoint = null;
      }
      if (_countedPointers.isNotEmpty) {
        // A palm or finger got there first: the pen takes over.
        if (drawingController.isDrawing) drawingController.cancelStroke();
        _countedPointers.clear();
        pointerCount = 0;
      }
      return false;
    }
    return ref.read(inputModeProvider).ignores(event.kind);
  }

  /// Marks an accepted down so its move/up/cancel are processed.
  void countPointer(int pointer) => _countedPointers.add(pointer);

  /// Returns true when move/up/cancel of [pointer] must be skipped.
  bool gateOther(int pointer, {bool end = false}) {
    if (end && pointer == _stylusPointer) _stylusPointer = -1;
    if (end && pointer == _invertedPointer) _invertedPointer = -1;
    if (end) return !_countedPointers.remove(pointer);
    return !_countedPointers.contains(pointer);
  }
}

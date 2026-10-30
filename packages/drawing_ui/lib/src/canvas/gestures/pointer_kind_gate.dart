part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Device-kind policy: in stylus mode touches never reach the tools, and a
/// stylus is never counted together with touches.
///
/// Ignored pointers are remembered by id so their move/up/cancel are skipped
/// even if the mode changes mid-gesture.
mixin _PointerKindGate<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, _GestureState<T> {
  final Set<int> _ignoredPointers = <int>{};
  int _stylusPointer = -1;

  /// True while a stylus is down (palm touches must not zoom/pan then).
  bool get isStylusActive => _stylusPointer >= 0;

  /// Returns true when the down event must not reach the tools.
  bool gateDown(PointerDownEvent event) {
    if (InputMode.isStylus(event.kind)) {
      ref.read(inputModeProvider.notifier).stylusSeen();
      _stylusPointer = event.pointer;
      return false;
    }
    if (ref.read(inputModeProvider).ignores(event.kind)) {
      _ignoredPointers.add(event.pointer);
      return true;
    }
    return false;
  }

  /// Returns true when move/up/cancel of [pointer] must be skipped.
  bool gateOther(int pointer, {bool end = false}) {
    if (pointer == _stylusPointer && end) _stylusPointer = -1;
    if (end) return _ignoredPointers.remove(pointer);
    return _ignoredPointers.contains(pointer);
  }
}

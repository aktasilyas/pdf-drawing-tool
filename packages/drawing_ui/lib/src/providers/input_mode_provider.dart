import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

const _stylusDetectedKey = 'input_stylus_detected';
const _drawWithFingerKey = 'input_draw_with_finger';

/// Which pointer kinds may drive tools on the canvas.
///
/// Finger-only users are unaffected. Once a stylus has been seen, touches only
/// navigate (pan / zoom / page swipe) unless [drawWithFinger] is on.
class InputMode {
  const InputMode({this.stylusDetected = false, this.drawWithFinger = false});

  final bool stylusDetected;
  final bool drawWithFinger;

  /// Whether a finger may start a tool action.
  bool get fingerDraws => !stylusDetected || drawWithFinger;

  /// Whether a pointer of [kind] must be kept away from the tools.
  bool ignores(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.touch && !fingerDraws;

  static bool isStylus(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  InputMode copyWith({bool? stylusDetected, bool? drawWithFinger}) => InputMode(
        stylusDetected: stylusDetected ?? this.stylusDetected,
        drawWithFinger: drawWithFinger ?? this.drawWithFinger,
      );
}

/// Persisted [InputMode]; the first stylus contact switches stylus mode on.
final inputModeProvider =
    StateNotifierProvider<InputModeNotifier, InputMode>((ref) {
  return InputModeNotifier(ref.watch(sharedPreferencesProvider));
});

class InputModeNotifier extends StateNotifier<InputMode> {
  InputModeNotifier(this._prefs) : super(_load(_prefs));

  final dynamic _prefs; // SharedPreferences?

  static InputMode _load(dynamic prefs) {
    if (prefs == null) return const InputMode();
    try {
      return InputMode(
        stylusDetected: prefs.getBool(_stylusDetectedKey) as bool? ?? false,
        drawWithFinger: prefs.getBool(_drawWithFingerKey) as bool? ?? false,
      );
    } catch (_) {
      return const InputMode();
    }
  }

  /// Called on a stylus pointer down; a no-op once stylus mode is on.
  void stylusSeen() {
    if (state.stylusDetected) return;
    state = state.copyWith(stylusDetected: true);
    _prefs?.setBool(_stylusDetectedKey, true);
  }

  /// "Draw with finger" setting. Turning it off also enables stylus mode, so
  /// the choice holds before a stylus has been seen.
  void setDrawWithFinger(bool value) {
    state = InputMode(
      stylusDetected: value ? state.stylusDetected : true,
      drawWithFinger: value,
    );
    _prefs?.setBool(_stylusDetectedKey, state.stylusDetected);
    _prefs?.setBool(_drawWithFingerKey, value);
  }
}

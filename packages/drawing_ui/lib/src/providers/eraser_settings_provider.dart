import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

// =============================================================================
// ERASER SETTINGS
// =============================================================================

/// SharedPreferences key for eraser settings.
const _eraserSettingsKey = 'starnote_eraser';

/// Eraser mode enum.
enum EraserMode { pixel, stroke, lasso }

/// Default eraser settings.
const _defaultEraserSettings = EraserSettings(
  mode: EraserMode.pixel,
  size: 20.0,
  pressureSensitive: true,
  eraseOnlyHighlighter: false,
  autoLift: false,
);

/// Eraser settings data model.
class EraserSettings {
  const EraserSettings({
    required this.mode,
    required this.size,
    required this.pressureSensitive,
    required this.eraseOnlyHighlighter,
    required this.autoLift,
  });

  final EraserMode mode;
  final double size;
  final bool pressureSensitive;
  final bool eraseOnlyHighlighter;
  final bool autoLift;

  EraserSettings copyWith({
    EraserMode? mode,
    double? size,
    bool? pressureSensitive,
    bool? eraseOnlyHighlighter,
    bool? autoLift,
  }) {
    return EraserSettings(
      mode: mode ?? this.mode,
      size: size ?? this.size,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      eraseOnlyHighlighter: eraseOnlyHighlighter ?? this.eraseOnlyHighlighter,
      autoLift: autoLift ?? this.autoLift,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'size': size,
      'pressureSensitive': pressureSensitive,
      'eraseOnlyHighlighter': eraseOnlyHighlighter,
      'autoLift': autoLift,
    };
  }

  factory EraserSettings.fromJson(Map<String, dynamic> json) {
    const d = _defaultEraserSettings;
    return EraserSettings(
      mode: EraserMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => d.mode,
      ),
      size: (json['size'] as num?)?.toDouble() ?? d.size,
      pressureSensitive:
          json['pressureSensitive'] as bool? ?? d.pressureSensitive,
      eraseOnlyHighlighter:
          json['eraseOnlyHighlighter'] as bool? ?? d.eraseOnlyHighlighter,
      autoLift: json['autoLift'] as bool? ?? d.autoLift,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory EraserSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return EraserSettings.fromJson(json);
  }
}

// =============================================================================
// ERASER SETTINGS PROVIDER
// =============================================================================

/// Eraser settings provider with SharedPreferences persistence.
final eraserSettingsProvider =
    StateNotifierProvider<EraserSettingsNotifier, EraserSettings>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return EraserSettingsNotifier(prefs);
  },
);

/// Notifier for eraser settings with persistence.
class EraserSettingsNotifier extends StateNotifier<EraserSettings> {
  EraserSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static EraserSettings _load(SharedPreferences? prefs) {
    if (prefs == null) return _defaultEraserSettings;
    final source = prefs.getString(_eraserSettingsKey);
    if (source != null) {
      try {
        return EraserSettings.fromJsonString(source);
      } catch (_) {
        // Invalid JSON, use defaults
      }
    }
    return _defaultEraserSettings;
  }

  Future<void> _save() async {
    await _prefs?.setString(_eraserSettingsKey, state.toJsonString());
  }

  void setMode(EraserMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setSize(double size) {
    state = state.copyWith(size: size);
    _save();
  }

  void setPressureSensitive(bool pressureSensitive) {
    state = state.copyWith(pressureSensitive: pressureSensitive);
    _save();
  }

  void setEraseOnlyHighlighter(bool eraseOnlyHighlighter) {
    state = state.copyWith(eraseOnlyHighlighter: eraseOnlyHighlighter);
    _save();
  }

  void setAutoLift(bool autoLift) {
    state = state.copyWith(autoLift: autoLift);
    _save();
  }
}

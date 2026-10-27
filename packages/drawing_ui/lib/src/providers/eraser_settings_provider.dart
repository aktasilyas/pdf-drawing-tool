import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/tool_providers.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

// =============================================================================
// ERASER SETTINGS
// =============================================================================

/// SharedPreferences key for eraser settings.
const _eraserSettingsKey = 'elyanotes_eraser';

/// Eraser mode enum.
enum EraserMode { pixel, stroke, lasso }

/// Eraser mode of an eraser [tool]; `null` for any other tool.
EraserMode? eraserModeForTool(ToolType tool) {
  return switch (tool) {
    ToolType.pixelEraser => EraserMode.pixel,
    ToolType.strokeEraser => EraserMode.stroke,
    ToolType.lassoEraser => EraserMode.lasso,
    _ => null,
  };
}

/// Eraser [ToolType] for [mode].
ToolType eraserToolForMode(EraserMode mode) {
  return switch (mode) {
    EraserMode.pixel => ToolType.pixelEraser,
    EraserMode.stroke => ToolType.strokeEraser,
    EraserMode.lasso => ToolType.lassoEraser,
  };
}

/// The eraser mode the canvas erases with: the current eraser tool decides,
/// so the toolbar, the panel and the canvas never disagree (#237). With a
/// non-eraser tool it is the last used eraser type ([EraserSettings.mode],
/// kept in sync by `currentToolProvider`), which the toolbar's eraser
/// button selects next.
final activeEraserModeProvider = Provider<EraserMode>((ref) {
  final tool = ref.watch(currentToolProvider);
  return eraserModeForTool(tool) ?? ref.watch(eraserSettingsProvider).mode;
});

/// Default eraser settings.
const _defaultEraserSettings = EraserSettings(
  mode: EraserMode.pixel,
  size: 20.0,
  // Off by default (#132): GoodNotes, Flexcil and StarNote erasers ignore
  // pen pressure, so the cursor is the eraser.
  pressureSensitive: false,
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

  /// Smallest share of [size] the eraser shrinks to at zero pressure.
  static const double minPressureScale = 0.3;

  /// Eraser diameter (screen px) at [pressure]: the single source for both
  /// the erase footprint and the cursor. Scales 30-100 % of [size] with
  /// pressure when [pressureSensitive] is on, otherwise always [size].
  double effectiveSize(double pressure) {
    if (!pressureSensitive) return size;
    final p = pressure.clamp(0.0, 1.0);
    return size * (minPressureScale + (1 - minPressureScale) * p);
  }

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

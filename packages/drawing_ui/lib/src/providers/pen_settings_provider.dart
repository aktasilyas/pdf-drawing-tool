import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

// =============================================================================
// PEN SETTINGS
// =============================================================================

/// SharedPreferences key prefix for pen settings.
const _penSettingsKeyPrefix = 'starnote_pen_';

/// Nib shape type for UI representation.
enum NibShapeType { circle, ellipse, rectangle }

/// Pen settings data model for UI state.
class PenSettings {
  const PenSettings({
    required this.color,
    required this.thickness,
    required this.stabilization,
    required this.nibShape,
    required this.pressureSensitive,
    this.pressureSensitivity = 0.75,
    this.nibAngle = 0.0,
    this.textured = false,
  });

  final Color color;
  final double thickness;
  final double stabilization;
  final NibShapeType nibShape;
  final bool pressureSensitive;
  final double pressureSensitivity;
  final double nibAngle;
  final bool textured;

  PenSettings copyWith({
    Color? color,
    double? thickness,
    double? stabilization,
    NibShapeType? nibShape,
    bool? pressureSensitive,
    double? pressureSensitivity,
    double? nibAngle,
    bool? textured,
  }) {
    return PenSettings(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      stabilization: stabilization ?? this.stabilization,
      nibShape: nibShape ?? this.nibShape,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
      nibAngle: nibAngle ?? this.nibAngle,
      textured: textured ?? this.textured,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'thickness': thickness,
      'stabilization': stabilization,
      'nibShape': nibShape.name,
      'pressureSensitive': pressureSensitive,
      'pressureSensitivity': pressureSensitivity,
      'nibAngle': nibAngle,
      'textured': textured,
    };
  }

  factory PenSettings.fromJson(Map<String, dynamic> json, PenSettings defaults) {
    return PenSettings(
      color: json['color'] is int ? Color(json['color'] as int) : defaults.color,
      thickness: (json['thickness'] as num?)?.toDouble() ?? defaults.thickness,
      stabilization:
          (json['stabilization'] as num?)?.toDouble() ?? defaults.stabilization,
      nibShape: NibShapeType.values.firstWhere(
        (e) => e.name == json['nibShape'],
        orElse: () => defaults.nibShape,
      ),
      pressureSensitive:
          json['pressureSensitive'] as bool? ?? defaults.pressureSensitive,
      pressureSensitivity: (json['pressureSensitivity'] as num?)?.toDouble() ??
          defaults.pressureSensitivity,
      nibAngle: (json['nibAngle'] as num?)?.toDouble() ?? defaults.nibAngle,
      textured: json['textured'] as bool? ?? defaults.textured,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PenSettings.fromJsonString(String source, PenSettings defaults) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return PenSettings.fromJson(json, defaults);
  }
}

// =============================================================================
// PEN SETTINGS PROVIDER
// =============================================================================

/// Settings for pen tools (family provider by tool type).
///
/// For pen tools with PenType, default values come from PenType.config.
final penSettingsProvider =
    StateNotifierProvider.family<PenSettingsNotifier, PenSettings, ToolType>(
  (ref, toolType) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final defaults = _defaultPenSettings(toolType);
    return PenSettingsNotifier(prefs, toolType, defaults);
  },
);

PenSettings _defaultPenSettings(ToolType toolType) {
  final penType = toolType.penType;
  if (penType != null) {
    final config = penType.config;
    return PenSettings(
      color: const Color(0xFF000000),
      thickness: config.defaultThickness,
      stabilization: 0.3,
      nibShape: _nibShapeFromCore(config.nibShape),
      pressureSensitive: config.pressureSensitive,
      pressureSensitivity: 0.75,
      textured: config.texture != StrokeTexture.none,
    );
  }

  return const PenSettings(
    color: Color(0xFF000000),
    thickness: 2.0,
    stabilization: 0.3,
    nibShape: NibShapeType.circle,
    pressureSensitive: false,
    pressureSensitivity: 0.75,
  );
}

/// Converts core NibShape to UI NibShapeType.
NibShapeType _nibShapeFromCore(NibShape nibShape) {
  switch (nibShape) {
    case NibShape.circle:
      return NibShapeType.circle;
    case NibShape.ellipse:
      return NibShapeType.ellipse;
    case NibShape.rectangle:
      return NibShapeType.rectangle;
  }
}

/// Notifier for pen settings state with SharedPreferences persistence.
class PenSettingsNotifier extends StateNotifier<PenSettings> {
  PenSettingsNotifier(this._prefs, this._toolType, PenSettings defaults)
      : super(_load(_prefs, _toolType, defaults));

  final SharedPreferences? _prefs;
  final ToolType _toolType;

  static PenSettings _load(
    SharedPreferences? prefs,
    ToolType toolType,
    PenSettings defaults,
  ) {
    if (prefs == null) return defaults;
    final key = '$_penSettingsKeyPrefix${toolType.name}';
    final source = prefs.getString(key);
    if (source != null) {
      try {
        return PenSettings.fromJsonString(source, defaults);
      } catch (_) {
        // Invalid JSON, use defaults
      }
    }
    return defaults;
  }

  Future<void> _save() async {
    final key = '$_penSettingsKeyPrefix${_toolType.name}';
    await _prefs?.setString(key, state.toJsonString());
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
    _save();
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
    _save();
  }

  void setStabilization(double stabilization) {
    state = state.copyWith(stabilization: stabilization);
    _save();
  }

  void setNibShape(NibShapeType nibShape) {
    state = state.copyWith(nibShape: nibShape);
    _save();
  }

  void setPressureSensitive(bool pressureSensitive) {
    state = state.copyWith(pressureSensitive: pressureSensitive);
    _save();
  }

  void setPressureSensitivity(double pressureSensitivity) {
    state = state.copyWith(pressureSensitivity: pressureSensitivity);
    _save();
  }

  void setNibAngle(double nibAngle) {
    state = state.copyWith(nibAngle: nibAngle);
    _save();
  }
}

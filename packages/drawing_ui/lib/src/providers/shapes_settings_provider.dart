import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key for shapes settings.
const _shapesSettingsKey = 'elyanotes_shapes';

/// Default shapes settings.
const _defaultShapesSettings = ShapesSettingsState(
  selectedShape: ShapeType.rectangle,
  strokeThickness: 2.0,
  strokeColor: Color(0xFF000000),
  fillEnabled: false,
  fillColor: Color(0x40000000),
);

/// Shapes settings provider with SharedPreferences persistence.
final shapesSettingsProvider =
    StateNotifierProvider<ShapesSettingsNotifier, ShapesSettingsState>(
  (ref) => ShapesSettingsNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Shape type enum - the ten most used shapes.
/// Maps one-to-one to the core ShapeType.
enum ShapeType {
  /// Straight line
  line,

  /// Arrow
  arrow,

  /// Rectangle
  rectangle,

  /// Ellipse / circle
  ellipse,

  /// Triangle
  triangle,

  /// Diamond (rhombus)
  diamond,

  /// Star
  star,

  /// Pentagon
  pentagon,

  /// Hexagon
  hexagon,

  /// Plus sign
  plus,
}

/// Shapes settings data model.
class ShapesSettingsState {
  const ShapesSettingsState({
    required this.selectedShape,
    required this.strokeThickness,
    required this.strokeColor,
    required this.fillEnabled,
    required this.fillColor,
  });

  final ShapeType selectedShape;
  final double strokeThickness;
  final Color strokeColor;
  final bool fillEnabled;
  final Color fillColor;

  ShapesSettingsState copyWith({
    ShapeType? selectedShape,
    double? strokeThickness,
    Color? strokeColor,
    bool? fillEnabled,
    Color? fillColor,
  }) {
    return ShapesSettingsState(
      selectedShape: selectedShape ?? this.selectedShape,
      strokeThickness: strokeThickness ?? this.strokeThickness,
      strokeColor: strokeColor ?? this.strokeColor,
      fillEnabled: fillEnabled ?? this.fillEnabled,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedShape': selectedShape.name,
      'strokeThickness': strokeThickness,
      'strokeColor': strokeColor.toARGB32(),
      'fillEnabled': fillEnabled,
      'fillColor': fillColor.toARGB32(),
    };
  }

  /// Reads stored settings; every missing, unknown or wrongly typed field
  /// falls back to its own default.
  factory ShapesSettingsState.fromJson(Map<String, dynamic> json) {
    const d = _defaultShapesSettings;
    final shape = ShapeType.values.asNameMap()[json['selectedShape']];
    final thickness = _positiveDouble(json['strokeThickness']);
    final strokeColor = json['strokeColor'];
    final fillEnabled = json['fillEnabled'];
    final fillColor = json['fillColor'];
    return ShapesSettingsState(
      selectedShape: shape ?? d.selectedShape,
      strokeThickness: thickness ?? d.strokeThickness,
      strokeColor: strokeColor is int ? Color(strokeColor) : d.strokeColor,
      fillEnabled: fillEnabled is bool ? fillEnabled : d.fillEnabled,
      fillColor: fillColor is int ? Color(fillColor) : d.fillColor,
    );
  }
}

double? _positiveDouble(Object? value) {
  if (value is num && value.isFinite && value > 0) return value.toDouble();
  return null;
}

/// Notifier for shapes settings with persistence. Null prefs (tests) keep
/// the settings in memory only.
class ShapesSettingsNotifier extends StateNotifier<ShapesSettingsState> {
  ShapesSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static ShapesSettingsState _load(SharedPreferences? prefs) {
    final source = prefs?.getString(_shapesSettingsKey);
    if (source == null) return _defaultShapesSettings;
    try {
      final json = jsonDecode(source);
      if (json is Map<String, dynamic>) {
        return ShapesSettingsState.fromJson(json);
      }
    } on FormatException {
      // Corrupt value: fall back to defaults.
    }
    return _defaultShapesSettings;
  }

  Future<void> _save() async {
    await _prefs?.setString(_shapesSettingsKey, jsonEncode(state.toJson()));
  }

  void setSelectedShape(ShapeType shape) {
    state = state.copyWith(selectedShape: shape);
    _save();
  }

  void setStrokeThickness(double thickness) {
    state = state.copyWith(strokeThickness: thickness);
    _save();
  }

  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColor: color);
    _save();
  }

  void setFillEnabled(bool enabled) {
    state = state.copyWith(fillEnabled: enabled);
    _save();
  }

  void setFillColor(Color color) {
    state = state.copyWith(fillColor: color);
    _save();
  }
}

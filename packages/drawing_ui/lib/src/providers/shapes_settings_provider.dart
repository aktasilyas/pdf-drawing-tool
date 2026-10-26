import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shapes settings provider.
final shapesSettingsProvider =
    StateNotifierProvider<ShapesSettingsNotifier, ShapesSettingsState>(
  (ref) => ShapesSettingsNotifier(const ShapesSettingsState(
    selectedShape: ShapeType.rectangle,
    strokeThickness: 2.0,
    strokeColor: Color(0xFF000000),
    fillEnabled: false,
    fillColor: Color(0x40000000),
  )),
);

/// Shape type enum - En cok kullanilan 10 sekil.
/// Core ShapeType ile birebir eslesir.
enum ShapeType {
  /// Duz cizgi
  line,

  /// Ok isareti
  arrow,

  /// Dikdortgen
  rectangle,

  /// Elips/Daire
  ellipse,

  /// Ucgen
  triangle,

  /// Eskenar dortgen
  diamond,

  /// Yildiz
  star,

  /// Besgen
  pentagon,

  /// Altigen
  hexagon,

  /// Arti isareti
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
}

/// Notifier for shapes settings.
class ShapesSettingsNotifier extends StateNotifier<ShapesSettingsState> {
  ShapesSettingsNotifier(super.state);

  void setSelectedShape(ShapeType shape) {
    state = state.copyWith(selectedShape: shape);
  }

  void setStrokeThickness(double thickness) {
    state = state.copyWith(strokeThickness: thickness);
  }

  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColor: color);
  }

  void setFillEnabled(bool enabled) {
    state = state.copyWith(fillEnabled: enabled);
  }

  void setFillColor(Color color) {
    state = state.copyWith(fillColor: color);
  }
}


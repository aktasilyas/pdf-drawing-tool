import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/pen_settings_provider.dart';

/// Pen box presets provider.
final penBoxPresetsProvider =
    StateNotifierProvider<PenBoxPresetsNotifier, List<PenPreset>>(
  (ref) => PenBoxPresetsNotifier(_defaultPenPresets()),
);

List<PenPreset> _defaultPenPresets() {
  return [];
}

/// Pen preset data model.
class PenPreset {
  const PenPreset({
    required this.id,
    this.toolType = ToolType.ballpointPen,
    this.color = const Color(0xFF000000),
    this.thickness = 2.0,
    this.nibShape = NibShapeType.circle,
    this.isEmpty = false,
  });

  final String id;
  final ToolType toolType;
  final Color color;
  final double thickness;
  final NibShapeType nibShape;
  final bool isEmpty;

  PenPreset copyWith({
    String? id,
    ToolType? toolType,
    Color? color,
    double? thickness,
    NibShapeType? nibShape,
    bool? isEmpty,
  }) {
    return PenPreset(
      id: id ?? this.id,
      toolType: toolType ?? this.toolType,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      nibShape: nibShape ?? this.nibShape,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }
}

/// Currently selected preset index.
final selectedPresetIndexProvider = StateProvider<int>((ref) => 0);

/// Notifier for pen box presets.
class PenBoxPresetsNotifier extends StateNotifier<List<PenPreset>> {
  PenBoxPresetsNotifier(super.state);

  void updatePreset(int index, PenPreset preset) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      preset,
      ...state.sublist(index + 1),
    ];
  }

  void addPreset(PenPreset preset) {
    final emptyIndex = state.indexWhere((p) => p.isEmpty);
    if (emptyIndex != -1) {
      updatePreset(emptyIndex, preset);
    } else {
      state = [...state, preset];
    }
  }

  void removePreset(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
  }
}


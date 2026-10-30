import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/pen_settings_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// SharedPreferences key for the pen box preset list.
const _presetsKey = 'elyanotes_pen_box_presets';

/// SharedPreferences key for the selected pen box preset index.
const _selectedIndexKey = 'elyanotes_pen_box_selected_index';

/// Pen box presets provider with SharedPreferences persistence.
final penBoxPresetsProvider =
    StateNotifierProvider<PenBoxPresetsNotifier, List<PenPreset>>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PenBoxPresetsNotifier(
      PenBoxPresetsNotifier.load(prefs),
      prefs: prefs,
    );
  },
);

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

  /// Serialises this preset for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolType': toolType.name,
      'color': color.toARGB32(),
      'thickness': thickness,
      'nibShape': nibShape.name,
      'isEmpty': isEmpty,
    };
  }

  /// Reads a stored preset, or returns null when the id, tool type, colour
  /// or thickness is missing or invalid. A missing or unknown nib shape and
  /// a missing isEmpty flag fall back to the defaults.
  static PenPreset? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final toolType = ToolType.values.asNameMap()[json['toolType']];
    final color = json['color'];
    final thickness = json['thickness'];
    if (id is! String || toolType == null || color is! int) return null;
    if (thickness is! num || !thickness.isFinite || thickness <= 0) {
      return null;
    }
    final nibShape = NibShapeType.values.asNameMap()[json['nibShape']];
    final isEmpty = json['isEmpty'];
    return PenPreset(
      id: id,
      toolType: toolType,
      color: Color(color),
      thickness: thickness.toDouble(),
      nibShape: nibShape ?? NibShapeType.circle,
      isEmpty: isEmpty is bool && isEmpty,
    );
  }
}

/// Currently selected preset index, persisted when prefs are available.
///
/// The stored index is clamped to the loaded preset list.
final selectedPresetIndexProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return 0;
  ref.listenSelf((_, next) => prefs.setInt(_selectedIndexKey, next));
  final stored = prefs.getInt(_selectedIndexKey) ?? 0;
  final count = ref.read(penBoxPresetsProvider).length;
  if (count == 0 || stored < 0) return 0;
  return stored < count ? stored : count - 1;
});

/// Notifier for pen box presets. With [prefs] every change is saved; without
/// them (tests) the list lives in memory only.
class PenBoxPresetsNotifier extends StateNotifier<List<PenPreset>> {
  PenBoxPresetsNotifier(super.state, {SharedPreferences? prefs})
      : _prefs = prefs;

  final SharedPreferences? _prefs;

  /// Loads the stored preset list. Unparsable JSON loads an empty list;
  /// invalid entries are skipped.
  static List<PenPreset> load(SharedPreferences? prefs) {
    final source = prefs?.getString(_presetsKey);
    if (source == null) return const [];
    try {
      final json = jsonDecode(source);
      if (json is! List) return const [];
      return json.map(PenPreset.tryFromJson).whereType<PenPreset>().toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _save() async {
    final encoded = jsonEncode(state.map((p) => p.toJson()).toList());
    await _prefs?.setString(_presetsKey, encoded);
  }

  void updatePreset(int index, PenPreset preset) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      preset,
      ...state.sublist(index + 1),
    ];
    _save();
  }

  void addPreset(PenPreset preset) {
    final emptyIndex = state.indexWhere((p) => p.isEmpty);
    if (emptyIndex != -1) {
      updatePreset(emptyIndex, preset);
    } else {
      state = [...state, preset];
      _save();
    }
  }

  void removePreset(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
    _save();
  }
}

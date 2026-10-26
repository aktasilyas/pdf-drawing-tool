import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// Lasso selection mode.
enum LassoMode {
  /// Free-form lasso selection (Serbest kement).
  freeform,

  /// Rectangle selection (Dikdortgen kement).
  rectangle,
}

/// Types of elements that can be selected with lasso tool.
enum SelectableType {
  /// Shapes (Sekil).
  shape,

  /// Images and stickers (Resim/Cikartma).
  imageSticker,

  /// Tape/washi elements (Bant).
  tape,

  /// Text boxes (Metin kutusu).
  textBox,

  /// Handwriting strokes (El yazisi).
  handwriting,

  /// Highlighter strokes (Vurgulayici).
  highlighter,

  /// Links (Baglanti).
  link,

  /// Labels (Etiket).
  label,
}

/// Lasso tool settings data model.
class LassoSettings {
  const LassoSettings({
    required this.mode,
    required this.selectableTypes,
  });

  /// The current lasso selection mode.
  final LassoMode mode;

  /// Map of selectable types and whether they are enabled.
  final Map<SelectableType, bool> selectableTypes;

  /// Default lasso settings matching PHASE1_UI_REFERENCE.md.
  factory LassoSettings.defaultSettings() {
    return LassoSettings(
      mode: LassoMode.freeform,
      selectableTypes: {
        SelectableType.shape: true,
        SelectableType.imageSticker: true,
        SelectableType.tape: true,
        SelectableType.textBox: true,
        SelectableType.handwriting: true,
        SelectableType.highlighter: false, // Default OFF per spec
        SelectableType.link: true,
        SelectableType.label: true,
      },
    );
  }

  LassoSettings copyWith({
    LassoMode? mode,
    Map<SelectableType, bool>? selectableTypes,
  }) {
    return LassoSettings(
      mode: mode ?? this.mode,
      selectableTypes: selectableTypes ?? Map.from(this.selectableTypes),
    );
  }

  /// Creates a copy with a single selectable type toggled.
  LassoSettings withSelectableType(SelectableType type, bool enabled) {
    final newTypes = Map<SelectableType, bool>.from(selectableTypes);
    newTypes[type] = enabled;
    return copyWith(selectableTypes: newTypes);
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'selectableTypes': {
        for (final e in selectableTypes.entries) e.key.name: e.value,
      },
    };
  }

  factory LassoSettings.fromJson(Map<String, dynamic> json) {
    final defaults = LassoSettings.defaultSettings();
    LassoMode mode = defaults.mode;
    if (json['mode'] is String) {
      try {
        mode = LassoMode.values.firstWhere((m) => m.name == json['mode']);
      } catch (_) {}
    }

    final selectableTypes =
        Map<SelectableType, bool>.from(defaults.selectableTypes);
    if (json['selectableTypes'] is Map) {
      final map = json['selectableTypes'] as Map;
      for (final type in SelectableType.values) {
        if (map.containsKey(type.name)) {
          selectableTypes[type] = map[type.name] as bool? ?? true;
        }
      }
    }

    return LassoSettings(mode: mode, selectableTypes: selectableTypes);
  }

  String toJsonString() => jsonEncode(toJson());

  factory LassoSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return LassoSettings.fromJson(json);
  }
}

/// SharedPreferences key for lasso settings.
const _lassoSettingsKey = 'elyanotes_lasso_settings';

/// Lasso settings provider with SharedPreferences persistence.
final lassoSettingsProvider =
    StateNotifierProvider<LassoSettingsNotifier, LassoSettings>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LassoSettingsNotifier(prefs);
  },
);

/// Notifier for lasso settings with persistence.
class LassoSettingsNotifier extends StateNotifier<LassoSettings> {
  LassoSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static LassoSettings _load(SharedPreferences? prefs) {
    if (prefs == null) return LassoSettings.defaultSettings();
    final source = prefs.getString(_lassoSettingsKey);
    if (source != null) {
      try {
        return LassoSettings.fromJsonString(source);
      } catch (_) {}
    }
    return LassoSettings.defaultSettings();
  }

  Future<void> _save() async {
    await _prefs?.setString(_lassoSettingsKey, state.toJsonString());
  }

  void setMode(LassoMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setSelectableType(SelectableType type, bool enabled) {
    state = state.withSelectableType(type, enabled);
    _save();
  }

  void setAllSelectableTypes(bool enabled) {
    final newTypes = <SelectableType, bool>{};
    for (final type in SelectableType.values) {
      newTypes[type] = enabled;
    }
    state = state.copyWith(selectableTypes: newTypes);
    _save();
  }
}


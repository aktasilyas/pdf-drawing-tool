import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

// =============================================================================
// HIGHLIGHTER SETTINGS
// =============================================================================

/// SharedPreferences key for highlighter settings.
const _highlighterSettingsKey = 'starnote_highlighter';

/// Default highlighter settings.
const _defaultHighlighterSettings = HighlighterSettings(
  color: Color(0x80FFEB3B),
  thickness: 20.0,
  straightLineMode: false,
  glowIntensity: 0.6,
);

/// Highlighter settings data model.
class HighlighterSettings {
  const HighlighterSettings({
    required this.color,
    required this.thickness,
    required this.straightLineMode,
    this.glowIntensity = 0.6,
  });

  final Color color;
  final double thickness;
  final bool straightLineMode;
  final double glowIntensity;

  HighlighterSettings copyWith({
    Color? color,
    double? thickness,
    bool? straightLineMode,
    double? glowIntensity,
  }) {
    return HighlighterSettings(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      straightLineMode: straightLineMode ?? this.straightLineMode,
      glowIntensity: glowIntensity ?? this.glowIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'thickness': thickness,
      'straightLineMode': straightLineMode,
      'glowIntensity': glowIntensity,
    };
  }

  factory HighlighterSettings.fromJson(Map<String, dynamic> json) {
    const d = _defaultHighlighterSettings;
    return HighlighterSettings(
      color: json['color'] is int ? Color(json['color'] as int) : d.color,
      thickness: (json['thickness'] as num?)?.toDouble() ?? d.thickness,
      straightLineMode: json['straightLineMode'] as bool? ?? d.straightLineMode,
      glowIntensity:
          (json['glowIntensity'] as num?)?.toDouble() ?? d.glowIntensity,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory HighlighterSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return HighlighterSettings.fromJson(json);
  }
}

// =============================================================================
// HIGHLIGHTER SETTINGS PROVIDER
// =============================================================================

/// Highlighter settings provider with SharedPreferences persistence.
final highlighterSettingsProvider =
    StateNotifierProvider<HighlighterSettingsNotifier, HighlighterSettings>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return HighlighterSettingsNotifier(prefs);
  },
);

/// Notifier for highlighter settings with persistence.
class HighlighterSettingsNotifier extends StateNotifier<HighlighterSettings> {
  HighlighterSettingsNotifier(this._prefs)
      : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static HighlighterSettings _load(SharedPreferences? prefs) {
    if (prefs == null) return _defaultHighlighterSettings;
    final source = prefs.getString(_highlighterSettingsKey);
    if (source != null) {
      try {
        return HighlighterSettings.fromJsonString(source);
      } catch (_) {
        // Invalid JSON, use defaults
      }
    }
    return _defaultHighlighterSettings;
  }

  Future<void> _save() async {
    await _prefs?.setString(_highlighterSettingsKey, state.toJsonString());
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
    _save();
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
    _save();
  }

  void setStraightLineMode(bool straightLineMode) {
    state = state.copyWith(straightLineMode: straightLineMode);
    _save();
  }

  void setGlowIntensity(double glowIntensity) {
    state = state.copyWith(glowIntensity: glowIntensity);
    _save();
  }
}

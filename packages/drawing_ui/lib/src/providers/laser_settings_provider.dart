import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// Laser pointer mode.
enum LaserMode {
  /// Line mode - draws a temporary line (Cizgi).
  line,

  /// Dot mode - shows a temporary dot (Nokta).
  dot,
}

/// Laser line drawing style (only applies in line mode).
enum LaserLineStyle {
  /// Solid neon glow line with bright core.
  solid,

  /// Hollow neon line - glow only, no bright core.
  hollow,

  /// Rainbow gradient along the path.
  rainbow,
}

/// Laser pointer settings data model.
class LaserSettings {
  const LaserSettings({
    required this.mode,
    required this.lineStyle,
    required this.thickness,
    required this.duration,
    required this.color,
  });

  /// The current laser mode (line or dot).
  final LaserMode mode;

  /// Line drawing style (solid / hollow / rainbow).
  final LaserLineStyle lineStyle;

  /// Thickness of the laser line/dot in mm.
  final double thickness;

  /// Duration the laser mark stays visible in seconds.
  final double duration;

  /// Color of the laser.
  final Color color;

  /// Default laser settings matching PHASE1_UI_REFERENCE.md.
  factory LaserSettings.defaultSettings() {
    return const LaserSettings(
      mode: LaserMode.line,
      lineStyle: LaserLineStyle.solid,
      thickness: 0.5,
      duration: 2.0,
      color: Color(0xFF29B6F6), // Light blue
    );
  }

  LaserSettings copyWith({
    LaserMode? mode,
    LaserLineStyle? lineStyle,
    double? thickness,
    double? duration,
    Color? color,
  }) {
    return LaserSettings(
      mode: mode ?? this.mode,
      lineStyle: lineStyle ?? this.lineStyle,
      thickness: thickness ?? this.thickness,
      duration: duration ?? this.duration,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'lineStyle': lineStyle.name,
      'thickness': thickness,
      'duration': duration,
      'color': color.toARGB32(),
    };
  }

  factory LaserSettings.fromJson(Map<String, dynamic> json) {
    final defaults = LaserSettings.defaultSettings();
    LaserMode mode = defaults.mode;
    if (json['mode'] is String) {
      try {
        mode = LaserMode.values.firstWhere((m) => m.name == json['mode']);
      } catch (_) {}
    }
    LaserLineStyle lineStyle = defaults.lineStyle;
    if (json['lineStyle'] is String) {
      try {
        lineStyle = LaserLineStyle.values
            .firstWhere((s) => s.name == json['lineStyle']);
      } catch (_) {}
    }
    return LaserSettings(
      mode: mode,
      lineStyle: lineStyle,
      thickness: (json['thickness'] as num?)?.toDouble() ?? defaults.thickness,
      duration: (json['duration'] as num?)?.toDouble() ?? defaults.duration,
      color:
          json['color'] is int ? Color(json['color'] as int) : defaults.color,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LaserSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return LaserSettings.fromJson(json);
  }
}

/// SharedPreferences key for laser settings.
const _laserSettingsKey = 'elyanotes_laser_settings';

/// Laser settings provider with SharedPreferences persistence.
final laserSettingsProvider =
    StateNotifierProvider<LaserSettingsNotifier, LaserSettings>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LaserSettingsNotifier(prefs);
  },
);

/// Notifier for laser settings with persistence.
class LaserSettingsNotifier extends StateNotifier<LaserSettings> {
  LaserSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static LaserSettings _load(SharedPreferences? prefs) {
    if (prefs == null) return LaserSettings.defaultSettings();
    final source = prefs.getString(_laserSettingsKey);
    if (source != null) {
      try {
        return LaserSettings.fromJsonString(source);
      } catch (_) {}
    }
    return LaserSettings.defaultSettings();
  }

  Future<void> _save() async {
    await _prefs?.setString(_laserSettingsKey, state.toJsonString());
  }

  void setMode(LaserMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setLineStyle(LaserLineStyle style) {
    state = state.copyWith(lineStyle: style);
    _save();
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
    _save();
  }

  void setDuration(double duration) {
    state = state.copyWith(duration: duration);
    _save();
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
    _save();
  }
}


import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

// ---------------------------------------------------------------------------
// Text Settings (default style for new text elements)
// ---------------------------------------------------------------------------

/// SharedPreferences key for text settings.
const _textSettingsKey = 'elyanotes_text_settings';

/// Default text settings.
const _defaultTextSettings = TextSettings();

/// Persistent settings for the text tool panel.
class TextSettings {
  final double fontSize;
  final int color;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  const TextSettings({
    this.fontSize = 16.0,
    this.color = 0xFF000000,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  TextSettings copyWith({
    double? fontSize,
    int? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    return TextSettings(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'color': color,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
    };
  }

  factory TextSettings.fromJson(Map<String, dynamic> json) {
    const d = _defaultTextSettings;
    return TextSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? d.fontSize,
      color: json['color'] as int? ?? d.color,
      isBold: json['isBold'] as bool? ?? d.isBold,
      isItalic: json['isItalic'] as bool? ?? d.isItalic,
      isUnderline: json['isUnderline'] as bool? ?? d.isUnderline,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TextSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return TextSettings.fromJson(json);
  }
}

/// Notifier for text settings with SharedPreferences persistence.
class TextSettingsNotifier extends StateNotifier<TextSettings> {
  TextSettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static TextSettings _load(SharedPreferences? prefs) {
    if (prefs == null) return _defaultTextSettings;
    final source = prefs.getString(_textSettingsKey);
    if (source != null) {
      try {
        return TextSettings.fromJsonString(source);
      } catch (_) {
        // Invalid JSON, use defaults
      }
    }
    return _defaultTextSettings;
  }

  Future<void> _save() async {
    await _prefs?.setString(_textSettingsKey, state.toJsonString());
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _save();
  }

  void setColor(int color) {
    state = state.copyWith(color: color);
    _save();
  }

  void toggleBold() {
    state = state.copyWith(isBold: !state.isBold);
    _save();
  }

  void toggleItalic() {
    state = state.copyWith(isItalic: !state.isItalic);
    _save();
  }

  void toggleUnderline() {
    state = state.copyWith(isUnderline: !state.isUnderline);
    _save();
  }
}

/// Provider for default text settings with SharedPreferences persistence.
final textSettingsProvider =
    StateNotifierProvider<TextSettingsNotifier, TextSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TextSettingsNotifier(prefs);
});

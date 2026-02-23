import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

/// Text tool state
class TextToolState {
  final bool isEditing;
  final TextElement? activeText;
  final bool isNewText; // true = yeni oluşturuluyor, false = mevcut düzenleniyor
  final bool showMenu; // Menu gösteriliyor mu?
  final TextElement? menuText; // Hangi text için menu gösteriliyor?
  final bool showStylePopup; // Stil popup gösteriliyor mu?
  final TextElement? styleText; // Hangi text için stil düzenleniyor?
  final bool isMoving; // Taşıma modu aktif mi?
  final TextElement? movingText; // Hangi text taşınıyor?

  const TextToolState({
    this.isEditing = false,
    this.activeText,
    this.isNewText = true,
    this.showMenu = false,
    this.menuText,
    this.showStylePopup = false,
    this.styleText,
    this.isMoving = false,
    this.movingText,
  });

  TextToolState copyWith({
    bool? isEditing,
    TextElement? activeText,
    bool? isNewText,
    bool? showMenu,
    TextElement? menuText,
    bool? showStylePopup,
    TextElement? styleText,
    bool? isMoving,
    TextElement? movingText,
  }) {
    return TextToolState(
      isEditing: isEditing ?? this.isEditing,
      activeText: activeText ?? this.activeText,
      isNewText: isNewText ?? this.isNewText,
      showMenu: showMenu ?? this.showMenu,
      menuText: menuText ?? this.menuText,
      showStylePopup: showStylePopup ?? this.showStylePopup,
      styleText: styleText ?? this.styleText,
      isMoving: isMoving ?? this.isMoving,
      movingText: movingText ?? this.movingText,
    );
  }
}

/// Text tool notifier
class TextToolNotifier extends StateNotifier<TextToolState> {
  TextToolNotifier() : super(const TextToolState());

  /// Yeni text oluşturmaya başla
  void startNewText(
    double x,
    double y, {
    double fontSize = 16.0,
    int color = 0xFF000000,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    final text = TextElement.create(
      text: '',
      x: x,
      y: y,
      fontSize: fontSize,
      color: color,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
    );

    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: true,
    );
  }

  /// Mevcut text'i düzenlemeye başla
  void editExistingText(TextElement text) {
    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: false,
    );
  }

  /// Text içeriğini güncelle
  void updateText(TextElement updatedText) {
    state = state.copyWith(activeText: updatedText);
  }

  /// Düzenlemeyi bitir
  TextElement? finishEditing() {
    final result = state.activeText;
    state = const TextToolState();
    return result;
  }

  /// Düzenlemeyi iptal et
  void cancelEditing() {
    state = const TextToolState();
  }

  /// Text için context menu göster
  void showContextMenu(TextElement text) {
    state = TextToolState(
      showMenu: true,
      menuText: text,
    );
  }

  /// Context menu'yu kapat
  void hideContextMenu() {
    state = const TextToolState();
  }

  /// Stil popup'ı göster
  void showStylePopup(TextElement text) {
    state = TextToolState(
      showStylePopup: true,
      styleText: text,
    );
  }

  /// Stil popup'ı kapat
  void hideStylePopup() {
    state = const TextToolState();
  }

  /// Taşıma modunu başlat
  void startMoving(TextElement text) {
    state = TextToolState(
      isMoving: true,
      movingText: text,
    );
  }

  /// Taşıma modunu iptal et
  void cancelMoving() {
    state = const TextToolState();
  }
}

/// Text tool provider
final textToolProvider =
    StateNotifierProvider<TextToolNotifier, TextToolState>((ref) {
  return TextToolNotifier();
});

/// Aktif layer'daki texts
final activeLayerTextsProvider = Provider<List<TextElement>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return [];
  return document.layers[document.activeLayerIndex].texts;
});

// ---------------------------------------------------------------------------
// Text Settings (default style for new text elements)
// ---------------------------------------------------------------------------

/// SharedPreferences key for text settings.
const _textSettingsKey = 'starnote_text_settings';

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

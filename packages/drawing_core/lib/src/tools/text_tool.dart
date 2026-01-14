import 'package:drawing_core/drawing_core.dart';

/// Text aracı
class TextTool {
  final double defaultFontSize;
  final int defaultColor;
  final String defaultFontFamily;

  TextElement? _activeText;
  bool _isEditing = false;

  TextTool({
    this.defaultFontSize = 16.0,
    this.defaultColor = 0xFF000000,
    this.defaultFontFamily = 'Roboto',
  });

  /// Yeni text oluşturmaya başla
  TextElement startText(double x, double y) {
    _activeText = TextElement.create(
      text: '',
      x: x,
      y: y,
      fontSize: defaultFontSize,
      color: defaultColor,
      fontFamily: defaultFontFamily,
    );
    _isEditing = true;
    return _activeText!;
  }

  /// Mevcut text'i düzenlemeye başla
  void editText(TextElement text) {
    _activeText = text;
    _isEditing = true;
  }

  /// Text içeriğini güncelle
  TextElement? updateText(String newText) {
    if (_activeText == null) return null;
    _activeText = _activeText!.copyWith(text: newText);
    return _activeText;
  }

  /// Text stilini güncelle
  TextElement? updateStyle({
    double? fontSize,
    int? color,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    TextAlignment? alignment,
  }) {
    if (_activeText == null) return null;
    _activeText = _activeText!.copyWith(
      fontSize: fontSize,
      color: color,
      fontFamily: fontFamily,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      alignment: alignment,
    );
    return _activeText;
  }

  /// Düzenlemeyi bitir ve TextElement döndür
  TextElement? endText() {
    if (_activeText == null || !_isEditing) return null;

    _isEditing = false;

    // Boş text'i kaydetme
    if (_activeText!.text.trim().isEmpty) {
      _activeText = null;
      return null;
    }

    final result = _activeText;
    _activeText = null;
    return result;
  }

  /// Düzenlemeyi iptal et
  void cancelText() {
    _activeText = null;
    _isEditing = false;
  }

  /// Aktif text
  TextElement? get activeText => _activeText;

  /// Düzenleme modunda mı?
  bool get isEditing => _isEditing;
}

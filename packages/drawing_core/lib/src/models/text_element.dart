import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';

/// Text alignment options.
enum TextAlignment {
  /// Align text to the left.
  left,

  /// Center align text.
  center,

  /// Align text to the right.
  right,
}

/// Represents a text element in a drawing.
///
/// A [TextElement] contains styled text positioned at a specific location.
/// It supports font styling, alignment, and optional width/height constraints.
///
/// Example:
/// ```dart
/// final text = TextElement.create(
///   text: 'Hello World',
///   x: 100,
///   y: 200,
///   fontSize: 24,
///   color: 0xFF000000,
///   isBold: true,
/// );
/// ```
class TextElement {
  /// Unique identifier for the text element.
  final String id;

  /// The text content.
  final String text;

  /// X-coordinate of the text position.
  final double x;

  /// Y-coordinate of the text position.
  final double y;

  /// Font size in logical pixels.
  final double fontSize;

  /// Text color in ARGB32 format.
  final int color;

  /// Font family name.
  final String fontFamily;

  /// Whether the text is bold.
  final bool isBold;

  /// Whether the text is italic.
  final bool isItalic;

  /// Whether the text is underlined.
  final bool isUnderline;

  /// Text alignment.
  final TextAlignment alignment;

  /// Optional width constraint (null = auto width).
  final double? width;

  /// Optional height constraint (null = auto height).
  final double? height;

  /// Rotation angle in radians.
  final double rotation;

  const TextElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16.0,
    this.color = 0xFF000000,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.alignment = TextAlignment.left,
    this.width,
    this.height,
    this.rotation = 0.0,
  });

  /// Creates a new text element with a generated ID.
  ///
  /// Use this factory to create a new text element when the user adds text.
  factory TextElement.create({
    required String text,
    required double x,
    required double y,
    double fontSize = 16.0,
    int color = 0xFF000000,
    String fontFamily = 'Roboto',
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    TextAlignment alignment = TextAlignment.left,
    double? width,
    double? height,
    double rotation = 0.0,
  }) {
    return TextElement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      x: x,
      y: y,
      fontSize: fontSize,
      color: color,
      fontFamily: fontFamily,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      alignment: alignment,
      width: width,
      height: height,
      rotation: rotation,
    );
  }

  /// Boş mu?
  bool get isEmpty => text.isEmpty;

  /// Boş değil mi?
  bool get isNotEmpty => text.isNotEmpty;

  /// Bounding box (tahmini - gerçek boyut render'da hesaplanır)
  BoundingBox get bounds {
    final lineHeight = fontSize * 1.2;
    final lines = text.split('\n');

    double maxLineWidth = 0;
    for (final line in lines) {
      final runes = line.runes.toList();
      final hasEmoji = runes.any((r) => r > 0xFF);
      if (hasEmoji) {
        maxLineWidth = math.max(maxLineWidth,
            _countVisibleGlyphs(runes) * fontSize);
      } else {
        maxLineWidth = math.max(maxLineWidth,
            runes.length * fontSize * 0.6);
      }
    }

    final w = width ?? maxLineWidth;
    final h = height ?? (lines.length * lineHeight);

    if (rotation == 0.0) {
      return BoundingBox(left: x, top: y, right: x + w, bottom: y + h);
    }
    // Rotated bounding box
    final cx = x + w / 2;
    final cy = y + h / 2;
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    // Rotate four corners and find axis-aligned envelope
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final corner in [
      (x, y), (x + w, y), (x + w, y + h), (x, y + h),
    ]) {
      final dx = corner.$1 - cx;
      final dy = corner.$2 - cy;
      final rx = cx + dx * cosR - dy * sinR;
      final ry = cy + dx * sinR + dy * cosR;
      if (rx < minX) minX = rx;
      if (rx > maxX) maxX = rx;
      if (ry < minY) minY = ry;
      if (ry > maxY) maxY = ry;
    }
    return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
  }

  /// Counts visible glyphs by collapsing ZWJ sequences and skipping
  /// invisible modifiers (variation selectors, skin tones, etc.).
  static int _countVisibleGlyphs(List<int> runes) {
    int count = 0;
    bool joinedToPrev = false;
    for (final rune in runes) {
      if (rune == 0x200D) { joinedToPrev = true; continue; } // ZWJ
      if (_isInvisibleModifier(rune)) continue;
      if (!joinedToPrev) count++;
      joinedToPrev = false;
    }
    return math.max(count, 1);
  }

  static bool _isInvisibleModifier(int rune) =>
      (rune >= 0xFE00 && rune <= 0xFE0F) || // Variation selectors
      (rune >= 0x1F3FB && rune <= 0x1F3FF) || // Skin tone modifiers
      rune == 0x20E3; // Combining enclosing keycap

  /// Hit test - nokta text üzerinde mi?
  bool containsPoint(double px, double py, double tolerance) {
    final b = bounds;
    return px >= b.left - tolerance &&
        px <= b.right + tolerance &&
        py >= b.top - tolerance &&
        py <= b.bottom + tolerance;
  }

  /// Immutable copy
  TextElement copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? color,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    TextAlignment? alignment,
    double? width,
    double? height,
    double? rotation,
  }) {
    return TextElement(
      id: id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      alignment: alignment ?? this.alignment,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'color': color,
        'fontFamily': fontFamily,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'alignment': alignment.name,
        'width': width,
        'height': height,
        'rotation': rotation,
      };

  factory TextElement.fromJson(Map<String, dynamic> json) {
    // Safe number parsing
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }
    
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }
    
    return TextElement(
      id: json['id'],
      text: json['text'],
      x: parseDouble(json['x'], 0.0),
      y: parseDouble(json['y'], 0.0),
      fontSize: parseDouble(json['fontSize'], 16.0),
      color: parseInt(json['color'], 0xFF000000),
      fontFamily: json['fontFamily'] ?? 'Roboto',
      isBold: json['isBold'] ?? false,
      isItalic: json['isItalic'] ?? false,
      isUnderline: json['isUnderline'] ?? false,
      alignment: TextAlignment.values.byName(json['alignment'] ?? 'left'),
      width: json['width'] != null ? parseDouble(json['width'], 0.0) : null,
      height: json['height'] != null ? parseDouble(json['height'], 0.0) : null,
      rotation: parseDouble(json['rotation'], 0.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextElement) return false;
    return other.id == id &&
        other.text == text &&
        other.x == x &&
        other.y == y &&
        other.fontSize == fontSize &&
        other.color == color &&
        other.fontFamily == fontFamily &&
        other.isBold == isBold &&
        other.isItalic == isItalic &&
        other.isUnderline == isUnderline &&
        other.alignment == alignment &&
        other.width == width &&
        other.height == height &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(id, text, x, y, fontSize, color, rotation);
}

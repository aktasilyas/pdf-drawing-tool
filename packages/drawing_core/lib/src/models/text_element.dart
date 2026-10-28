import 'dart:math' as math;

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/element_ids.dart';

part 'text_element_bounds.dart';
part 'text_element_json.dart';

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
      id: ElementIds.next(),
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
  BoundingBox get bounds => _estimateTextBounds(this);

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
    String? id,
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
      id: id ?? this.id,
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
  Map<String, dynamic> toJson() => _textElementToJson(this);

  /// JSON deserialization
  factory TextElement.fromJson(Map<String, dynamic> json) =>
      _textElementFromJson(json);

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

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
    );
  }

  /// Boş mu?
  bool get isEmpty => text.isEmpty;

  /// Boş değil mi?
  bool get isNotEmpty => text.isNotEmpty;

  /// Bounding box (tahmini - gerçek boyut render'da hesaplanır)
  BoundingBox get bounds {
    // Tahmini karakter genişliği
    final charWidth = fontSize * 0.6;
    final lineHeight = fontSize * 1.2;

    // Satır sayısı
    final lines = text.split('\n');
    final maxLineLength = lines.isEmpty
        ? 0
        : lines.map((l) => l.length).reduce((a, b) => a > b ? a : b);

    final estimatedWidth = width ?? (maxLineLength * charWidth);
    final estimatedHeight = height ?? (lines.length * lineHeight);

    return BoundingBox(
      left: x,
      top: y,
      right: x + estimatedWidth,
      bottom: y + estimatedHeight,
    );
  }

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
      };

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      id: json['id'],
      text: json['text'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: json['color'] ?? 0xFF000000,
      fontFamily: json['fontFamily'] ?? 'Roboto',
      isBold: json['isBold'] ?? false,
      isItalic: json['isItalic'] ?? false,
      isUnderline: json['isUnderline'] ?? false,
      alignment: TextAlignment.values.byName(json['alignment'] ?? 'left'),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextElement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

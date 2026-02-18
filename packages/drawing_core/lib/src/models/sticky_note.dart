import 'package:drawing_core/drawing_core.dart';

/// Represents a sticky note element on the canvas.
///
/// A colored rectangular area that can be positioned, resized, and
/// recolored. Supports serialization and undo/redo via history commands.
/// Internal [strokes] and [shapes] use coordinates relative to the note's
/// origin.
class StickyNote {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;

  /// ARGB32 color value. Default yellow: 0xFFFFF3CD.
  final int color;

  /// Whether the note is minimized (shown as a small icon).
  final bool minimized;

  /// Strokes drawn inside this note (relative coordinates).
  final List<Stroke> strokes;

  /// Shapes drawn inside this note (relative coordinates).
  final List<Shape> shapes;

  StickyNote({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.color = 0xFFFFF3CD,
    this.minimized = false,
    List<Stroke>? strokes,
    List<Shape>? shapes,
  })  : strokes = strokes != null
            ? List<Stroke>.unmodifiable(strokes)
            : const [],
        shapes = shapes != null
            ? List<Shape>.unmodifiable(shapes)
            : const [];

  /// Creates a new sticky note with a generated ID.
  factory StickyNote.create({
    required double x,
    required double y,
    double width = 200,
    double height = 200,
    int color = 0xFFFFF3CD,
    bool minimized = false,
  }) {
    return StickyNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      minimized: minimized,
    );
  }

  /// Size of the minimized icon.
  static const double minimizedSize = 48.0;

  BoundingBox get bounds {
    if (minimized) {
      return BoundingBox(
        left: x,
        top: y,
        right: x + minimizedSize,
        bottom: y + minimizedSize,
      );
    }
    return BoundingBox(left: x, top: y, right: x + width, bottom: y + height);
  }

  bool containsPoint(double px, double py, double tolerance) {
    final w = minimized ? minimizedSize : width;
    final h = minimized ? minimizedSize : height;
    return px >= x - tolerance &&
        px <= x + w + tolerance &&
        py >= y - tolerance &&
        py <= y + h + tolerance;
  }

  StickyNote copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    int? color,
    bool? minimized,
    List<Stroke>? strokes,
    List<Shape>? shapes,
  }) {
    return StickyNote(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      minimized: minimized ?? this.minimized,
      strokes: strokes ?? this.strokes,
      shapes: shapes ?? this.shapes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'color': color,
        'minimized': minimized,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'shapes': shapes.map((s) => s.toJson()).toList(),
      };

  factory StickyNote.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return StickyNote(
      id: json['id'] as String,
      x: parseDouble(json['x'], 0.0),
      y: parseDouble(json['y'], 0.0),
      width: parseDouble(json['width'], 200.0),
      height: parseDouble(json['height'], 200.0),
      color: json['color'] as int? ?? 0xFFFFF3CD,
      minimized: json['minimized'] as bool? ?? false,
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      shapes: (json['shapes'] as List<dynamic>?)
              ?.map((s) => Shape.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StickyNote) return false;
    if (other.id != id ||
        other.x != x ||
        other.y != y ||
        other.width != width ||
        other.height != height ||
        other.color != color ||
        other.minimized != minimized) {
      return false;
    }
    if (other.strokes.length != strokes.length ||
        other.shapes.length != shapes.length) {
      return false;
    }
    for (int i = 0; i < strokes.length; i++) {
      if (other.strokes[i] != strokes[i]) return false;
    }
    for (int i = 0; i < shapes.length; i++) {
      if (other.shapes[i] != shapes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      id, x, y, width, height, color, minimized,
      strokes.length, shapes.length);
}

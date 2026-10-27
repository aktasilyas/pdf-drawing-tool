import 'package:equatable/equatable.dart';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/image_element.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/sticky_note.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/text_element.dart';

part 'layer_element_ops.dart';
part 'layer_stroke_ops.dart';

/// Represents a layer in a drawing document.
///
/// A [Layer] contains a collection of [Stroke]s and [Shape]s, and has properties
/// like visibility, lock state, and opacity.
///
/// This class is immutable - all modification methods return a new [Layer].
class Layer extends Equatable with _LayerStrokeOps, _LayerElementOps {
  /// Unique identifier for the layer.
  final String id;

  /// Display name of the layer.
  final String name;

  /// The strokes contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<Stroke> strokes;

  /// The shapes contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<Shape> shapes;

  /// The text elements contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<TextElement> texts;

  /// The image elements contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<ImageElement> images;

  /// The sticky note elements contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<StickyNote> stickyNotes;

  /// Explicit render order for all element types.
  ///
  /// When non-empty, the unified painter uses this order instead of
  /// type-based layering. Contains IDs of [Stroke]s, [Shape]s,
  /// [ImageElement]s, and [TextElement]s.
  final List<String> elementOrder;

  /// Whether this layer is visible.
  final bool isVisible;

  /// Whether this layer is locked (cannot be modified).
  final bool isLocked;

  /// The opacity of this layer (0.0 to 1.0).
  final double opacity;

  /// Creates a new [Layer].
  ///
  /// The [strokes], [shapes], and [texts] lists are wrapped in [List.unmodifiable]
  /// to ensure immutability.
  /// [opacity] is clamped to the range [0.0, 1.0].
  Layer({
    required this.id,
    required this.name,
    required List<Stroke> strokes,
    List<Shape>? shapes,
    List<TextElement>? texts,
    List<ImageElement>? images,
    List<StickyNote>? stickyNotes,
    List<String>? elementOrder,
    this.isVisible = true,
    this.isLocked = false,
    double opacity = 1.0,
  })  : strokes = List.unmodifiable(strokes),
        shapes = List.unmodifiable(shapes ?? const []),
        texts = List.unmodifiable(texts ?? const []),
        images = List.unmodifiable(images ?? const []),
        stickyNotes = List.unmodifiable(stickyNotes ?? const []),
        elementOrder = List.unmodifiable(elementOrder ?? const []),
        opacity = opacity.clamp(0.0, 1.0);

  /// Creates an empty layer with a generated ID.
  factory Layer.empty(String name) {
    return Layer(
      id: _generateId(),
      name: name,
      strokes: const [],
      shapes: const [],
      texts: const [],
      images: const [],
      stickyNotes: const [],
      elementOrder: const [],
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return 'layer_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Whether this layer has no strokes, shapes, texts, or images.
  bool get isEmpty =>
      strokes.isEmpty &&
      shapes.isEmpty &&
      texts.isEmpty &&
      images.isEmpty &&
      stickyNotes.isEmpty;

  /// Whether this layer has at least one stroke, shape, text, image, or sticky note.
  bool get isNotEmpty =>
      strokes.isNotEmpty ||
      shapes.isNotEmpty ||
      texts.isNotEmpty ||
      images.isNotEmpty ||
      stickyNotes.isNotEmpty;

  /// The number of strokes in this layer.
  int get strokeCount => strokes.length;

  /// The number of shapes in this layer.
  int get shapeCount => shapes.length;

  /// The number of text elements in this layer.
  int get textCount => texts.length;

  /// The number of image elements in this layer.
  int get imageCount => images.length;

  // ============================================================
  // COMMON METHODS
  // ============================================================

  /// Creates a copy of this [Layer] with the given fields replaced.
  Layer copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    List<Shape>? shapes,
    List<TextElement>? texts,
    List<ImageElement>? images,
    List<StickyNote>? stickyNotes,
    List<String>? elementOrder,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      shapes: shapes ?? this.shapes,
      texts: texts ?? this.texts,
      images: images ?? this.images,
      stickyNotes: stickyNotes ?? this.stickyNotes,
      elementOrder: elementOrder ?? this.elementOrder,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
    );
  }

  /// Converts this [Layer] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'shapes': shapes.map((s) => s.toJson()).toList(),
      'texts': texts.map((t) => t.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'stickyNotes': stickyNotes.map((n) => n.toJson()).toList(),
      'elementOrder': elementOrder,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
    };
  }

  /// Creates a [Layer] from a JSON map.
  factory Layer.fromJson(Map<String, dynamic> json) {
    return Layer(
      id: json['id'] as String,
      name: json['name'] as String,
      strokes: (json['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      shapes: (json['shapes'] as List?)
              ?.map((s) => Shape.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      texts: (json['texts'] as List?)
              ?.map((t) => TextElement.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      images: (json['images'] as List?)
              ?.map((i) => ImageElement.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      stickyNotes: (json['stickyNotes'] as List?)
              ?.map((n) => StickyNote.fromJson(n as Map<String, dynamic>))
              .toList() ??
          const [],
      elementOrder:
          (json['elementOrder'] as List?)?.map((e) => e as String).toList() ??
              const [],
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        strokes,
        shapes,
        texts,
        images,
        stickyNotes,
        elementOrder,
        isVisible,
        isLocked,
        opacity
      ];

  @override
  String toString() {
    return 'Layer(id: $id, name: $name, strokeCount: $strokeCount, '
        'shapeCount: $shapeCount, textCount: $textCount, imageCount: $imageCount, '
        'isVisible: $isVisible, isLocked: $isLocked, opacity: $opacity)';
  }
}

import 'package:equatable/equatable.dart';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/image_element.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/sticky_note.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/text_element.dart';

/// Represents a layer in a drawing document.
///
/// A [Layer] contains a collection of [Stroke]s and [Shape]s, and has properties
/// like visibility, lock state, and opacity.
///
/// This class is immutable - all modification methods return a new [Layer].
class Layer extends Equatable {
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
    this.isVisible = true,
    this.isLocked = false,
    double opacity = 1.0,
  })  : strokes = List.unmodifiable(strokes),
        shapes = List.unmodifiable(shapes ?? const []),
        texts = List.unmodifiable(texts ?? const []),
        images = List.unmodifiable(images ?? const []),
        stickyNotes = List.unmodifiable(stickyNotes ?? const []),
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
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return 'layer_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Whether this layer has no strokes, shapes, texts, or images.
  bool get isEmpty =>
      strokes.isEmpty && shapes.isEmpty && texts.isEmpty && images.isEmpty && stickyNotes.isEmpty;

  /// Whether this layer has at least one stroke, shape, text, image, or sticky note.
  bool get isNotEmpty =>
      strokes.isNotEmpty || shapes.isNotEmpty || texts.isNotEmpty || images.isNotEmpty || stickyNotes.isNotEmpty;

  /// The number of strokes in this layer.
  int get strokeCount => strokes.length;

  /// The number of shapes in this layer.
  int get shapeCount => shapes.length;

  /// The number of text elements in this layer.
  int get textCount => texts.length;

  /// The number of image elements in this layer.
  int get imageCount => images.length;

  // ============================================================
  // STROKE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given stroke added.
  ///
  /// The original layer is not modified.
  Layer addStroke(Stroke stroke) {
    return Layer(
      id: id,
      name: name,
      strokes: [...strokes, stroke],
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the stroke matching [strokeId] removed.
  ///
  /// If no stroke with the given ID exists, returns a copy of this layer.
  /// The original layer is not modified.
  Layer removeStroke(String strokeId) {
    final newStrokes = strokes.where((s) => s.id != strokeId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: newStrokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the stroke updated.
  ///
  /// The stroke is matched by ID. If no matching stroke is found,
  /// returns a copy of this layer unchanged.
  /// The original layer is not modified.
  Layer updateStroke(Stroke stroke) {
    final index = strokes.indexWhere((s) => s.id == stroke.id);
    if (index == -1) {
      return copyWith();
    }

    final newStrokes = List<Stroke>.from(strokes);
    newStrokes[index] = stroke;

    return Layer(
      id: id,
      name: name,
      strokes: newStrokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with all strokes, shapes, and texts removed.
  ///
  /// The original layer is not modified.
  Layer clear() {
    return Layer(
      id: id,
      name: name,
      strokes: const [],
      shapes: const [],
      texts: const [],
      images: const [],
      stickyNotes: const [],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the stroke with the given [id], or null if not found.
  Stroke? getStrokeById(String strokeId) {
    for (final stroke in strokes) {
      if (stroke.id == strokeId) {
        return stroke;
      }
    }
    return null;
  }

  /// Finds all strokes that intersect with the given [rect].
  ///
  /// This is a stub implementation for Phase 2.
  /// Full implementation will be done in Phase 3.
  ///
  /// Returns an empty list (stub).
  List<Stroke> findStrokesInRect(BoundingBox rect) {
    // TODO: Implement in Phase 3
    // Will check stroke bounds intersection with rect
    return const [];
  }

  // ============================================================
  // SHAPE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given shape added.
  ///
  /// The original layer is not modified.
  Layer addShape(Shape shape) {
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: [...shapes, shape],
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the shape matching [shapeId] removed.
  ///
  /// If no shape with the given ID exists, returns a copy of this layer.
  /// The original layer is not modified.
  Layer removeShape(String shapeId) {
    final newShapes = shapes.where((s) => s.id != shapeId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: newShapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the shape updated.
  ///
  /// The shape is matched by ID. If no matching shape is found,
  /// returns a copy of this layer unchanged.
  /// The original layer is not modified.
  Layer updateShape(Shape shape) {
    final index = shapes.indexWhere((s) => s.id == shape.id);
    if (index == -1) {
      return copyWith();
    }

    final newShapes = List<Shape>.from(shapes);
    newShapes[index] = shape;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: newShapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the shape with the given [id], or null if not found.
  Shape? getShapeById(String shapeId) {
    for (final shape in shapes) {
      if (shape.id == shapeId) {
        return shape;
      }
    }
    return null;
  }

  // ============================================================
  // TEXT METHODS
  // ============================================================

  /// Returns a new [Layer] with the given text element added.
  ///
  /// The original layer is not modified.
  Layer addText(TextElement text) {
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: [...texts, text],
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the text matching [textId] removed.
  ///
  /// If no text with the given ID exists, returns a copy of this layer.
  /// The original layer is not modified.
  Layer removeText(String textId) {
    final newTexts = texts.where((t) => t.id != textId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: newTexts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the text updated.
  ///
  /// The text is matched by ID. If no matching text is found,
  /// returns a copy of this layer unchanged.
  /// The original layer is not modified.
  Layer updateText(TextElement text) {
    final index = texts.indexWhere((t) => t.id == text.id);
    if (index == -1) {
      return copyWith();
    }

    final newTexts = List<TextElement>.from(texts);
    newTexts[index] = text;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: newTexts,
      images: images,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the text element with the given [id], or null if not found.
  TextElement? getTextById(String textId) {
    for (final text in texts) {
      if (text.id == textId) {
        return text;
      }
    }
    return null;
  }

  // ============================================================
  // IMAGE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given image element added.
  Layer addImage(ImageElement image) {
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: [...images, image],
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the image matching [imageId] removed.
  Layer removeImage(String imageId) {
    final newImages = images.where((i) => i.id != imageId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: newImages,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the image updated.
  Layer updateImage(ImageElement image) {
    final index = images.indexWhere((i) => i.id == image.id);
    if (index == -1) {
      return copyWith();
    }

    final newImages = List<ImageElement>.from(images);
    newImages[index] = image;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: newImages,
      stickyNotes: stickyNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the image element with the given [id], or null if not found.
  ImageElement? getImageById(String imageId) {
    for (final image in images) {
      if (image.id == imageId) {
        return image;
      }
    }
    return null;
  }

  // ============================================================
  // STICKY NOTE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given sticky note added.
  Layer addStickyNote(StickyNote note) {
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: [...stickyNotes, note],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the sticky note matching [noteId] removed.
  Layer removeStickyNote(String noteId) {
    final newNotes = stickyNotes.where((n) => n.id != noteId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: newNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the sticky note updated.
  Layer updateStickyNote(StickyNote note) {
    final index = stickyNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      return copyWith();
    }

    final newNotes = List<StickyNote>.from(stickyNotes);
    newNotes[index] = note;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: newNotes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the sticky note with the given [id], or null if not found.
  StickyNote? getStickyNoteById(String noteId) {
    for (final note in stickyNotes) {
      if (note.id == noteId) {
        return note;
      }
    }
    return null;
  }

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
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, strokes, shapes, texts, images, stickyNotes, isVisible, isLocked, opacity];

  @override
  String toString() {
    return 'Layer(id: $id, name: $name, strokeCount: $strokeCount, '
        'shapeCount: $shapeCount, textCount: $textCount, imageCount: $imageCount, '
        'isVisible: $isVisible, isLocked: $isLocked, opacity: $opacity)';
  }
}

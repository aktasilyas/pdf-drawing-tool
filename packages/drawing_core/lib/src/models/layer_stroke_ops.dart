part of 'layer.dart';

/// Stroke and shape operations for [Layer].
///
/// Kept in a mixin so `layer.dart` stays small; every method returns a
/// new [Layer].
mixin _LayerStrokeOps {
  String get id;
  String get name;
  List<Stroke> get strokes;
  List<Shape> get shapes;
  List<TextElement> get texts;
  List<ImageElement> get images;
  List<StickyNote> get stickyNotes;
  List<String> get elementOrder;
  List<UnreadableElement> get unreadableElements;
  bool get isVisible;
  bool get isLocked;
  double get opacity;

  /// Implemented by [Layer]; declared here for the element mixins.
  Layer copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    List<Shape>? shapes,
    List<TextElement>? texts,
    List<ImageElement>? images,
    List<StickyNote>? stickyNotes,
    List<String>? elementOrder,
    List<UnreadableElement>? unreadableElements,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
  });

  // ============================================================
  // STROKE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given stroke added.
  ///
  /// The original layer is not modified.
  Layer addStroke(Stroke stroke) {
    if (elementOrder.contains(stroke.id)) return this as Layer;
    return Layer(
      id: id,
      name: name,
      strokes: [...strokes, stroke],
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      elementOrder: [...elementOrder, stroke.id],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
      elementOrder: elementOrder.where((id) => id != strokeId).toList(),
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
      elementOrder: const [],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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

  /// Finds all strokes whose bounds intersect with the given [rect].
  ///
  /// Uses a bounding-box (AABB) test; touching edges do not count.
  List<Stroke> findStrokesInRect(BoundingBox rect) {
    return strokes.where((stroke) {
      final bounds = stroke.bounds;
      if (bounds == null) return false;
      return bounds.left < rect.right &&
          bounds.right > rect.left &&
          bounds.top < rect.bottom &&
          bounds.bottom > rect.top;
    }).toList();
  }

  // ============================================================
  // SHAPE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given shape added.
  ///
  /// The original layer is not modified.
  Layer addShape(Shape shape) {
    if (elementOrder.contains(shape.id)) return this as Layer;
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: [...shapes, shape],
      texts: texts,
      images: images,
      stickyNotes: stickyNotes,
      elementOrder: [...elementOrder, shape.id],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
      elementOrder: elementOrder.where((id) => id != shapeId).toList(),
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
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
}

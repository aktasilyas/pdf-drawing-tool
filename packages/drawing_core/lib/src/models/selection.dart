import 'package:equatable/equatable.dart';
import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';

/// Simple 2D point for selection handle positions.
/// Used instead of dart:ui Offset to keep drawing_core pure Dart.
class Point2D extends Equatable {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'Point2D($x, $y)';
}

/// Selection type - how the selection was created.
enum SelectionType {
  /// Free-form lasso selection
  lasso,

  /// Rectangle selection
  rectangle,
}

/// Selection handle positions for resize/transform operations.
enum SelectionHandle {
  topLeft,
  topCenter,
  topRight,
  middleLeft,
  middleRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  center, // For dragging/moving
}

/// Extension to get handle positions from bounds.
extension SelectionHandlePosition on SelectionHandle {
  /// Returns the position of this handle for the given bounds.
  Point2D getPosition(BoundingBox bounds) {
    switch (this) {
      case SelectionHandle.topLeft:
        return Point2D(bounds.left, bounds.top);
      case SelectionHandle.topCenter:
        return Point2D((bounds.left + bounds.right) / 2, bounds.top);
      case SelectionHandle.topRight:
        return Point2D(bounds.right, bounds.top);
      case SelectionHandle.middleLeft:
        return Point2D(bounds.left, (bounds.top + bounds.bottom) / 2);
      case SelectionHandle.middleRight:
        return Point2D(bounds.right, (bounds.top + bounds.bottom) / 2);
      case SelectionHandle.bottomLeft:
        return Point2D(bounds.left, bounds.bottom);
      case SelectionHandle.bottomCenter:
        return Point2D((bounds.left + bounds.right) / 2, bounds.bottom);
      case SelectionHandle.bottomRight:
        return Point2D(bounds.right, bounds.bottom);
      case SelectionHandle.center:
        return Point2D(
          (bounds.left + bounds.right) / 2,
          (bounds.top + bounds.bottom) / 2,
        );
    }
  }
}

/// Represents a selection of strokes and shapes on the canvas.
///
/// A selection contains:
/// - A list of selected stroke IDs
/// - A list of selected shape IDs
/// - The bounding box enclosing all selected items
/// - The selection type (lasso or rectangle)
/// - Optional lasso path for free-form selections
///
/// This class is immutable.
class Selection extends Equatable {
  /// Unique identifier for this selection.
  final String id;

  /// How the selection was created.
  final SelectionType type;

  /// IDs of selected strokes.
  final List<String> selectedStrokeIds;

  /// IDs of selected shapes.
  final List<String> selectedShapeIds;

  /// IDs of selected images.
  final List<String> selectedImageIds;

  /// IDs of selected text elements (regular text + emoji stickers).
  final List<String> selectedTextIds;

  /// Bounding box enclosing all selected items.
  final BoundingBox bounds;

  /// The lasso path points (only for lasso selections).
  final List<DrawingPoint>? lassoPath;

  /// Creates a new [Selection].
  const Selection({
    required this.id,
    required this.type,
    required this.selectedStrokeIds,
    this.selectedShapeIds = const [],
    this.selectedImageIds = const [],
    this.selectedTextIds = const [],
    required this.bounds,
    this.lassoPath,
  });

  /// Factory - creates a new selection with a unique ID.
  factory Selection.create({
    required SelectionType type,
    required List<String> selectedStrokeIds,
    List<String> selectedShapeIds = const [],
    List<String> selectedImageIds = const [],
    List<String> selectedTextIds = const [],
    required BoundingBox bounds,
    List<DrawingPoint>? lassoPath,
  }) {
    return Selection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      selectedStrokeIds: List.unmodifiable(selectedStrokeIds),
      selectedShapeIds: List.unmodifiable(selectedShapeIds),
      selectedImageIds: List.unmodifiable(selectedImageIds),
      selectedTextIds: List.unmodifiable(selectedTextIds),
      bounds: bounds,
      lassoPath: lassoPath != null ? List.unmodifiable(lassoPath) : null,
    );
  }

  /// Creates an empty selection.
  factory Selection.empty() {
    return Selection(
      id: '',
      type: SelectionType.rectangle,
      selectedStrokeIds: const [],
      selectedShapeIds: const [],
      selectedImageIds: const [],
      selectedTextIds: const [],
      bounds: BoundingBox.zero(),
    );
  }

  /// Whether the selection is empty (no strokes, shapes, images, or texts selected).
  bool get isEmpty =>
      selectedStrokeIds.isEmpty &&
      selectedShapeIds.isEmpty &&
      selectedImageIds.isEmpty &&
      selectedTextIds.isEmpty;

  /// Whether the selection has items.
  bool get isNotEmpty =>
      selectedStrokeIds.isNotEmpty ||
      selectedShapeIds.isNotEmpty ||
      selectedImageIds.isNotEmpty ||
      selectedTextIds.isNotEmpty;

  /// Total number of selected items (strokes + shapes + images + texts).
  int get count =>
      selectedStrokeIds.length +
      selectedShapeIds.length +
      selectedImageIds.length +
      selectedTextIds.length;

  /// Number of selected strokes.
  int get strokeCount => selectedStrokeIds.length;

  /// Number of selected shapes.
  int get shapeCount => selectedShapeIds.length;

  /// Number of selected images.
  int get imageCount => selectedImageIds.length;

  /// Number of selected text elements.
  int get textCount => selectedTextIds.length;

  /// Center point of the selection.
  Point2D get center => Point2D(
        (bounds.left + bounds.right) / 2,
        (bounds.top + bounds.bottom) / 2,
      );

  /// Width of the selection bounds.
  double get width => bounds.right - bounds.left;

  /// Height of the selection bounds.
  double get height => bounds.bottom - bounds.top;

  /// Checks if a stroke is in this selection.
  bool containsStroke(String strokeId) {
    return selectedStrokeIds.contains(strokeId);
  }

  /// Checks if a shape is in this selection.
  bool containsShape(String shapeId) {
    return selectedShapeIds.contains(shapeId);
  }

  /// Checks if an image is in this selection.
  bool containsImage(String imageId) {
    return selectedImageIds.contains(imageId);
  }

  /// Checks if a text element is in this selection.
  bool containsText(String textId) {
    return selectedTextIds.contains(textId);
  }

  /// Creates a copy with updated fields.
  Selection copyWith({
    String? id,
    SelectionType? type,
    List<String>? selectedStrokeIds,
    List<String>? selectedShapeIds,
    List<String>? selectedImageIds,
    List<String>? selectedTextIds,
    BoundingBox? bounds,
    List<DrawingPoint>? lassoPath,
  }) {
    return Selection(
      id: id ?? this.id,
      type: type ?? this.type,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      selectedShapeIds: selectedShapeIds ?? this.selectedShapeIds,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      bounds: bounds ?? this.bounds,
      lassoPath: lassoPath ?? this.lassoPath,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'selectedStrokeIds': selectedStrokeIds,
        'selectedShapeIds': selectedShapeIds,
        'selectedImageIds': selectedImageIds,
        'selectedTextIds': selectedTextIds,
        'bounds': bounds.toJson(),
        if (lassoPath != null)
          'lassoPath': lassoPath!.map((p) => p.toJson()).toList(),
      };

  /// Creates from JSON map.
  factory Selection.fromJson(Map<String, dynamic> json) {
    return Selection(
      id: json['id'] as String,
      type: SelectionType.values.byName(json['type'] as String),
      selectedStrokeIds: List<String>.from(json['selectedStrokeIds'] as List),
      selectedShapeIds: json['selectedShapeIds'] != null
          ? List<String>.from(json['selectedShapeIds'] as List)
          : const [],
      selectedImageIds: json['selectedImageIds'] != null
          ? List<String>.from(json['selectedImageIds'] as List)
          : const [],
      selectedTextIds: json['selectedTextIds'] != null
          ? List<String>.from(json['selectedTextIds'] as List)
          : const [],
      bounds: BoundingBox.fromJson(json['bounds'] as Map<String, dynamic>),
      lassoPath: json['lassoPath'] != null
          ? (json['lassoPath'] as List)
              .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, selectedStrokeIds, selectedShapeIds, selectedImageIds, selectedTextIds, bounds, lassoPath];

  @override
  String toString() {
    return 'Selection(id: $id, type: $type, count: $count, bounds: $bounds)';
  }
}

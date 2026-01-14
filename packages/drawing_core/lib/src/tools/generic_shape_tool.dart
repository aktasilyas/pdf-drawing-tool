import 'package:drawing_core/drawing_core.dart';

/// Generic shape tool for any shape type.
///
/// This tool can be used for shapes that don't need
/// special handling (triangle, diamond, star, pentagon, hexagon, plus).
class GenericShapeTool extends ShapeTool {
  /// The shape type to create.
  final ShapeType _shapeType;

  /// İçi dolu mu?
  final bool filled;

  /// Constructor
  GenericShapeTool({
    required super.style,
    required ShapeType shapeType,
    super.fillColor,
    this.filled = false,
  }) : _shapeType = shapeType;

  @override
  ShapeType get shapeType => _shapeType;

  @override
  bool get isFilled => filled;
}

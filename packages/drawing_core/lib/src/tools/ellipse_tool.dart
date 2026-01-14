import 'package:drawing_core/drawing_core.dart';

/// Elips/Daire aracı
class EllipseTool extends ShapeTool {
  /// İçi dolu mu?
  final bool filled;

  /// Constructor
  EllipseTool({
    required super.style,
    super.fillColor,
    this.filled = false,
  });

  @override
  ShapeType get shapeType => ShapeType.ellipse;

  @override
  bool get isFilled => filled;
}

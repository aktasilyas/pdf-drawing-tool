import 'package:drawing_core/drawing_core.dart';

/// Dikdörtgen aracı
class RectangleTool extends ShapeTool {
  /// İçi dolu mu?
  final bool filled;

  /// Constructor
  RectangleTool({
    required super.style,
    this.filled = false,
  });

  @override
  ShapeType get shapeType => ShapeType.rectangle;

  @override
  bool get isFilled => filled;
}

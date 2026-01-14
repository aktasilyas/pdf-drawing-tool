import 'package:drawing_core/drawing_core.dart';

/// Düz çizgi aracı
class LineTool extends ShapeTool {
  /// Constructor
  LineTool({required super.style});

  @override
  ShapeType get shapeType => ShapeType.line;
}

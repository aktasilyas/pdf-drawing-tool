import 'package:drawing_core/drawing_core.dart';

/// Ok aracı
class ArrowTool extends ShapeTool {
  /// Constructor
  ArrowTool({required super.style});

  @override
  ShapeType get shapeType => ShapeType.arrow;
}

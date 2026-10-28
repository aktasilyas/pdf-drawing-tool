import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/drawing_strings.dart';

/// Localized names for [ShapeType].
extension ShapeTypeLabel on ShapeType {
  /// The user-facing name of this shape in the given strings.
  String label(DrawingStrings s) {
    final c = s.catalog;
    switch (this) {
      case ShapeType.line:
        return c.shapeLine;
      case ShapeType.arrow:
        return c.shapeArrow;
      case ShapeType.rectangle:
        return c.shapeRectangle;
      case ShapeType.ellipse:
        return c.shapeEllipse;
      case ShapeType.triangle:
        return c.shapeTriangle;
      case ShapeType.diamond:
        return c.shapeDiamond;
      case ShapeType.star:
        return c.shapeStar;
      case ShapeType.pentagon:
        return c.shapePentagon;
      case ShapeType.hexagon:
        return c.shapeHexagon;
      case ShapeType.plus:
        return c.shapePlus;
    }
  }
}

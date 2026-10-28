import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/drawing_strings.dart';
import 'package:drawing_ui/src/models/selection_action_kind.dart';

/// Localized names for [SelectionActionKind].
extension SelectionActionKindLabel on SelectionActionKind {
  /// The user-facing label of this action in the given strings.
  String label(DrawingStrings s) {
    final c = s.selection;
    switch (this) {
      case SelectionActionKind.ai:
        return c.ai;
      case SelectionActionKind.color:
        return c.color;
      case SelectionActionKind.screenshot:
        return c.screenshot;
      case SelectionActionKind.cut:
        return c.cut;
      case SelectionActionKind.duplicate:
        return c.duplicate;
      case SelectionActionKind.delete:
        return c.delete;
      case SelectionActionKind.bringToFront:
        return c.bringToFront;
      case SelectionActionKind.sendToBack:
        return c.sendToBack;
      case SelectionActionKind.copy:
        return c.copy;
      case SelectionActionKind.paste:
        return c.paste;
      case SelectionActionKind.askAi:
        return c.askAi;
      case SelectionActionKind.takeScreenshot:
        return c.takeScreenshot;
    }
  }
}

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

import 'package:flutter_pen_toolbar/flutter_pen_toolbar.dart' as toolbar;
import 'package:drawing_core/drawing_core.dart';

/// Maps between flutter_pen_toolbar PenType and drawing_core PenType.
///
/// This utility class provides bidirectional conversion between the
/// pen types used in the toolbar package and the core drawing library.
class PenTypeMapper {
  /// Converts drawing_core PenType to flutter_pen_toolbar PenType.
  static toolbar.PenType toToolbarPenType(PenType penType) {
    switch (penType) {
      case PenType.pencil:
        return toolbar.PenType.pencil;
      case PenType.hardPencil:
        return toolbar.PenType.pencilTip;
      case PenType.ballpointPen:
        return toolbar.PenType.ballpointPen;
      case PenType.gelPen:
        return toolbar.PenType.gelPen;
      case PenType.dashedPen:
        return toolbar.PenType.dashedPen;
      case PenType.highlighter:
        return toolbar.PenType.highlighter;
      case PenType.brushPen:
        return toolbar.PenType.brushPen;
      case PenType.neonHighlighter:
        return toolbar.PenType.neonHighlighter;
      case PenType.rulerPen:
        return toolbar.PenType.rulerPen;
    }
  }

  /// Converts flutter_pen_toolbar PenType to drawing_core PenType.
  static PenType fromToolbarPenType(toolbar.PenType toolbarType) {
    switch (toolbarType) {
      case toolbar.PenType.pencil:
        return PenType.pencil;
      case toolbar.PenType.pencilTip:
        return PenType.hardPencil;
      case toolbar.PenType.ballpointPen:
        return PenType.ballpointPen;
      case toolbar.PenType.gelPen:
        return PenType.gelPen;
      case toolbar.PenType.dashedPen:
        return PenType.dashedPen;
      case toolbar.PenType.highlighter:
        return PenType.highlighter;
      case toolbar.PenType.brushPen:
        return PenType.brushPen;
      case toolbar.PenType.neonHighlighter:
        return PenType.neonHighlighter;
      case toolbar.PenType.rulerPen:
        return PenType.rulerPen;
      // Fallback for toolbar types not in drawing_core
      case toolbar.PenType.pen:
      case toolbar.PenType.marker:
      case toolbar.PenType.fountainPen:
      case toolbar.PenType.fineliner:
      case toolbar.PenType.crayon:
        return PenType.ballpointPen;
    }
  }

  /// Checks if a toolbar PenType has a corresponding drawing_core PenType.
  static bool isSupported(toolbar.PenType toolbarType) {
    return const [
      toolbar.PenType.pencil,
      toolbar.PenType.pencilTip,
      toolbar.PenType.ballpointPen,
      toolbar.PenType.gelPen,
      toolbar.PenType.dashedPen,
      toolbar.PenType.highlighter,
      toolbar.PenType.brushPen,
      toolbar.PenType.neonHighlighter,
      toolbar.PenType.rulerPen,
    ].contains(toolbarType);
  }
}

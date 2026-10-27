import 'package:drawing_ui/src/l10n/drawing_strings.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

/// Localized names for [ToolType].
extension ToolTypeLabel on ToolType {
  /// The user-facing name of this tool in the given strings.
  String label(DrawingStrings s) {
    final t = s.tools;
    switch (this) {
      case ToolType.fountainPen:
        return t.fountainPen;
      case ToolType.pencil:
        return t.pencil;
      case ToolType.hardPencil:
        return t.hardPencil;
      case ToolType.ballpointPen:
        return t.ballpointPen;
      case ToolType.gelPen:
        return t.gelPen;
      case ToolType.dashedPen:
        return t.dashedPen;
      case ToolType.highlighter:
        return t.highlighter;
      case ToolType.brushPen:
        return t.brushPen;
      case ToolType.neonHighlighter:
        return t.neonHighlighter;
      case ToolType.rulerPen:
        return t.rulerPen;
      case ToolType.pixelEraser:
        return t.pixelEraser;
      case ToolType.strokeEraser:
        return t.strokeEraser;
      case ToolType.lassoEraser:
        return t.lassoEraser;
      case ToolType.shapes:
        return t.shapes;
      case ToolType.text:
        return t.text;
      case ToolType.sticker:
        return t.sticker;
      case ToolType.image:
        return t.image;
      case ToolType.selection:
        return t.selection;
      case ToolType.panZoom:
        return t.panZoom;
      case ToolType.laserPointer:
        return t.laserPointer;
      case ToolType.stickyNote:
        return t.stickyNote;
      case ToolType.toolbarSettings:
        return t.toolbarSettings;
    }
  }
}

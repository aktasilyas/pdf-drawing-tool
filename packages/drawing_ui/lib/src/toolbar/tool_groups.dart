import 'package:drawing_ui/src/models/models.dart';

/// Pen tool types (grouped as one button in toolbar).
const List<ToolType> penTools = [
  ToolType.pencil,
  ToolType.hardPencil,
  ToolType.ballpointPen,
  ToolType.gelPen,
  ToolType.dashedPen,
  ToolType.brushPen,
  ToolType.rulerPen,
];

/// Highlighter tool types (grouped as one button in toolbar).
const List<ToolType> highlighterTools = [
  ToolType.highlighter,
  ToolType.neonHighlighter,
];

/// Tools that have a settings panel.
const Set<ToolType> toolsWithPanel = {
  ToolType.pencil,
  ToolType.hardPencil,
  ToolType.ballpointPen,
  ToolType.gelPen,
  ToolType.dashedPen,
  ToolType.brushPen,
  ToolType.neonHighlighter,
  ToolType.highlighter,
  ToolType.pixelEraser,
  ToolType.strokeEraser,
  ToolType.lassoEraser,
  ToolType.shapes,
  ToolType.sticker,
  ToolType.image,
  ToolType.laserPointer,
  ToolType.selection,
};

/// Pen tools as a Set (for anchor resolution in panels).
const Set<ToolType> penToolsSet = {
  ToolType.pencil,
  ToolType.hardPencil,
  ToolType.ballpointPen,
  ToolType.gelPen,
  ToolType.dashedPen,
  ToolType.brushPen,
  ToolType.rulerPen,
};

/// Highlighter tools as a Set (for anchor resolution in panels).
const Set<ToolType> highlighterToolsSet = {
  ToolType.highlighter,
  ToolType.neonHighlighter,
};

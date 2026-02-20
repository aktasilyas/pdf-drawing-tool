/// Panel builders and helpers for the drawing screen.
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';

/// Build the active tool panel widget.
Widget buildActivePanel({
  required ToolType panel,
  bool isPenPickerMode = false,
  ValueChanged<ToolType>? onPenSelected,
}) {
  // Pen picker mode — compact pen list
  if (isPenPickerMode && penToolsSet.contains(panel)) {
    return PenTypePicker(onPenSelected: onPenSelected);
  }

  switch (panel) {
    case ToolType.pencil:
    case ToolType.hardPencil:
    case ToolType.ballpointPen:
    case ToolType.gelPen:
    case ToolType.dashedPen:
    case ToolType.brushPen:
    case ToolType.rulerPen:
      return PenSettingsPanel(toolType: panel);

    case ToolType.highlighter:
    case ToolType.neonHighlighter:
      return const HighlighterSettingsPanel();

    case ToolType.pixelEraser:
    case ToolType.strokeEraser:
    case ToolType.lassoEraser:
      return const EraserSettingsPanel();

    case ToolType.shapes:
      return const ShapesSettingsPanel();

    case ToolType.sticker:
      return const StickerPanel();

    case ToolType.image:
      return const ImagePanel();

    case ToolType.selection:
      return const LassoSelectionPanel();

    case ToolType.laserPointer:
      return const LaserPointerPanel();

    case ToolType.stickyNote:
      return const StickyNotePanel();

    case ToolType.text:
      return const TextSettingsPanel();

    case ToolType.panZoom:
      return const SizedBox.shrink();

    case ToolType.toolbarSettings:
      return const ToolbarSettingsPanel();
  }
}


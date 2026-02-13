/// Panel builders and helpers for the drawing screen.
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/panels.dart';

/// Build the active tool panel widget.
Widget buildActivePanel({
  required ToolType panel,
}) {
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

    case ToolType.text:
      return const _TextToolPanel();

    case ToolType.panZoom:
      return const SizedBox.shrink();

    case ToolType.toolbarSettings:
      return const ToolbarSettingsPanel();
  }
}

/// Simple text tool panel (placeholder).
class _TextToolPanel extends StatelessWidget {
  const _TextToolPanel();

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Text',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap on the canvas to add a text box.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          PanelSection(
            title: 'FONT SIZE',
            child: Slider(
              value: 16,
              min: 8,
              max: 72,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 16),
          const PanelSection(
            title: 'TEXT COLOR',
            child: Row(
              children: [
                _ColorDot(color: Colors.black, isSelected: true),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.blue),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.red),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Simple color dot widget.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    this.isSelected = false,
  });

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
      ),
    );
  }
}
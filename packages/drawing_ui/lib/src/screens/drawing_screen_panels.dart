/// Panel builders and helpers for the drawing screen.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/widgets/anchored_panel.dart';

/// Determine panel alignment based on tool's position in toolbar.
AnchorAlignment resolvePanelAlignment(ToolType tool) {
  const rightTools = {
    ToolType.laserPointer,
  };

  if (penToolsSet.contains(tool)) {
    return AnchorAlignment.left;
  }
  if (rightTools.contains(tool)) {
    return AnchorAlignment.right;
  }
  return AnchorAlignment.center;
}

/// Build the active tool panel widget.
Widget buildActivePanel({
  required ToolType panel,
  required VoidCallback onClose,
}) {
  switch (panel) {
    case ToolType.pencil:
    case ToolType.hardPencil:
    case ToolType.ballpointPen:
    case ToolType.gelPen:
    case ToolType.dashedPen:
    case ToolType.brushPen:
    case ToolType.rulerPen:
      return PenSettingsPanel(
        toolType: panel,
        onClose: onClose,
      );

    case ToolType.highlighter:
    case ToolType.neonHighlighter:
      return HighlighterSettingsPanel(onClose: onClose);

    case ToolType.pixelEraser:
    case ToolType.strokeEraser:
    case ToolType.lassoEraser:
      return EraserSettingsPanel(onClose: onClose);

    case ToolType.shapes:
      return ShapesSettingsPanel(onClose: onClose);

    case ToolType.sticker:
      return StickerPanel(onClose: onClose);

    case ToolType.image:
      return ImagePanel(onClose: onClose);

    case ToolType.selection:
      return LassoSelectionPanel(onClose: onClose);

    case ToolType.laserPointer:
      return _LaserPointerPanel(onClose: onClose);

    case ToolType.text:
      return _TextToolPanel(onClose: onClose);

    case ToolType.panZoom:
      return const SizedBox.shrink();

    case ToolType.toolbarSettings:
      return ToolbarSettingsPanel(onClose: onClose);
  }
}

/// Simple text tool panel (placeholder).
class _TextToolPanel extends StatelessWidget {
  const _TextToolPanel({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Text',
      onClose: onClose,
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

/// Simple laser pointer panel (placeholder).
class _LaserPointerPanel extends StatelessWidget {
  const _LaserPointerPanel({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Laser Pointer',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelSection(
            title: 'MODE',
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Dot',
                    icon: StarNoteIcons.circle,
                    isSelected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Trail',
                    icon: StarNoteIcons.selection,
                    isSelected: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PanelSection(
            title: 'COLOR',
            child: Row(
              children: [
                _ColorDot(color: Colors.red, isSelected: true),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.green),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.blue),
                const SizedBox(width: 8),
                _ColorDot(color: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PanelSection(
            title: 'DURATION',
            child: Slider(
              value: 2,
              min: 0.5,
              max: 5,
              divisions: 9,
              label: '2s',
              onChanged: (_) {},
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

/// Mode button for laser pointer.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final PhosphorIconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

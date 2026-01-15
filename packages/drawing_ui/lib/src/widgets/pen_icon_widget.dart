import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import '../painters/pen_icons/pen_icons.dart';

/// Widget that displays a custom pen icon based on pen type.
///
/// Uses custom painters to render premium, realistic pen icons
/// with gradients, shadows, and 3D depth effects.
///
/// The [orientation] parameter controls the pen direction:
/// - [PenOrientation.vertical]: Tip points UP (for popup/settings)
/// - [PenOrientation.horizontal]: Tip points RIGHT (for PenBox)
class PenIconWidget extends StatelessWidget {
  /// The pen type to display.
  final PenType penType;

  /// The color of the pen tip/ink.
  final Color color;

  /// Whether the pen is currently selected.
  final bool isSelected;

  /// The size of the icon.
  final double size;

  /// The orientation of the pen icon.
  ///
  /// - [PenOrientation.vertical]: Tip points UP (default, for popups)
  /// - [PenOrientation.horizontal]: Tip points RIGHT (for PenBox)
  final PenOrientation orientation;

  const PenIconWidget({
    super.key,
    required this.penType,
    this.color = Colors.black,
    this.isSelected = false,
    this.size = 56.0,
    this.orientation = PenOrientation.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _getPainter(),
    );
  }

  PenIconPainter _getPainter() {
    switch (penType) {
      case PenType.pencil:
        return PencilIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.hardPencil:
        return HardPencilIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.ballpointPen:
        return BallpointIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.gelPen:
        return GelPenIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.dashedPen:
        return DashedPenIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.highlighter:
        return HighlighterIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.brushPen:
        return BrushPenIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.neonHighlighter:
        return NeonHighlighterIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
      case PenType.rulerPen:
        return RulerPenIconPainter(
          penColor: color,
          isSelected: isSelected,
          size: size,
          orientation: orientation,
        );
    }
  }
}

/// Convenience widget for ToolType-based icon display.
///
/// Automatically maps ToolType to PenType and displays
/// the appropriate custom pen icon.
class ToolPenIcon extends StatelessWidget {
  /// The tool type to display.
  final ToolType toolType;

  /// Optional color override for the pen tip.
  final Color? color;

  /// Whether the tool is currently selected.
  final bool isSelected;

  /// The size of the icon.
  final double size;

  /// The orientation of the pen icon.
  final PenOrientation orientation;

  const ToolPenIcon({
    super.key,
    required this.toolType,
    this.color,
    this.isSelected = false,
    this.size = 48.0,
    this.orientation = PenOrientation.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final penType = toolType.penType;
    if (penType == null) {
      // Non-pen tool, return placeholder icon
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.edit, size: size * 0.5),
      );
    }

    return PenIconWidget(
      penType: penType,
      color: color ?? Colors.black,
      isSelected: isSelected,
      size: size,
      orientation: orientation,
    );
  }
}

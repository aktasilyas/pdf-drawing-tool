import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_pen_toolbar/flutter_pen_toolbar.dart' as toolbar;
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/utils/pen_type_mapper.dart';

/// Orientation of the pen icon.
///
/// Controls the direction the pen tip points:
/// - [vertical]: Tip points UP (for popup/settings panels)
/// - [horizontal]: Tip points RIGHT (for PenBox, toward canvas)
enum PenOrientation {
  /// Tip points UP - used in popup/settings panels.
  vertical,

  /// Tip points RIGHT - used in PenBox (toward canvas).
  horizontal,
}

/// Widget that displays a pen icon using flutter_pen_toolbar.
///
/// Uses the toolbar package's PenPainter for consistent,
/// premium pen icon rendering.
///
/// The [orientation] parameter controls the pen direction:
/// - [PenOrientation.vertical]: Tip points UP (for popup/settings)
/// - [PenOrientation.horizontal]: Tip points RIGHT (for PenBox)
class PenIconWidget extends StatelessWidget {
  /// The pen type to display.
  final PenType penType;

  /// The color of the pen stripe/accent.
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
    final toolbarPenType = PenTypeMapper.toToolbarPenType(penType);

    // Calculate config based on size
    final config = toolbar.PenToolbarConfig(
      penWidth: size * 0.45,
      penHeight: size,
      stripeHeight: size * 0.06,
      stripeTopOffset: size * 0.15,
    );

    Widget penWidget = CustomPaint(
      size: Size(size * 0.5, size),
      painter: toolbar.PenPainter(
        penColor: color,
        penType: toolbarPenType,
        isSelected: isSelected,
        isEnabled: true,
        config: config,
      ),
    );

    // Apply rotation for horizontal orientation
    if (orientation == PenOrientation.horizontal) {
      penWidget = Transform.rotate(
        angle: 1.5708, // 90 degrees in radians (pi/2)
        child: penWidget,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: penWidget),
    );
  }
}

/// Convenience widget for ToolType-based icon display.
///
/// Automatically maps ToolType to PenType and displays
/// the appropriate pen icon using flutter_pen_toolbar.
class ToolPenIcon extends StatelessWidget {
  /// The tool type to display.
  final ToolType toolType;

  /// Optional color override for the pen stripe.
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

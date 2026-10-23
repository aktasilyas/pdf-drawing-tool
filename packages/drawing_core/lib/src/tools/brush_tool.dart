import 'package:drawing_core/src/internal.dart';

/// A brush drawing tool.
///
/// Creates strokes with an ellipse nib shape, suitable for
/// artistic and expressive drawing. Supports pressure sensitivity
/// through the [DrawingPoint.pressure] values.
class BrushTool extends DrawingTool {
  /// Creates a new [BrushTool].
  ///
  /// Input stabilization is on by default; pass `inputFilter: null` to disable.
  ///
  /// If no [style] is provided, uses [StrokeStyle.brush] as the default,
  /// which has:
  /// - Black color (0xFF000000)
  /// - 5.0 thickness
  /// - Ellipse nib shape
  BrushTool({
    StrokeStyle? style,
    StrokeInputFilterConfig? inputFilter = const StrokeInputFilterConfig(),
  }) : super(style ?? StrokeStyle.brush(), inputFilter: inputFilter);

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

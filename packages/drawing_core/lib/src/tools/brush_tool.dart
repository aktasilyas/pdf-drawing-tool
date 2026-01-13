import '../models/drawing_point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import 'drawing_tool.dart';

/// A brush drawing tool.
///
/// Creates strokes with an ellipse nib shape, suitable for
/// artistic and expressive drawing. Supports pressure sensitivity
/// through the [DrawingPoint.pressure] values.
class BrushTool extends DrawingTool {
  /// Creates a new [BrushTool].
  ///
  /// If no [style] is provided, uses [StrokeStyle.brush] as the default,
  /// which has:
  /// - Black color (0xFF000000)
  /// - 5.0 thickness
  /// - Ellipse nib shape
  BrushTool({StrokeStyle? style}) : super(style ?? StrokeStyle.brush());

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

import 'package:drawing_core/src/internal.dart';

/// A basic pen drawing tool.
///
/// Creates strokes with the pen style by default.
/// This is the most common drawing tool for general-purpose drawing.
class PenTool extends DrawingTool {
  /// Creates a new [PenTool].
  ///
  /// If no [style] is provided, uses [StrokeStyle.pen] as the default.
  PenTool({StrokeStyle? style}) : super(style ?? StrokeStyle.pen());

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

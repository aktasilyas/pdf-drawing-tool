import 'package:drawing_core/src/internal.dart';

/// A basic pen drawing tool.
///
/// Creates strokes with the pen style by default.
/// This is the most common drawing tool for general-purpose drawing.
class PenTool extends DrawingTool {
  /// Creates a new [PenTool].
  ///
  /// Input stabilization is on by default; pass `inputFilter: null` to disable.
  ///
  /// If no [style] is provided, uses [StrokeStyle.pen] as the default.
  PenTool({
    StrokeStyle? style,
    StrokeInputFilterConfig? inputFilter = const StrokeInputFilterConfig(),
  }) : super(style ?? StrokeStyle.pen(), inputFilter: inputFilter);

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

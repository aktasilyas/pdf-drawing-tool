import '../models/drawing_point.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import 'drawing_tool.dart';

/// A highlighter drawing tool.
///
/// Creates semi-transparent strokes with a rectangle nib shape,
/// ideal for highlighting text or areas.
class HighlighterTool extends DrawingTool {
  /// Creates a new [HighlighterTool].
  ///
  /// If no [style] is provided, uses [StrokeStyle.highlighter] as the default,
  /// which has:
  /// - Yellow color (0xFFFFEB3B)
  /// - 20.0 thickness
  /// - 0.5 opacity (semi-transparent)
  /// - Rectangle nib shape
  HighlighterTool({StrokeStyle? style})
      : super(style ?? StrokeStyle.highlighter());

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

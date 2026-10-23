import 'package:drawing_core/src/internal.dart';

/// A highlighter drawing tool.
///
/// Creates semi-transparent strokes with a rectangle nib shape,
/// ideal for highlighting text or areas.
class HighlighterTool extends DrawingTool {
  /// Creates a new [HighlighterTool].
  ///
  /// Input stabilization is on by default; pass `inputFilter: null` to disable.
  ///
  /// If no [style] is provided, uses [StrokeStyle.highlighter] as the default,
  /// which has:
  /// - Yellow color (0xFFFFEB3B)
  /// - 20.0 thickness
  /// - 0.5 opacity (semi-transparent)
  /// - Rectangle nib shape
  HighlighterTool({
    StrokeStyle? style,
    StrokeInputFilterConfig? inputFilter = const StrokeInputFilterConfig(),
  }) : super(style ?? StrokeStyle.highlighter(), inputFilter: inputFilter);

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    return Stroke.create(
      style: style,
      points: points,
    );
  }
}

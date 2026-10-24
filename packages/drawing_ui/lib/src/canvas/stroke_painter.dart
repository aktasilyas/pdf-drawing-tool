import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

export 'drawing_controller.dart';

// =============================================================================
// COMMITTED STROKES PAINTER
// =============================================================================

/// Renders committed (finished) strokes to the canvas.
///
/// This painter is optimized for performance:
/// - Only repaints when the stroke list actually changes
/// - Uses pre-computed stroke count and point count for fast comparison
/// - Shares a single [FlutterStrokeRenderer] instance
///
/// Use this for the "background" layer of completed strokes.
class CommittedStrokesPainter extends CustomPainter {
  /// The list of completed strokes to render.
  final List<Stroke> strokes;

  /// Segments to visually exclude during pixel eraser gesture.
  /// Maps stroke ID → list of segment indices to hide.
  final Map<String, List<int>> excludedSegments;

  /// Stroke IDs to completely skip rendering (used during live selection move/rotate).
  final Set<String> excludedStrokeIds;

  final FlutterStrokeRenderer _renderer;
  final int _strokeCount;
  final int _totalPointCount;

  /// Creates a painter for committed strokes.
  ///
  /// [strokes] - The list of completed strokes to render.
  /// [renderer] - Optional renderer instance for reuse.
  /// [excludedSegments] - Segments to visually skip (pixel eraser preview).
  /// [excludedStrokeIds] - Stroke IDs to skip entirely (selection live transform).
  CommittedStrokesPainter({
    required this.strokes,
    FlutterStrokeRenderer? renderer,
    this.excludedSegments = const {},
    this.excludedStrokeIds = const {},
  })  : _renderer = renderer ?? FlutterStrokeRenderer(),
        _strokeCount = strokes.length,
        _totalPointCount = strokes.fold(0, (sum, s) => sum + s.pointCount);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    if (excludedSegments.isEmpty && excludedStrokeIds.isEmpty) {
      _renderer.renderStrokes(canvas, strokes);
      return;
    }

    // Render strokes, skipping excluded IDs and segments
    for (final stroke in strokes) {
      if (excludedStrokeIds.contains(stroke.id)) continue;

      final excluded = excludedSegments[stroke.id];
      if (excluded != null && excluded.isNotEmpty) {
        _renderer.renderStrokeExcluding(canvas, stroke, excluded.toSet());
      } else {
        _renderer.renderStroke(canvas, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CommittedStrokesPainter oldDelegate) {
    // Excluded segments changed → repaint (pixel eraser live feedback)
    if (!identical(oldDelegate.excludedSegments, excludedSegments)) {
      return true;
    }

    // Excluded stroke IDs changed → repaint (selection live transform)
    if (!identical(oldDelegate.excludedStrokeIds, excludedStrokeIds)) {
      return true;
    }

    if (oldDelegate._strokeCount != _strokeCount) return true;
    if (oldDelegate._totalPointCount != _totalPointCount) return true;

    if (!identical(oldDelegate.strokes, strokes)) {
      for (int i = 0; i < strokes.length; i++) {
        if (oldDelegate.strokes[i] != strokes[i]) {
          return true;
        }
      }
    }

    return false;
  }
}

// =============================================================================
// ACTIVE STROKE PAINTER
// =============================================================================

/// Renders the currently active (being drawn) stroke.
///
/// This painter is called on every pointer move event, so it MUST be fast:
/// - No allocations in paint()
/// - Minimal shouldRepaint logic
/// - Uses cached point count for comparison
///
/// Use this for the "foreground" layer showing live drawing.
class ActiveStrokePainter extends CustomPainter {
  /// The points of the stroke being drawn.
  final List<DrawingPoint> points;

  /// The style to use for rendering.
  final StrokeStyle style;

  final FlutterStrokeRenderer _renderer;
  final int _pointCount;

  /// Creates a painter for the active stroke.
  ///
  /// [points] - Current points in the active stroke.
  /// [style] - The stroke style to render with.
  /// [renderer] - Optional renderer instance for reuse.
  ActiveStrokePainter({
    required this.points,
    required this.style,
    FlutterStrokeRenderer? renderer,
  })  : _renderer = renderer ?? FlutterStrokeRenderer(),
        _pointCount = points.length;

  @override
  void paint(Canvas canvas, Size size) {
    // Early exit - avoid any work for empty strokes
    if (points.isEmpty) return;

    _renderer.renderActiveStroke(canvas, points, style);
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) {
    // Repaint when:
    // 1. Point count changed (new point added)
    // 2. Style changed (user changed tool settings)
    // 3. Points content changed (for straight line mode where count stays 2 but positions change)
    if (oldDelegate._pointCount != _pointCount) return true;
    if (oldDelegate.style != style) return true;

    // Check if point positions changed (important for straight line preview)
    if (_pointCount > 0 && _pointCount == oldDelegate._pointCount) {
      // Compare last point position (most likely to change)
      final oldLast = oldDelegate.points.last;
      final newLast = points.last;
      if (oldLast.x != newLast.x || oldLast.y != newLast.y) return true;
    }

    return false;
  }
}

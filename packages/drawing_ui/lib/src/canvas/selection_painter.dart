import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Paints the selection preview path during selection creation.
///
/// Handle drawing (border, corners, rotation handle) has been moved to
/// `_SelectionHandlesPainter` inside `SelectionHandles` widget, which
/// also applies live move/rotation transforms.
///
/// This painter only draws the lasso/rectangle preview path while the
/// user is creating a selection.
class SelectionPainter extends CustomPainter {
  /// The current selection to display (bounds only, no handles).
  final Selection? selection;

  /// Preview path during selection creation.
  final List<DrawingPoint>? previewPath;

  /// Current zoom level (unused now, kept for API compat).
  final double zoom;

  /// Whether a live transform is active (move/rotate).
  /// When true, we skip drawing bounds — the SelectedElementsPainter
  /// + SelectionHandles custom painter handle the visuals.
  final bool hasLiveTransform;

  /// Dashed stroke paint for the selection border.
  static final Paint _dashPaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Semi-transparent fill paint for the selection area.
  static final Paint _fillPaint = Paint()
    ..color = const Color(0x152196F3)
    ..style = PaintingStyle.fill;

  SelectionPainter({
    required this.selection,
    this.previewPath,
    this.zoom = 1.0,
    this.hasLiveTransform = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw preview path (during selection creation)
    if (previewPath != null && previewPath!.isNotEmpty) {
      _drawPreviewPath(canvas);
    }

    // Draw bounds outline for empty selections so the user can see the area
    if (selection != null && selection!.isEmpty && !hasLiveTransform) {
      _drawEmptySelectionBounds(canvas);
    }
  }

  void _drawEmptySelectionBounds(Canvas canvas) {
    final sel = selection!;
    final lasso = sel.lassoPath;

    // Lasso selection: draw the original free-form path
    if (sel.type == SelectionType.lasso && lasso != null && lasso.length >= 3) {
      final path = Path();
      path.moveTo(lasso.first.x, lasso.first.y);
      for (int i = 1; i < lasso.length; i++) {
        path.lineTo(lasso[i].x, lasso[i].y);
      }
      path.close();
      canvas.drawPath(path, _fillPaint);
      canvas.drawPath(_createDashedPath(path), _dashPaint);
      return;
    }

    // Rectangle selection: draw bounds rectangle
    final b = sel.bounds;
    if (b.width <= 0 || b.height <= 0) return;

    final rect = Rect.fromLTRB(b.left, b.top, b.right, b.bottom);
    final path = Path()..addRect(rect);
    canvas.drawRect(rect, _fillPaint);
    canvas.drawPath(_createDashedPath(path), _dashPaint);
  }

  void _drawPreviewPath(Canvas canvas) {
    if (previewPath == null || previewPath!.length < 2) return;

    final path = Path();
    path.moveTo(previewPath!.first.x, previewPath!.first.y);

    for (int i = 1; i < previewPath!.length; i++) {
      path.lineTo(previewPath![i].x, previewPath![i].y);
    }

    // Draw semi-transparent fill
    canvas.drawPath(path, _fillPaint);

    // Draw dashed border
    canvas.drawPath(_createDashedPath(path), _dashPaint);
  }

  /// Creates a dashed version of the given path.
  static Path _createDashedPath(
    Path source, {
    double dashLength = 6.0,
    double gapLength = 4.0,
  }) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = (distance + dashLength).clamp(0.0, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, dashEnd),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.previewPath != previewPath ||
        oldDelegate.hasLiveTransform != hasLiveTransform;
  }
}

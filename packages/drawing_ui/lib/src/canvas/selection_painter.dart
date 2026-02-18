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

  /// Paint for preview path during selection.
  static final Paint _previewPaint = Paint()
    ..color = const Color(0x802196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

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
  }

  void _drawPreviewPath(Canvas canvas) {
    if (previewPath == null || previewPath!.length < 2) return;

    final path = Path();
    path.moveTo(previewPath!.first.x, previewPath!.first.y);

    for (int i = 1; i < previewPath!.length; i++) {
      path.lineTo(previewPath![i].x, previewPath![i].y);
    }

    canvas.drawPath(path, _previewPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.previewPath != previewPath ||
        oldDelegate.hasLiveTransform != hasLiveTransform;
  }
}

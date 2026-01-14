import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Paints selection overlays, handles, and preview paths.
///
/// This painter is responsible for:
/// - Drawing the selection bounds rectangle
/// - Drawing 8 resize handles
/// - Drawing lasso selection paths
/// - Drawing selection preview during creation
///
/// Uses cached Paint objects for performance.
class SelectionPainter extends CustomPainter {
  /// The current selection to display.
  final Selection? selection;

  /// Preview path during selection creation.
  final List<DrawingPoint>? previewPath;

  /// Current zoom level for handle size adjustment.
  final double zoom;

  // ─────────────────────────────────────────────────────────────────────────
  // CACHED PAINT OBJECTS (Performance)
  // ─────────────────────────────────────────────────────────────────────────

  /// Paint for selection bounds rectangle.
  static final Paint _boundsPaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  /// Paint for handle fill (white).
  static final Paint _handleFillPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.fill;

  /// Paint for handle stroke (blue).
  static final Paint _handleStrokePaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  /// Paint for preview path during selection.
  static final Paint _previewPaint = Paint()
    ..color = const Color(0x802196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Base handle size in logical pixels.
  static const double _handleSize = 10.0;

  /// Creates a selection painter.
  SelectionPainter({
    required this.selection,
    this.previewPath,
    this.zoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw preview path (during selection creation)
    if (previewPath != null && previewPath!.isNotEmpty) {
      _drawPreviewPath(canvas);
    }

    // Exit if no selection
    if (selection == null) return;

    final bounds = selection!.bounds;

    // NOTE: We intentionally do NOT draw the lasso path after selection is complete.
    // The lasso path was useful during selection creation to show the area being selected,
    // but once selection is finalized, showing both the lasso path AND the bounding box
    // is confusing (lasso path is at draw location, bounds are around selected strokes).
    // The bounding box with handles is sufficient to indicate the selection.

    // Draw selection bounds rectangle
    _drawSelectionBounds(canvas, bounds);

    // Draw resize handles
    _drawHandles(canvas, bounds);
  }

  /// Draws the preview path during selection creation.
  void _drawPreviewPath(Canvas canvas) {
    if (previewPath == null || previewPath!.length < 2) return;

    final path = Path();
    path.moveTo(previewPath!.first.x, previewPath!.first.y);

    for (int i = 1; i < previewPath!.length; i++) {
      path.lineTo(previewPath![i].x, previewPath![i].y);
    }

    canvas.drawPath(path, _previewPaint);
  }

  /// Draws the selection bounds rectangle.
  void _drawSelectionBounds(Canvas canvas, BoundingBox bounds) {
    final rect = Rect.fromLTRB(
      bounds.left,
      bounds.top,
      bounds.right,
      bounds.bottom,
    );

    canvas.drawRect(rect, _boundsPaint);
  }

  /// Draws all 8 resize handles.
  void _drawHandles(Canvas canvas, BoundingBox bounds) {
    const handles = [
      SelectionHandle.topLeft,
      SelectionHandle.topCenter,
      SelectionHandle.topRight,
      SelectionHandle.middleLeft,
      SelectionHandle.middleRight,
      SelectionHandle.bottomLeft,
      SelectionHandle.bottomCenter,
      SelectionHandle.bottomRight,
    ];

    // Adjust handle size based on zoom level
    final handleSize = _handleSize / zoom;

    for (final handle in handles) {
      final pos = handle.getPosition(bounds);
      _drawHandle(canvas, Offset(pos.x, pos.y), handleSize);
    }
  }

  /// Draws a single resize handle.
  void _drawHandle(Canvas canvas, Offset position, double size) {
    final rect = Rect.fromCenter(
      center: position,
      width: size,
      height: size,
    );

    // White fill
    canvas.drawRect(rect, _handleFillPaint);
    // Blue stroke
    canvas.drawRect(rect, _handleStrokePaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.previewPath != previewPath ||
        oldDelegate.zoom != zoom;
  }
}

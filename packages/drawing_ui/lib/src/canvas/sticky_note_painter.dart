import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/note_shape_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

/// CustomPainter for rendering [StickyNote]s on the drawing canvas.
///
/// Draws colored rounded rectangles with a subtle bottom shadow.
/// Also renders internal strokes and shapes (relative coords) clipped to
/// note bounds.
class StickyNotePainter extends CustomPainter {
  final List<StickyNote> stickyNotes;

  /// If set, this note's live position/size is used instead of the
  /// committed version in [stickyNotes]. Enables real-time drag feedback.
  final StickyNote? overrideNote;

  /// Stroke renderer for drawing internal note strokes.
  final FlutterStrokeRenderer renderer;

  // Cached paint objects for performance
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  StickyNotePainter({
    required this.stickyNotes,
    required this.renderer,
    this.overrideNote,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final note in stickyNotes) {
      final effective =
          (overrideNote != null && overrideNote!.id == note.id)
              ? overrideNote!
              : note;
      _drawStickyNote(canvas, effective);
    }
  }

  void _drawStickyNote(Canvas canvas, StickyNote note) {
    if (note.minimized) {
      _drawMinimizedIcon(canvas, note);
      return;
    }

    final rect = Rect.fromLTWH(note.x, note.y, note.width, note.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Shadow (offset down by 3px)
    final shadowRect = Rect.fromLTWH(
        note.x + 1, note.y + 3, note.width - 2, note.height);
    final shadowRRect =
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(8));
    _shadowPaint.color = Colors.black.withValues(alpha: 0.12);
    canvas.drawRRect(shadowRRect, _shadowPaint);

    // Fill
    _fillPaint.color = Color(note.color);
    canvas.drawRRect(rrect, _fillPaint);

    // Subtle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.black.withValues(alpha: 0.08);
    canvas.drawRRect(rrect, borderPaint);

    // Pushpin icon (top-left corner)
    _drawPushpin(canvas, note.x + 20, note.y + 20);

    // Internal strokes & shapes (relative coords, clipped to note bounds)
    if (note.strokes.isNotEmpty || note.shapes.isNotEmpty) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.translate(note.x, note.y);
      for (final stroke in note.strokes) {
        renderer.renderStroke(canvas, stroke);
      }
      for (final shape in note.shapes) {
        NoteShapeRenderer.drawShape(canvas, shape);
      }
      canvas.restore();
    }
  }

  /// Draws a minimized sticky note as a small 48x48 colored icon.
  void _drawMinimizedIcon(Canvas canvas, StickyNote note) {
    const s = StickyNote.minimizedSize;
    final rect = Rect.fromLTWH(note.x, note.y, s, s);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Shadow
    final shadowRect = Rect.fromLTWH(note.x + 1, note.y + 2, s - 2, s);
    final shadowRRect =
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(8));
    _shadowPaint.color = Colors.black.withValues(alpha: 0.15);
    canvas.drawRRect(shadowRRect, _shadowPaint);

    // Fill
    _fillPaint.color = Color(note.color);
    canvas.drawRRect(rrect, _fillPaint);

    // Fold triangle (top-right corner)
    const foldSize = 10.0;
    final foldPath = Path()
      ..moveTo(note.x + s - foldSize, note.y)
      ..lineTo(note.x + s, note.y + foldSize)
      ..lineTo(note.x + s, note.y)
      ..close();
    final foldPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(foldPath, foldPaint);

    // Subtle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawRRect(rrect, borderPaint);

    // Small pushpin (scaled down, centered)
    _drawMiniPushpin(canvas, note.x + s / 2, note.y + s / 2 + 2);
  }

  /// Draws a smaller pushpin for the minimized icon.
  void _drawMiniPushpin(Canvas canvas, double cx, double cy) {
    final pinColor = Colors.black.withValues(alpha: 0.3);

    final headPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 3), 4.5, headPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 1, cy - 4), 1.5, highlightPaint);

    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy - 3), 4.5, ringPaint);

    final needlePaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + 1.5),
      Offset(cx + 1, cy + 8),
      needlePaint,
    );
  }

  /// Draws a pushpin icon at the given center position.
  void _drawPushpin(Canvas canvas, double cx, double cy) {
    final pinColor = Colors.black.withValues(alpha: 0.35);

    final headPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 4), 7, headPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 1.5, cy - 5.5), 2.5, highlightPaint);

    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy - 4), 7, ringPaint);

    final needlePaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + 3),
      Offset(cx + 2, cy + 13),
      needlePaint,
    );

    final tipPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + 2, cy + 13),
      Offset(cx + 2.5, cy + 16),
      tipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StickyNotePainter oldDelegate) {
    return oldDelegate.stickyNotes != stickyNotes ||
        oldDelegate.overrideNote != overrideNote ||
        (overrideNote != null &&
            oldDelegate.overrideNote != null &&
            (overrideNote!.x != oldDelegate.overrideNote!.x ||
                overrideNote!.y != oldDelegate.overrideNote!.y ||
                overrideNote!.width != oldDelegate.overrideNote!.width ||
                overrideNote!.height != oldDelegate.overrideNote!.height ||
                overrideNote!.color != oldDelegate.overrideNote!.color ||
                overrideNote!.minimized != oldDelegate.overrideNote!.minimized));
  }
}

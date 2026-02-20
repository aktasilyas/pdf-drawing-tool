import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Icon button size for top-right action buttons (canvas coordinates).
const double stickyNoteIconBtnSize = 28.0;

/// Gap between icon buttons.
const double stickyNoteIconGap = 4.0;

/// Paints selection border, bottom-right resize handle,
/// and top-right shrink + three-dot icon buttons.
class StickyNoteHandlesPainter extends CustomPainter {
  final StickyNote note;
  static const double _r = 8.0;

  StickyNoteHandlesPainter({required this.note});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(note.x, note.y, note.width, note.height);

    // Selection border
    final border = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), border);

    // Bottom-right resize handle
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final br = Offset(note.x + note.width, note.y + note.height);
    canvas.drawCircle(br, _r, fill);
    canvas.drawCircle(br, _r, stroke);
    _drawResizeArrow(canvas, br);

    // Top-right icon buttons
    final right = note.x + note.width;
    final shrinkCenter = Offset(
      right - stickyNoteIconBtnSize * 2 - stickyNoteIconGap - 6 +
          stickyNoteIconBtnSize / 2,
      note.y + 6 + stickyNoteIconBtnSize / 2,
    );
    final menuCenter = Offset(
      right - stickyNoteIconBtnSize - 6 + stickyNoteIconBtnSize / 2,
      note.y + 6 + stickyNoteIconBtnSize / 2,
    );

    _drawIconButton(canvas, shrinkCenter);
    _drawMinimizeIcon(canvas, shrinkCenter);

    _drawIconButton(canvas, menuCenter);
    _drawDotsIcon(canvas, menuCenter);
  }

  void _drawIconButton(Canvas canvas, Offset center) {
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center,
            width: stickyNoteIconBtnSize,
            height: stickyNoteIconBtnSize),
        const Radius.circular(6),
      ),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center,
            width: stickyNoteIconBtnSize,
            height: stickyNoteIconBtnSize),
        const Radius.circular(6),
      ),
      borderPaint,
    );
  }

  /// Minimize icon: horizontal line (like a window minimize button)
  void _drawMinimizeIcon(Canvas canvas, Offset c) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Single horizontal line at center
    canvas.drawLine(
        Offset(c.dx - 5, c.dy + 2), Offset(c.dx + 5, c.dy + 2), p);
  }

  /// Three vertical dots icon
  void _drawDotsIcon(Canvas canvas, Offset c) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    const r = 2.0;
    const gap = 5.0;
    canvas.drawCircle(Offset(c.dx, c.dy - gap), r, p);
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(Offset(c.dx, c.dy + gap), r, p);
  }

  void _drawResizeArrow(Canvas canvas, Offset center) {
    final p = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const d = 3.5;
    canvas.drawLine(Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy + d), p);
    canvas.drawLine(Offset(center.dx + d, center.dy + d),
        Offset(center.dx + d - 2.5, center.dy + d), p);
    canvas.drawLine(Offset(center.dx + d, center.dy + d),
        Offset(center.dx + d, center.dy + d - 2.5), p);
    canvas.drawLine(Offset(center.dx - d, center.dy - d),
        Offset(center.dx - d + 2.5, center.dy - d), p);
    canvas.drawLine(Offset(center.dx - d, center.dy - d),
        Offset(center.dx - d, center.dy - d + 2.5), p);
  }

  @override
  bool shouldRepaint(StickyNoteHandlesPainter old) {
    return old.note.x != note.x ||
        old.note.y != note.y ||
        old.note.width != note.width ||
        old.note.height != note.height;
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Text rendering painter
class TextElementPainter extends CustomPainter {
  final List<TextElement> texts;
  final TextElement? activeText; // Editing preview
  final bool showCursor;
  final Set<String> excludedTextIds;

  TextElementPainter({
    required this.texts,
    this.activeText,
    this.showCursor = false,
    this.excludedTextIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Committed texts
    for (final text in texts) {
      if (excludedTextIds.contains(text.id)) continue;
      _drawText(canvas, text);
    }

    // Active text (being edited)
    if (activeText != null) {
      _drawText(canvas, activeText!, isActive: true);
    }
  }

  void _drawText(Canvas canvas, TextElement text, {bool isActive = false}) {
    if (text.text.isEmpty && !isActive) return;

    final textStyle = ui.TextStyle(
      color: Color(text.color),
      fontSize: text.fontSize,
      fontFamily: text.fontFamily,
      fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration:
          text.isUnderline ? TextDecoration.underline : TextDecoration.none,
    );

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: _convertAlignment(text.alignment),
      maxLines: null,
    );

    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text.text.isEmpty ? ' ' : text.text);

    final paragraph = paragraphBuilder.build();

    // Layout width
    final layoutWidth = text.width ?? 1000.0;
    paragraph.layout(ui.ParagraphConstraints(width: layoutWidth));

    // Draw text
    canvas.drawParagraph(paragraph, Offset(text.x, text.y));

    // Draw selection/editing indicator
    if (isActive) {
      _drawEditingIndicator(canvas, text, paragraph);
    }
  }

  void _drawEditingIndicator(
      Canvas canvas, TextElement text, ui.Paragraph paragraph) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromLTWH(
      text.x - 2,
      text.y - 2,
      paragraph.maxIntrinsicWidth + 4,
      paragraph.height + 4,
    );

    canvas.drawRect(rect, paint);

    // Cursor
    if (showCursor) {
      final cursorPaint = Paint()
        ..color = const Color(0xFF000000)
        ..strokeWidth = 2.0;

      final cursorX = text.x + paragraph.maxIntrinsicWidth;
      canvas.drawLine(
        Offset(cursorX, text.y),
        Offset(cursorX, text.y + paragraph.height),
        cursorPaint,
      );
    }
  }

  TextAlign _convertAlignment(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }

  @override
  bool shouldRepaint(covariant TextElementPainter oldDelegate) {
    return oldDelegate.texts != texts ||
        oldDelegate.activeText != activeText ||
        oldDelegate.showCursor != showCursor ||
        oldDelegate.excludedTextIds != excludedTextIds;
  }
}

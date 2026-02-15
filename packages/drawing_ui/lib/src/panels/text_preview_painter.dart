import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Text Preview
// ---------------------------------------------------------------------------

/// Visual preview of current text style settings.
///
/// Shows sample text rendered with the selected font size, color,
/// bold, italic, and underline settings inside a lined "notebook" area.
class TextPreview extends StatelessWidget {
  const TextPreview({
    super.key,
    required this.fontSize,
    required this.color,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  final double fontSize;
  final Color color;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clamp preview font size so it fits the 100px box
    final previewSize = fontSize.clamp(10.0, 42.0);

    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        painter: _NotebookLinesPainter(
          lineColor: cs.outlineVariant.withValues(alpha: 0.3),
          isDark: isDark,
        ),
        child: Center(
          child: Text(
            'Merhaba',
            style: TextStyle(
              fontSize: previewSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration:
                  isUnderline ? TextDecoration.underline : TextDecoration.none,
              decorationColor: color,
              color: color,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws faint horizontal notebook lines in the preview background.
class _NotebookLinesPainter extends CustomPainter {
  _NotebookLinesPainter({
    required this.lineColor,
    required this.isDark,
  });

  final Color lineColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const spacing = 24.0;
    var y = spacing;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      y += spacing;
    }

    // Faint text cursor line at left
    final cursorPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.15, 12),
      Offset(size.width * 0.15, size.height - 12),
      cursorPaint,
    );
  }

  @override
  bool shouldRepaint(_NotebookLinesPainter o) =>
      lineColor != o.lineColor || isDark != o.isDark;
}

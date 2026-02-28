import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog that shows a screenshot preview before saving.
///
/// Returns `true` if the user taps "Kaydet", `false`/`null` otherwise.
class ScreenshotPreviewDialog extends StatelessWidget {
  const ScreenshotPreviewDialog({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ekran Resmi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _CheckerboardPainter(color: cs.outlineVariant),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'İptal',
                    style: GoogleFonts.sourceSerif4(color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a checkerboard pattern to indicate transparency.
class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({required this.color});

  final Color color;
  static const double _cellSize = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.3);
    for (double y = 0; y < size.height; y += _cellSize) {
      for (double x = 0; x < size.width; x += _cellSize) {
        final col = (x / _cellSize).floor();
        final row = (y / _cellSize).floor();
        if ((col + row) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, _cellSize, _cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) =>
      color != oldDelegate.color;
}

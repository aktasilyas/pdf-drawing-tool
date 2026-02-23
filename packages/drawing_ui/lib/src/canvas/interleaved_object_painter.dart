import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'image_painter.dart';

/// Renders [ImageElement]s and [TextElement]s interleaved by creation order.
///
/// Element IDs are microsecond timestamps, so sorting by ID gives
/// chronological (z-order) rendering: earliest-created at the bottom,
/// most-recently-created on top.
///
/// This replaces the separate [ImageElementPainter] + [TextElementPainter]
/// approach which always painted all images below all texts regardless
/// of creation order.
class InterleavedObjectPainter extends CustomPainter {
  final List<ImageElement> images;
  final List<TextElement> texts;
  final ImageCacheManager cacheManager;
  final TextElement? activeText;
  final Set<String> excludedImageIds;
  final Set<String> excludedTextIds;
  final List<String> elementOrder;

  InterleavedObjectPainter({
    required this.images,
    required this.texts,
    required this.cacheManager,
    this.activeText,
    this.excludedImageIds = const {},
    this.excludedTextIds = const {},
    this.elementOrder = const [],
  }) : super(repaint: cacheManager);

  @override
  void paint(Canvas canvas, Size size) {
    // Build id→element maps for order-based lookup.
    final imageMap = <String, ImageElement>{};
    for (final img in images) {
      if (!excludedImageIds.contains(img.id)) imageMap[img.id] = img;
    }
    final textMap = <String, TextElement>{};
    for (final txt in texts) {
      if (!excludedTextIds.contains(txt.id)) textMap[txt.id] = txt;
    }

    if (elementOrder.isNotEmpty) {
      // Paint in explicit order, then append any remaining (backward compat).
      final painted = <String>{};
      for (final id in elementOrder) {
        painted.add(id);
        final img = imageMap[id];
        if (img != null) { _drawImage(canvas, img); continue; }
        final txt = textMap[id];
        if (txt != null) { _drawText(canvas, txt); }
      }
      // Remaining elements not in elementOrder: sorted by ID.
      final remaining = <_PaintEntry>[];
      for (final e in imageMap.entries) {
        if (!painted.contains(e.key)) {
          remaining.add(_PaintEntry(id: e.key, image: e.value));
        }
      }
      for (final e in textMap.entries) {
        if (!painted.contains(e.key)) {
          remaining.add(_PaintEntry(id: e.key, text: e.value));
        }
      }
      remaining.sort((a, b) => a.id.compareTo(b.id));
      for (final e in remaining) {
        if (e.image != null) { _drawImage(canvas, e.image!); }
        else { _drawText(canvas, e.text!); }
      }
    } else {
      // Fallback: sort by ID (microsecond timestamp) — oldest first.
      final entries = <_PaintEntry>[];
      for (final e in imageMap.entries) {
        entries.add(_PaintEntry(id: e.key, image: e.value));
      }
      for (final e in textMap.entries) {
        entries.add(_PaintEntry(id: e.key, text: e.value));
      }
      entries.sort((a, b) => a.id.compareTo(b.id));
      for (final e in entries) {
        if (e.image != null) { _drawImage(canvas, e.image!); }
        else { _drawText(canvas, e.text!); }
      }
    }

    // Active text always on top (editing preview).
    if (activeText != null) {
      _drawText(canvas, activeText!, isActive: true);
    }
  }

  // ── Image rendering (from ImageElementPainter) ──

  void _drawImage(Canvas canvas, ImageElement element) {
    final cachedImage = cacheManager.get(element.filePath);
    if (cachedImage == null) {
      _drawPlaceholder(canvas, element);
      cacheManager.loadImage(element.filePath);
      return;
    }

    canvas.save();
    if (element.rotation != 0.0) {
      final cx = element.x + element.width / 2;
      final cy = element.y + element.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(element.rotation);
      canvas.translate(-cx, -cy);
    }

    final src = Rect.fromLTWH(
        0, 0, cachedImage.width.toDouble(), cachedImage.height.toDouble());
    final dst =
        Rect.fromLTWH(element.x, element.y, element.width, element.height);
    canvas.drawImageRect(cachedImage, src, dst, Paint());
    canvas.restore();
  }

  void _drawPlaceholder(Canvas canvas, ImageElement element) {
    final rect =
        Rect.fromLTWH(element.x, element.y, element.width, element.height);
    canvas.drawRect(
        rect, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    final iconSize =
        (element.width < element.height ? element.width : element.height) * 0.3;
    canvas.drawRect(
        Rect.fromCenter(center: rect.center, width: iconSize, height: iconSize),
        Paint()
          ..color = const Color(0xFF9E9E9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
  }

  // ── Text rendering (from TextElementPainter) ──

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

    final paragraph = (ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: _convertAlignment(text.alignment),
        maxLines: null,
      ),
    )
          ..pushStyle(textStyle)
          ..addText(text.text.isEmpty ? ' ' : text.text))
        .build();

    paragraph.layout(ui.ParagraphConstraints(width: text.width ?? 1000.0));
    canvas.drawParagraph(paragraph, Offset(text.x, text.y));

    if (isActive) {
      final paint = Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromLTWH(text.x - 2, text.y - 2,
            paragraph.maxIntrinsicWidth + 4, paragraph.height + 4),
        paint,
      );
    }
  }

  static TextAlign _convertAlignment(TextAlignment alignment) {
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
  bool shouldRepaint(covariant InterleavedObjectPainter oldDelegate) {
    return oldDelegate.images != images ||
        oldDelegate.texts != texts ||
        oldDelegate.activeText != activeText ||
        oldDelegate.excludedImageIds != excludedImageIds ||
        oldDelegate.excludedTextIds != excludedTextIds ||
        oldDelegate.elementOrder != elementOrder;
  }
}

/// Lightweight wrapper to tag an element for sorting.
class _PaintEntry {
  final String id;
  final ImageElement? image;
  final TextElement? text;

  const _PaintEntry({required this.id, this.image, this.text});
}

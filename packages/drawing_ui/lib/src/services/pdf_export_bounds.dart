import 'dart:math';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;

Rect? _contentBounds(Page page) {
  double? minX, minY, maxX, maxY;
  void expand(BoundingBox b) {
    minX = minX == null ? b.left : min(minX!, b.left);
    minY = minY == null ? b.top : min(minY!, b.top);
    maxX = maxX == null ? b.right : max(maxX!, b.right);
    maxY = maxY == null ? b.bottom : max(maxY!, b.bottom);
  }

  for (final layer in page.layers) {
    if (!layer.isVisible) continue;
    for (final stroke in layer.strokes) {
      final b = stroke.bounds;
      if (b != null) expand(b);
    }
    for (final shape in layer.shapes) {
      expand(shape.bounds);
    }
    for (final img in layer.images) {
      expand(img.bounds);
    }
    for (final text in layer.texts) {
      expand(text.bounds);
    }
    for (final note in layer.stickyNotes) {
      expand(note.bounds);
    }
  }
  if (minX == null) return null;
  return Rect.fromLTRB(minX!, minY!, maxX!, maxY!);
}

/// PDF page bounds of an infinite-canvas page: the page rect grown to hold
/// all visible content plus padding.
({double width, double height, double offsetX, double offsetY})
    infiniteCanvasExportBounds(Page page) {
  final pageW = page.size.width;
  final pageH = page.size.height;
  final contentRect = _contentBounds(page);
  const padding = 24.0;
  final double left, top, right, bottom;
  if (contentRect != null) {
    left = min(0.0, contentRect.left - padding);
    top = min(0.0, contentRect.top - padding);
    right = max(pageW, contentRect.right + padding);
    bottom = max(pageH, contentRect.bottom + padding);
  } else {
    left = 0;
    top = 0;
    right = pageW;
    bottom = pageH;
  }
  return (
    width: right - left,
    height: bottom - top,
    offsetX: -left,
    offsetY: -top,
  );
}

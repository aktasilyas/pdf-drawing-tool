import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/rendering/element_text_layout.dart';

/// Anti-aliasing margin added around every element, in page units.
const double _aaMargin = 2.0;

/// Inflated page-space bounds for [stroke]: point bbox + half thickness
/// (scaled for non-round nibs) + AA margin + glow blur extent.
///
/// Returns [Rect.zero] for an empty stroke.
Rect strokeBounds(Stroke stroke) {
  final b = stroke.bounds;
  if (b == null) return Rect.zero;
  final style = stroke.style;
  // Square/ellipse nibs reach up to sqrt(2) * half thickness at corners.
  final nibFactor = style.nibShape == NibShape.circle ? 1.0 : math.sqrt2;
  var margin = style.thickness / 2 * nibFactor + _aaMargin;
  if (style.glowRadius > 0 && style.glowIntensity > 0) {
    // Gaussian blur sigma = radius * intensity; ~3 sigma covers the tail.
    margin += 3 * style.glowRadius * style.glowIntensity;
  }
  return Rect.fromLTRB(b.left, b.top, b.right, b.bottom).inflate(margin);
}

/// Inflated page-space bounds for [shape] (stroke width, AA, arrow head).
Rect shapeBounds(Shape shape) {
  final b = shape.bounds; // already includes half thickness
  var margin = _aaMargin;
  if (shape.type == ShapeType.arrow) {
    margin += shape.style.thickness * 4;
  }
  final style = shape.style;
  if (style.glowRadius > 0 && style.glowIntensity > 0) {
    margin += 3 * style.glowRadius * style.glowIntensity;
  }
  return Rect.fromLTRB(b.left, b.top, b.right, b.bottom).inflate(margin);
}

/// Page-space bounds for [image], including rotation and placeholder border.
Rect imageBounds(ImageElement image) {
  final rect = Rect.fromLTWH(image.x, image.y, image.width, image.height);
  return _rotatedBounds(rect, rect.center, image.rotation).inflate(_aaMargin);
}

final Expando<Rect> _textBoundsCache = Expando<Rect>('textBounds');

/// Page-space bounds for [text]. The paragraph is laid out once per instance
/// and the result cached in an [Expando].
Rect textBounds(TextElement text) {
  final cached = _textBoundsCache[text];
  if (cached != null) return cached;

  final paragraph = layoutTextParagraph(text);
  final w = paragraph.maxIntrinsicWidth;
  final h = paragraph.height;
  paragraph.dispose();

  // Include the 2px active-selection outline drawn around the text.
  final rect = Rect.fromLTWH(text.x, text.y, w, h);
  final center = Offset(text.x + w / 2, text.y + h / 2);
  final result =
      _rotatedBounds(rect, center, text.rotation).inflate(_aaMargin + 2);
  _textBoundsCache[text] = result;
  return result;
}

Rect _rotatedBounds(Rect rect, Offset center, double rotation) {
  if (rotation == 0.0) return rect;
  final cosA = math.cos(rotation);
  final sinA = math.sin(rotation);
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final c in [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ]) {
    final dx = c.dx - center.dx;
    final dy = c.dy - center.dy;
    final x = center.dx + dx * cosA - dy * sinA;
    final y = center.dy + dx * sinA + dy * cosA;
    minX = math.min(minX, x);
    maxX = math.max(maxX, x);
    minY = math.min(minY, y);
    maxY = math.max(maxY, y);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

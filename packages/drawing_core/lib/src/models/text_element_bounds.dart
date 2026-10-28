part of 'text_element.dart';

// Estimated bounds for [TextElement]. The real size is measured at render
// time; this estimate drives hit testing and selection.

BoundingBox _estimateTextBounds(TextElement element) {
  final fontSize = element.fontSize;
  final lineHeight = fontSize * 1.2;
  final lines = element.text.split('\n');

  double maxLineWidth = 0;
  for (final line in lines) {
    final runes = line.runes.toList();
    final hasEmoji = runes.any((r) => r > 0xFF);
    if (hasEmoji) {
      maxLineWidth =
          math.max(maxLineWidth, _countVisibleGlyphs(runes) * fontSize);
    } else {
      maxLineWidth = math.max(maxLineWidth, runes.length * fontSize * 0.6);
    }
  }

  final x = element.x;
  final y = element.y;
  final w = element.width ?? maxLineWidth;
  final h = element.height ?? (lines.length * lineHeight);

  if (element.rotation == 0.0) {
    return BoundingBox(left: x, top: y, right: x + w, bottom: y + h);
  }
  // Rotated bounding box
  final cx = x + w / 2;
  final cy = y + h / 2;
  final cosR = math.cos(element.rotation);
  final sinR = math.sin(element.rotation);
  // Rotate four corners and find axis-aligned envelope
  double minX = double.infinity, maxX = double.negativeInfinity;
  double minY = double.infinity, maxY = double.negativeInfinity;
  for (final corner in [
    (x, y),
    (x + w, y),
    (x + w, y + h),
    (x, y + h),
  ]) {
    final dx = corner.$1 - cx;
    final dy = corner.$2 - cy;
    final rx = cx + dx * cosR - dy * sinR;
    final ry = cy + dx * sinR + dy * cosR;
    if (rx < minX) minX = rx;
    if (rx > maxX) maxX = rx;
    if (ry < minY) minY = ry;
    if (ry > maxY) maxY = ry;
  }
  return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
}

/// Counts visible glyphs by collapsing ZWJ sequences and skipping
/// invisible modifiers (variation selectors, skin tones, etc.).
int _countVisibleGlyphs(List<int> runes) {
  int count = 0;
  bool joinedToPrev = false;
  for (final rune in runes) {
    if (rune == 0x200D) {
      joinedToPrev = true;
      continue;
    } // ZWJ
    if (_isInvisibleModifier(rune)) continue;
    if (!joinedToPrev) count++;
    joinedToPrev = false;
  }
  return math.max(count, 1);
}

bool _isInvisibleModifier(int rune) =>
    (rune >= 0xFE00 && rune <= 0xFE0F) || // Variation selectors
    (rune >= 0x1F3FB && rune <= 0x1F3FF) || // Skin tone modifiers
    rune == 0x20E3; // Combining enclosing keycap

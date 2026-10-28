import 'dart:ui';

import 'template_accent_paints.dart';

/// Shared inputs and helpers of the structural (planner, list, creative)
/// template painters. Proportional measurements only; every paint comes from
/// [accent] so nothing is allocated while painting.
mixin TemplateStructuralHelpers {
  Color get lineColor;
  double get lineWidth;
  Map<String, dynamic>? get extraData;
  double get spacingPx;
  TemplateAccentPaints get accent;

  /// Thick horizontal separator.
  void drawDividerLine(Canvas canvas, double y, double startX, double endX) {
    canvas.drawLine(Offset(startX, y), Offset(endX, y), accent.divider);
  }

  /// Empty rounded checkbox.
  void drawCheckboxRect(Canvas canvas, Offset topLeft, double size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size),
        Radius.circular(size * 0.15),
      ),
      accent.ink,
    );
  }
}

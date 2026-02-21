import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/ruler_provider.dart';

/// Ruler strip height (the narrow dimension) in screen pixels.
const double rulerStripHeight = 160;

/// Angle snap threshold in radians (~3°).
/// When within this range of 0°/90°/180°/270° the ruler locks to that angle.
const double _angleSnapThreshold = 3.0 * math.pi / 180;

/// Ruler strip length in screen pixels.
/// Much larger than any device width so the ends are never visible.
const double rulerStripLength = 4000;

/// GoodNotes-style physical ruler overlay.
///
/// - Transparent body with cm tick marks and numbers
/// - Single finger drag to reposition
/// - Two finger gesture to rotate
/// - Extends far beyond the screen edges (ends never visible)
/// - [rulerPositionProvider] stores the centre of the ruler
class RulerOverlay extends ConsumerStatefulWidget {
  const RulerOverlay({super.key});

  @override
  ConsumerState<RulerOverlay> createState() => _RulerOverlayState();
}

class _RulerOverlayState extends ConsumerState<RulerOverlay> {
  double _gestureStartAngle = 0;
  bool _needsCenter = true;

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(rulerVisibleProvider);
    if (!visible) {
      _needsCenter = true;
      return const SizedBox.shrink();
    }

    // Centre the ruler on first show.
    if (_needsCenter) {
      _needsCenter = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.sizeOf(context);
        ref.read(rulerPositionProvider.notifier).state =
            Offset(size.width / 2, size.height * 0.45);
      });
    }

    final center = ref.watch(rulerPositionProvider);
    final angle = ref.watch(rulerAngleProvider);
    final isRotating = ref.watch(rulerRotatingProvider);
    final cs = Theme.of(context).colorScheme;

    // Convert radians to degrees for display (normalise to -180..180).
    final degrees = (angle * 180 / math.pi) % 360;
    final displayDeg =
        degrees > 180 ? degrees - 360 : (degrees < -180 ? degrees + 360 : degrees);

    return Positioned(
      left: center.dx - rulerStripLength / 2,
      top: center.dy - rulerStripHeight / 2,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Container(
            width: rulerStripLength,
            height: rulerStripHeight,
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.78),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  width: 2.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RulerMarkingsPainter(
                      tickColor: cs.onSurface.withValues(alpha: 0.85),
                      numberColor: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                if (isRotating)
                  Center(
                    child: _AngleBadge(
                      degrees: displayDeg,
                      backgroundColor: cs.inverseSurface,
                      textColor: cs.onInverseSurface,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartAngle = ref.read(rulerAngleProvider);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final angle = ref.read(rulerAngleProvider);

    // Un-rotate the focal point delta from the rotated frame back to
    // screen-space (GestureDetector sits inside Transform.rotate).
    final d = details.focalPointDelta;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final screenDelta = Offset(
      d.dx * cosA - d.dy * sinA,
      d.dx * sinA + d.dy * cosA,
    );

    // Apply full delta, then clamp so both ruler ends stay off-screen.
    final current = ref.read(rulerPositionProvider);
    final candidate = current + screenDelta;
    final screenSize = MediaQuery.sizeOf(context);
    ref.read(rulerPositionProvider.notifier).state =
        _clampRulerPosition(candidate, angle, screenSize);

    // Rotate: two fingers.
    if (details.pointerCount >= 2) {
      ref.read(rulerRotatingProvider.notifier).state = true;
      final raw = _gestureStartAngle + details.rotation;
      ref.read(rulerAngleProvider.notifier).state = _snapAngle(raw);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    ref.read(rulerRotatingProvider.notifier).state = false;
  }

  /// Snaps [angle] to 0°/90°/180°/270° if within [_angleSnapThreshold].
  double _snapAngle(double angle) {
    const cardinals = [0.0, math.pi / 2, math.pi, -math.pi / 2, -math.pi];
    var a = angle % (2 * math.pi);
    if (a > math.pi) a -= 2 * math.pi;
    if (a < -math.pi) a += 2 * math.pi;
    for (final c in cardinals) {
      if ((a - c).abs() < _angleSnapThreshold) return c;
    }
    return a;
  }

  /// Clamps [center] along the ruler axis so both ends stay off-screen.
  Offset _clampRulerPosition(Offset center, double angle, Size screen) {
    final halfLen = rulerStripLength / 2;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final corners = [
      Offset.zero, Offset(screen.width, 0),
      Offset(0, screen.height), Offset(screen.width, screen.height),
    ];
    var minProj = double.infinity;
    var maxProj = double.negativeInfinity;
    for (final c in corners) {
      final p = c.dx * dir.dx + c.dy * dir.dy;
      if (p < minProj) minProj = p;
      if (p > maxProj) maxProj = p;
    }
    final centerProj = center.dx * dir.dx + center.dy * dir.dy;
    final clamped = centerProj.clamp(maxProj - halfLen, minProj + halfLen);
    final shift = clamped - centerProj;
    return center + dir * shift;
  }
}

/// Paints cm/mm tick marks and cm numbers on both edges of the ruler.
class _RulerMarkingsPainter extends CustomPainter {
  _RulerMarkingsPainter({
    required this.tickColor,
    required this.numberColor,
  });

  final Color tickColor;
  final Color numberColor;

  /// Approximate pixels per centimetre (96 DPI logical).
  static const double _cmPx = 37.8;
  static const double _mmPx = _cmPx / 10;

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final cmCount = (size.width / 2 / _cmPx).ceil();

    for (int cm = -cmCount; cm <= cmCount; cm++) {
      final cmX = centerX + cm * _cmPx;

      // Draw sub-mm ticks for this cm segment.
      for (int mm = 0; mm < 10; mm++) {
        final x = cmX + mm * _mmPx;
        if (x < 0 || x > size.width) continue;

        final bool isCm = mm == 0;
        final bool isHalf = mm == 5;
        final double h = isCm ? 28.0 : isHalf ? 18.0 : 8.0;

        // Top edge
        canvas.drawLine(Offset(x, 0), Offset(x, h), tickPaint);
        // Bottom edge
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x, size.height - h),
          tickPaint,
        );
      }

      // Cm number in the centre.
      if (cm == 0 || cmX < 0 || cmX > size.width) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: '${cm.abs()}',
          style: TextStyle(
            color: numberColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cmX - tp.width / 2, (size.height - tp.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RulerMarkingsPainter old) =>
      tickColor != old.tickColor || numberColor != old.numberColor;
}

/// Small pill badge showing the current rotation angle in degrees.
class _AngleBadge extends StatelessWidget {
  const _AngleBadge({
    required this.degrees,
    required this.backgroundColor,
    required this.textColor,
  });

  final double degrees;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${degrees.toStringAsFixed(1)}°',
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

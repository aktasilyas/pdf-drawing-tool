part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Ruler hit-testing and snapping for pen and straight-line input.
mixin _RulerSnapping<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  /// Snap threshold in screen pixels.
  static const double _rulerSnapThreshold = 30.0;

  /// Returns true if [screenPoint] falls inside the rotated ruler strip.
  ///
  /// [rulerPositionProvider] stores the centre of the ruler.
  /// Un-rotates the point around that centre and checks against the
  /// axis-aligned bounds [-length/2, length/2] x [-height/2, height/2].
  bool _isPointOnRuler(Offset screenPoint) {
    if (!ref.read(rulerVisibleProvider)) return false;

    final center = ref.read(rulerPositionProvider);
    final angle = ref.read(rulerAngleProvider);

    final cosA = math.cos(-angle);
    final sinA = math.sin(-angle);
    final d = screenPoint - center;
    final localX = d.dx * cosA - d.dy * sinA;
    final localY = d.dx * sinA + d.dy * cosA;

    return localX.abs() <= rulerStripLength / 2 &&
        localY.abs() <= rulerStripHeight / 2;
  }

  /// Snaps [point] to the nearest ruler edge (top or bottom).
  ///
  /// If the point is ON the ruler body it is always projected to the nearest
  /// edge so the pen draws parallel to the ruler (physical ruler behaviour).
  /// If the point is outside but within [_rulerSnapThreshold] it is snapped.
  core.DrawingPoint _snapToRuler(core.DrawingPoint point) {
    if (!ref.read(rulerVisibleProvider)) return point;

    final transform = ref.read(canvasTransformProvider);
    final center = ref.read(rulerPositionProvider);
    final angle = ref.read(rulerAngleProvider);

    // Perpendicular direction (un-rotated +Y → points "down" from ruler).
    final perpX = -math.sin(angle);
    final perpY = math.cos(angle);
    final halfH = rulerStripHeight / 2;

    // Bottom edge origin in screen space.
    final bottomScreen = center + Offset(perpX * halfH, perpY * halfH);
    // Top edge origin in screen space.
    final topScreen = center + Offset(-perpX * halfH, -perpY * halfH);

    final pointScreen = transform.canvasToScreen(Offset(point.x, point.y));
    final dirX = math.cos(angle);
    final dirY = math.sin(angle);

    // Project onto bottom edge.
    final vB = pointScreen - bottomScreen;
    final tB = vB.dx * dirX + vB.dy * dirY;
    final projB = bottomScreen + Offset(dirX * tB, dirY * tB);
    final distB = (pointScreen - projB).distance;

    // Project onto top edge.
    final vT = pointScreen - topScreen;
    final tT = vT.dx * dirX + vT.dy * dirY;
    final projT = topScreen + Offset(dirX * tT, dirY * tT);
    final distT = (pointScreen - projT).distance;

    // If the point is on the ruler body, always project to nearest edge.
    // If outside but near an edge, snap within threshold.
    final onRuler = _isPointOnRuler(pointScreen);
    final dist = math.min(distB, distT);
    if (!onRuler && dist >= _rulerSnapThreshold) return point;

    final projected = distB <= distT ? projB : projT;
    final canvasProj = transform.screenToCanvas(projected);

    return core.DrawingPoint(
      x: canvasProj.dx,
      y: canvasProj.dy,
      pressure: point.pressure,
      tilt: point.tilt,
      timestamp: point.timestamp,
    );
  }
}

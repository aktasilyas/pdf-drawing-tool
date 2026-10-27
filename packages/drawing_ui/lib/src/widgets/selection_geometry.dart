import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// What a pointer-down on the selection grabs.
enum SelectionDragMode { move, rotate, scale }

/// Result of [SelectionGeometry.hitTest].
class SelectionHit {
  /// What the drag does.
  final SelectionDragMode mode;

  /// The grabbed scale handle; only set for [SelectionDragMode.scale].
  final SelectionHandle? handle;

  /// Drag origin in canvas coordinates: the handle centre for a scale drag,
  /// the pointer position otherwise.
  final Offset anchor;

  const SelectionHit(this.mode, this.anchor, {this.handle});
}

/// Pure geometry for the selection handles: hit testing, live move clamping,
/// scale factors and bounds. All positions are in canvas coordinates.
abstract final class SelectionGeometry {
  /// Minimum handle hit radius in screen (logical) pixels at any zoom.
  static const double minScreenHitRadius = 24.0;

  /// Hit radius in canvas units below which a handle is never shrunk, so a
  /// handle is always at least as grabbable as it is drawn when zoomed in.
  static const double minCanvasHitRadius = 22.0;

  /// Distance from the top edge centre to the rotation handle.
  static const double rotationHandleDistance = 36.0;

  /// Smallest width/height a scale drag can shrink the selection to.
  static const double minSize = 20.0;

  /// Pointer travel (canvas units) below which a pointer-up is a tap.
  static const double tapSlop = 18.0;

  /// Handle hit radius in canvas units for the given canvas [zoom], so that
  /// it is at least [minScreenHitRadius] logical pixels on screen.
  static double hitRadius(double zoom) {
    if (zoom <= 0) return minCanvasHitRadius;
    return math.max(minCanvasHitRadius, minScreenHitRadius / zoom);
  }

  /// Centre of the selection bounds.
  static Offset center(BoundingBox b) =>
      Offset((b.left + b.right) / 2, (b.top + b.bottom) / 2);

  /// Position of the rotation handle above the top edge.
  static Offset rotationHandle(BoundingBox b) =>
      Offset((b.left + b.right) / 2, b.top - rotationHandleDistance);

  /// Whether [p] lies inside (or on the edge of) [b].
  static bool contains(Offset p, BoundingBox b) =>
      p.dx >= b.left && p.dx <= b.right && p.dy >= b.top && p.dy <= b.bottom;

  /// Positions of the eight scale handles.
  static List<(SelectionHandle, Offset)> scaleHandles(BoundingBox b) {
    final c = center(b);
    return [
      (SelectionHandle.topLeft, Offset(b.left, b.top)),
      (SelectionHandle.topRight, Offset(b.right, b.top)),
      (SelectionHandle.bottomLeft, Offset(b.left, b.bottom)),
      (SelectionHandle.bottomRight, Offset(b.right, b.bottom)),
      (SelectionHandle.topCenter, Offset(c.dx, b.top)),
      (SelectionHandle.bottomCenter, Offset(c.dx, b.bottom)),
      (SelectionHandle.middleLeft, Offset(b.left, c.dy)),
      (SelectionHandle.middleRight, Offset(b.right, c.dy)),
    ];
  }

  /// Whether [h] is one of the four corner handles (uniform scale).
  static bool isCorner(SelectionHandle h) =>
      h == SelectionHandle.topLeft ||
      h == SelectionHandle.topRight ||
      h == SelectionHandle.bottomLeft ||
      h == SelectionHandle.bottomRight;

  /// What a pointer-down at [p] grabs, or `null` when it is outside the
  /// selection and all handles.
  ///
  /// The nearest handle (rotation handle included) within [hitRadius] wins,
  /// so overlapping hit areas at low zoom stay predictable.
  static SelectionHit? hitTest(Offset p, BoundingBox b, {double zoom = 1.0}) {
    final r = hitRadius(zoom);
    SelectionHit? best;
    var bestDist = double.infinity;

    final rot = rotationHandle(b);
    final rotDist = (p - rot).distance;
    if (rotDist <= r) {
      best = SelectionHit(SelectionDragMode.rotate, p);
      bestDist = rotDist;
    }
    for (final (handle, pos) in scaleHandles(b)) {
      final d = (p - pos).distance;
      if (d <= r && d < bestDist) {
        best = SelectionHit(SelectionDragMode.scale, pos, handle: handle);
        bestDist = d;
      }
    }
    if (best != null) return best;
    if (contains(p, b)) return SelectionHit(SelectionDragMode.move, p);
    return null;
  }

  /// Angle of [p] around the centre of [b], in radians.
  static double angleAround(Offset p, BoundingBox b) {
    final c = center(b);
    return math.atan2(p.dy - c.dy, p.dx - c.dx);
  }

  /// Clamps a live move [delta] of [b] so it stays on a page of [pageSize].
  /// A `null` [pageSize] (infinite canvas) leaves the delta unchanged.
  static Offset clampMove(Offset delta, BoundingBox b, Size? pageSize) {
    if (pageSize == null) return delta;
    final minDx = -b.left, maxDx = pageSize.width - b.right;
    final minDy = -b.top, maxDy = pageSize.height - b.bottom;
    return Offset(
      minDx <= maxDx ? delta.dx.clamp(minDx, maxDx) : delta.dx,
      minDy <= maxDy ? delta.dy.clamp(minDy, maxDy) : delta.dy,
    );
  }

  /// Scale factors for dragging [handle] of [b] from [dragStart] to [pos],
  /// around the centre of [b]. Corners scale uniformly, edges along one axis.
  /// Returns `null` for a degenerate selection or start point.
  static (double, double)? scaleFor({
    required SelectionHandle handle,
    required BoundingBox b,
    required Offset dragStart,
    required Offset pos,
    Size? pageSize,
  }) {
    final c = center(b);
    final halfW = (b.right - b.left) / 2, halfH = (b.bottom - b.top) / 2;
    if (halfW < 1 || halfH < 1) return null;

    double sx = 1.0, sy = 1.0;
    if (isCorner(handle)) {
      final d0 = (dragStart - c).distance;
      if (d0 < 1) return null;
      sx = (pos - c).distance / d0;
      sy = sx;
    } else {
      switch (handle) {
        case SelectionHandle.topCenter:
        case SelectionHandle.bottomCenter:
          final d0 = (dragStart.dy - c.dy).abs();
          if (d0 < 1) return null;
          sy = (pos.dy - c.dy).abs() / d0;
        case SelectionHandle.middleLeft:
        case SelectionHandle.middleRight:
          final d0 = (dragStart.dx - c.dx).abs();
          if (d0 < 1) return null;
          sx = (pos.dx - c.dx).abs() / d0;
        default:
          break;
      }
    }
    if (halfW * 2 * sx < minSize) sx = minSize / (halfW * 2);
    if (halfH * 2 * sy < minSize) sy = minSize / (halfH * 2);
    if (pageSize != null) {
      final maxX = math.min(c.dx, pageSize.width - c.dx) / halfW;
      final maxY = math.min(c.dy, pageSize.height - c.dy) / halfH;
      if (sx > maxX) sx = maxX;
      if (sy > maxY) sy = maxY;
    }
    if (isCorner(handle)) {
      final f = math.min(sx, sy);
      sx = f;
      sy = f;
    }
    return (sx, sy);
  }

  /// [b] moved by [delta].
  static BoundingBox translate(BoundingBox b, Offset delta) => BoundingBox(
        left: b.left + delta.dx,
        top: b.top + delta.dy,
        right: b.right + delta.dx,
        bottom: b.bottom + delta.dy,
      );

  /// Smallest box containing all [boxes], or `null` when there are none.
  static BoundingBox? union(Iterable<BoundingBox> boxes) {
    BoundingBox? out;
    for (final b in boxes) {
      out = out == null
          ? b
          : BoundingBox(
              left: math.min(out.left, b.left),
              top: math.min(out.top, b.top),
              right: math.max(out.right, b.right),
              bottom: math.max(out.bottom, b.bottom),
            );
    }
    return out;
  }
}

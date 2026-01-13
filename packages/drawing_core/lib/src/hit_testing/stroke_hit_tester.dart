import 'dart:math';

import 'package:drawing_core/src/internal.dart';

/// Stroke hit testing implementation.
///
/// Performans kritik! Bounding box pre-filter ile %90+ stroke elenir.
///
/// Hedef: <5ms per hit test (1000 stroke ile)
class StrokeHitTester implements HitTester<Stroke> {
  const StrokeHitTester();

  @override
  bool hitTest(Stroke stroke, double x, double y, double tolerance) {
    // 1. Quick bounds check (O(1)) - 90%+ eleme
    if (!_boundsCheck(stroke, x, y, tolerance)) {
      return false;
    }

    // 2. Detailed segment check
    return _segmentCheck(stroke, x, y, tolerance);
  }

  @override
  List<Stroke> findElementsAt(
    List<Stroke> strokes,
    double x,
    double y,
    double tolerance,
  ) {
    return strokes.where((s) => hitTest(s, x, y, tolerance)).toList();
  }

  @override
  Stroke? findTopElementAt(
    List<Stroke> strokes,
    double x,
    double y,
    double tolerance,
  ) {
    // Son çizilen en üstte - tersten tara (early exit)
    for (int i = strokes.length - 1; i >= 0; i--) {
      if (hitTest(strokes[i], x, y, tolerance)) {
        return strokes[i];
      }
    }
    return null;
  }

  /// Bounding box pre-filter (HIZLI - O(1))
  ///
  /// Stroke kalınlığını da hesaba katar.
  bool _boundsCheck(Stroke stroke, double x, double y, double tolerance) {
    final bounds = stroke.bounds;
    if (bounds == null) return false;

    final effectiveTolerance = tolerance + (stroke.style.thickness / 2);

    return x >= bounds.left - effectiveTolerance &&
        x <= bounds.right + effectiveTolerance &&
        y >= bounds.top - effectiveTolerance &&
        y <= bounds.bottom + effectiveTolerance;
  }

  /// Segment distance check (DETAYLI)
  ///
  /// Her segment için point-to-segment mesafesi hesaplar.
  /// İlk hit'te durur (early exit).
  bool _segmentCheck(Stroke stroke, double x, double y, double tolerance) {
    final points = stroke.points;
    if (points.isEmpty) return false;

    final effectiveTolerance = tolerance + (stroke.style.thickness / 2);

    // Tek nokta - sadece mesafe kontrolü
    if (points.length == 1) {
      final p = points.first;
      return _distance(x, y, p.x, p.y) <= effectiveTolerance;
    }

    // Her segment için kontrol
    for (int i = 0; i < points.length - 1; i++) {
      final distance = _pointToSegmentDistance(
        x,
        y,
        points[i].x,
        points[i].y,
        points[i + 1].x,
        points[i + 1].y,
      );

      if (distance <= effectiveTolerance) {
        return true; // Early exit - ilk hit'te dur
      }
    }

    return false;
  }

  /// İki nokta arası Euclidean mesafe
  double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  /// Nokta ile çizgi segmenti arasındaki en kısa mesafe.
  ///
  /// Algoritma:
  /// 1. Noktanın segment üzerine projeksiyonunu hesapla
  /// 2. Projeksiyon segment dışındaysa en yakın uç noktayı kullan
  /// 3. Projeksiyon noktası ile test noktası arası mesafeyi döndür
  double _pointToSegmentDistance(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    // Segment aslında bir nokta
    if (dx == 0 && dy == 0) {
      return _distance(px, py, x1, y1);
    }

    // Projeksiyon parametresi (0-1 arası segment üzerinde)
    // t < 0: en yakın nokta segment başlangıcı
    // t > 1: en yakın nokta segment sonu
    // 0 <= t <= 1: en yakın nokta segment üzerinde
    final t = max(
      0.0,
      min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)),
    );

    // En yakın nokta koordinatları
    final nearestX = x1 + t * dx;
    final nearestY = y1 + t * dy;

    return _distance(px, py, nearestX, nearestY);
  }
}

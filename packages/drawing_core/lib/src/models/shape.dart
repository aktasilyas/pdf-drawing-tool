import 'dart:math';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

/// Geometrik şekil modeli
class Shape {
  /// Unique identifier
  final String id;

  /// Şekil tipi
  final ShapeType type;

  /// Başlangıç noktası
  final DrawingPoint startPoint;

  /// Bitiş noktası
  final DrawingPoint endPoint;

  /// Çizgi stili
  final StrokeStyle style;

  /// İçi dolu mu?
  final bool isFilled;

  const Shape({
    required this.id,
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.style,
    this.isFilled = false,
  });

  /// Factory - yeni shape oluştur
  factory Shape.create({
    required ShapeType type,
    required DrawingPoint startPoint,
    required DrawingPoint endPoint,
    required StrokeStyle style,
    bool isFilled = false,
  }) {
    return Shape(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      startPoint: startPoint,
      endPoint: endPoint,
      style: style,
      isFilled: isFilled,
    );
  }

  /// Bounding box
  BoundingBox get bounds {
    final halfThickness = style.thickness / 2;

    final left = min(startPoint.x, endPoint.x) - halfThickness;
    final top = min(startPoint.y, endPoint.y) - halfThickness;
    final right = max(startPoint.x, endPoint.x) + halfThickness;
    final bottom = max(startPoint.y, endPoint.y) + halfThickness;

    return BoundingBox(left: left, top: top, right: right, bottom: bottom);
  }

  /// Genişlik
  double get width => (endPoint.x - startPoint.x).abs();

  /// Yükseklik
  double get height => (endPoint.y - startPoint.y).abs();

  /// Merkez X koordinatı
  double get centerX => (startPoint.x + endPoint.x) / 2;

  /// Merkez Y koordinatı
  double get centerY => (startPoint.y + endPoint.y) / 2;

  /// Sol kenar (normalized)
  double get left => min(startPoint.x, endPoint.x);

  /// Üst kenar (normalized)
  double get top => min(startPoint.y, endPoint.y);

  /// Sağ kenar (normalized)
  double get right => max(startPoint.x, endPoint.x);

  /// Alt kenar (normalized)
  double get bottom => max(startPoint.y, endPoint.y);

  /// Hit test - nokta shape üzerinde mi?
  bool containsPoint(double x, double y, double tolerance) {
    // Önce bounds check
    final b = bounds;
    if (x < b.left - tolerance ||
        x > b.right + tolerance ||
        y < b.top - tolerance ||
        y > b.bottom + tolerance) {
      return false;
    }

    switch (type) {
      case ShapeType.line:
        return _lineContainsPoint(x, y, tolerance);
      case ShapeType.arrow:
        return _arrowContainsPoint(x, y, tolerance);
      case ShapeType.rectangle:
        return _rectangleContainsPoint(x, y, tolerance);
      case ShapeType.ellipse:
        return _ellipseContainsPoint(x, y, tolerance);
    }
  }

  bool _lineContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    return _pointToLineDistance(
          x,
          y,
          startPoint.x,
          startPoint.y,
          endPoint.x,
          endPoint.y,
        ) <=
        effectiveTolerance;
  }

  bool _arrowContainsPoint(double x, double y, double tolerance) {
    // Ana çizgi kontrolü
    if (_lineContainsPoint(x, y, tolerance)) return true;

    // Ok başı kontrolü (basitleştirilmiş - bounds check yeterli)
    final arrowHeadSize = style.thickness * 4;
    final dx = endPoint.x - startPoint.x;
    final dy = endPoint.y - startPoint.y;
    final length = sqrt(dx * dx + dy * dy);

    if (length < 1) return false;

    // Ok başı bölgesinde mi?
    final distToEnd = sqrt(pow(x - endPoint.x, 2) + pow(y - endPoint.y, 2));
    return distToEnd <= arrowHeadSize + tolerance;
  }

  bool _rectangleContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    final b = bounds;

    if (isFilled) {
      // İçi dolu - bounds içinde mi?
      return x >= b.left - effectiveTolerance &&
          x <= b.right + effectiveTolerance &&
          y >= b.top - effectiveTolerance &&
          y <= b.bottom + effectiveTolerance;
    } else {
      // Sadece kenarlar
      final onLeft = (x - b.left).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onRight = (x - b.right).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onTop = (y - b.top).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;
      final onBottom = (y - b.bottom).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;

      return onLeft || onRight || onTop || onBottom;
    }
  }

  bool _ellipseContainsPoint(double x, double y, double tolerance) {
    final cx = centerX;
    final cy = centerY;
    final rx = width / 2;
    final ry = height / 2;

    if (rx < 1 || ry < 1) return false;

    // Normalize edilmiş mesafe
    final normalizedDist = pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2);

    if (isFilled) {
      return normalizedDist <= 1.0 + tolerance / min(rx, ry);
    } else {
      // Kenar üzerinde mi?
      final innerRx = rx - style.thickness / 2;
      final innerRy = ry - style.thickness / 2;
      final outerRx = rx + style.thickness / 2;
      final outerRy = ry + style.thickness / 2;

      final innerDist = innerRx > 0 && innerRy > 0
          ? pow((x - cx) / innerRx, 2) + pow((y - cy) / innerRy, 2)
          : 0.0;
      final outerDist =
          pow((x - cx) / outerRx, 2) + pow((y - cy) / outerRy, 2);

      return outerDist <= 1.0 + tolerance / min(rx, ry) &&
          innerDist >= 1.0 - tolerance / min(rx, ry);
    }
  }

  double _pointToLineDistance(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
    }

    final t = max(
        0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)));

    final nearestX = x1 + t * dx;
    final nearestY = y1 + t * dy;

    return sqrt(pow(px - nearestX, 2) + pow(py - nearestY, 2));
  }

  /// Immutable copy
  Shape copyWith({
    DrawingPoint? startPoint,
    DrawingPoint? endPoint,
    StrokeStyle? style,
    bool? isFilled,
  }) {
    return Shape(
      id: id,
      type: type,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      style: style ?? this.style,
      isFilled: isFilled ?? this.isFilled,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'startPoint': startPoint.toJson(),
        'endPoint': endPoint.toJson(),
        'style': style.toJson(),
        'isFilled': isFilled,
      };

  /// JSON deserialization
  factory Shape.fromJson(Map<String, dynamic> json) {
    return Shape(
      id: json['id'] as String,
      type: ShapeType.values.byName(json['type'] as String),
      startPoint:
          DrawingPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
      endPoint:
          DrawingPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      isFilled: (json['isFilled'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shape && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

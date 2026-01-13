# Phase 4C: Shape Tools - Technical Specification

> **Module**: Shape Tools  
> **Package**: `drawing_core` + `drawing_ui`  
> **Priority**: 🟡 YÜKSEK

---

## 🎯 Amaç

Geometrik şekil çizme araçları:
1. **Line Tool**: Düz çizgi
2. **Rectangle Tool**: Dikdörtgen
3. **Ellipse Tool**: Elips/Daire
4. **Arrow Tool**: Ok işareti

---

## 📐 Shape Model

### Shape Type Enum

```dart
// lib/src/models/shape_type.dart

enum ShapeType {
  line,
  rectangle,
  ellipse,
  arrow,
}
```

### Shape Model

```dart
// lib/src/models/shape.dart

/// Geometrik şekil modeli
class Shape {
  final String id;
  final ShapeType type;
  final DrawingPoint startPoint;
  final DrawingPoint endPoint;
  final StrokeStyle style;
  final bool isFilled;
  final BoundingBox? _cachedBounds;
  
  const Shape({
    required this.id,
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.style,
    this.isFilled = false,
  }) : _cachedBounds = null;
  
  /// Factory constructor - yeni shape oluştur
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
  
  /// Bounding box hesapla
  BoundingBox get bounds {
    if (_cachedBounds != null) return _cachedBounds!;
    
    final halfThickness = style.thickness / 2;
    
    double left, top, right, bottom;
    
    switch (type) {
      case ShapeType.line:
      case ShapeType.arrow:
        left = min(startPoint.x, endPoint.x) - halfThickness;
        top = min(startPoint.y, endPoint.y) - halfThickness;
        right = max(startPoint.x, endPoint.x) + halfThickness;
        bottom = max(startPoint.y, endPoint.y) + halfThickness;
        break;
        
      case ShapeType.rectangle:
      case ShapeType.ellipse:
        left = min(startPoint.x, endPoint.x) - halfThickness;
        top = min(startPoint.y, endPoint.y) - halfThickness;
        right = max(startPoint.x, endPoint.x) + halfThickness;
        bottom = max(startPoint.y, endPoint.y) + halfThickness;
        break;
    }
    
    return BoundingBox(left: left, top: top, right: right, bottom: bottom);
  }
  
  /// Genişlik
  double get width => (endPoint.x - startPoint.x).abs();
  
  /// Yükseklik
  double get height => (endPoint.y - startPoint.y).abs();
  
  /// Merkez nokta
  Offset get center => Offset(
    (startPoint.x + endPoint.x) / 2,
    (startPoint.y + endPoint.y) / 2,
  );
  
  /// Hit test - nokta shape üzerinde mi?
  bool containsPoint(double x, double y, double tolerance) {
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
      x, y,
      startPoint.x, startPoint.y,
      endPoint.x, endPoint.y,
    ) <= effectiveTolerance;
  }
  
  bool _arrowContainsPoint(double x, double y, double tolerance) {
    // Ana çizgi kontrolü
    if (_lineContainsPoint(x, y, tolerance)) return true;
    
    // Ok başı kontrolü (basitleştirilmiş)
    final arrowHeadSize = style.thickness * 3;
    final dx = endPoint.x - startPoint.x;
    final dy = endPoint.y - startPoint.y;
    final length = sqrt(dx * dx + dy * dy);
    
    if (length < 1) return false;
    
    final unitX = dx / length;
    final unitY = dy / length;
    
    // Ok başı üçgeninin köşeleri
    final tipX = endPoint.x;
    final tipY = endPoint.y;
    final baseX = tipX - unitX * arrowHeadSize;
    final baseY = tipY - unitY * arrowHeadSize;
    
    // Sol ve sağ kanatlar
    final perpX = -unitY * arrowHeadSize * 0.5;
    final perpY = unitX * arrowHeadSize * 0.5;
    
    final leftX = baseX + perpX;
    final leftY = baseY + perpY;
    final rightX = baseX - perpX;
    final rightY = baseY - perpY;
    
    // Üçgen içinde mi?
    return _pointInTriangle(x, y, tipX, tipY, leftX, leftY, rightX, rightY);
  }
  
  bool _rectangleContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    final bounds = this.bounds;
    
    if (isFilled) {
      // İçi dolu - bounds içinde mi?
      return x >= bounds.left - effectiveTolerance &&
             x <= bounds.right + effectiveTolerance &&
             y >= bounds.top - effectiveTolerance &&
             y <= bounds.bottom + effectiveTolerance;
    } else {
      // Sadece kenarlar - kenar üzerinde mi?
      final onLeft = (x - bounds.left).abs() <= effectiveTolerance &&
                     y >= bounds.top && y <= bounds.bottom;
      final onRight = (x - bounds.right).abs() <= effectiveTolerance &&
                      y >= bounds.top && y <= bounds.bottom;
      final onTop = (y - bounds.top).abs() <= effectiveTolerance &&
                    x >= bounds.left && x <= bounds.right;
      final onBottom = (y - bounds.bottom).abs() <= effectiveTolerance &&
                       x >= bounds.left && x <= bounds.right;
      
      return onLeft || onRight || onTop || onBottom;
    }
  }
  
  bool _ellipseContainsPoint(double x, double y, double tolerance) {
    final cx = center.dx;
    final cy = center.dy;
    final rx = width / 2;
    final ry = height / 2;
    
    if (rx < 1 || ry < 1) return false;
    
    // Normalize edilmiş mesafe
    final normalizedDist = pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2);
    
    if (isFilled) {
      // İçi dolu - elips içinde mi?
      return normalizedDist <= 1.0 + tolerance / min(rx, ry);
    } else {
      // Sadece kenar - kenar üzerinde mi?
      final innerDist = pow((x - cx) / (rx - style.thickness/2), 2) +
                        pow((y - cy) / (ry - style.thickness/2), 2);
      final outerDist = pow((x - cx) / (rx + style.thickness/2), 2) +
                        pow((y - cy) / (ry + style.thickness/2), 2);
      
      return outerDist <= 1.0 + tolerance / min(rx, ry) &&
             innerDist >= 1.0 - tolerance / min(rx, ry);
    }
  }
  
  double _pointToLineDistance(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    
    if (dx == 0 && dy == 0) {
      return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
    }
    
    final t = max(0.0, min(1.0,
      ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    ));
    
    final nearestX = x1 + t * dx;
    final nearestY = y1 + t * dy;
    
    return sqrt(pow(px - nearestX, 2) + pow(py - nearestY, 2));
  }
  
  bool _pointInTriangle(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
  ) {
    final d1 = _sign(px, py, x1, y1, x2, y2);
    final d2 = _sign(px, py, x2, y2, x3, y3);
    final d3 = _sign(px, py, x3, y3, x1, y1);
    
    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
    
    return !(hasNeg && hasPos);
  }
  
  double _sign(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    return (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2);
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
  
  factory Shape.fromJson(Map<String, dynamic> json) {
    return Shape(
      id: json['id'],
      type: ShapeType.values.byName(json['type']),
      startPoint: DrawingPoint.fromJson(json['startPoint']),
      endPoint: DrawingPoint.fromJson(json['endPoint']),
      style: StrokeStyle.fromJson(json['style']),
      isFilled: json['isFilled'] ?? false,
    );
  }
}
```

---

## 📦 Shape Tools

### ShapeTool Abstract

```dart
// lib/src/tools/shape_tool.dart

abstract class ShapeTool extends DrawingTool {
  DrawingPoint? _startPoint;
  DrawingPoint? _currentPoint;
  bool _isDrawing = false;
  
  ShapeTool({required StrokeStyle style}) : super(style);
  
  /// Shape tipi
  ShapeType get shapeType;
  
  /// İçi dolu mu?
  bool get isFilled => false;
  
  /// Çizim başlat
  void startShape(DrawingPoint point) {
    _startPoint = point;
    _currentPoint = point;
    _isDrawing = true;
  }
  
  /// Çizimi güncelle
  void updateShape(DrawingPoint point) {
    if (!_isDrawing) return;
    _currentPoint = point;
  }
  
  /// Çizimi tamamla ve Shape döndür
  Shape? endShape() {
    if (!_isDrawing || _startPoint == null || _currentPoint == null) {
      cancelShape();
      return null;
    }
    
    _isDrawing = false;
    
    // Minimum boyut kontrolü
    final dx = (_currentPoint!.x - _startPoint!.x).abs();
    final dy = (_currentPoint!.y - _startPoint!.y).abs();
    
    if (dx < 5 && dy < 5) {
      _clear();
      return null;
    }
    
    final shape = Shape.create(
      type: shapeType,
      startPoint: _startPoint!,
      endPoint: _currentPoint!,
      style: style,
      isFilled: isFilled,
    );
    
    _clear();
    return shape;
  }
  
  /// Çizimi iptal et
  void cancelShape() {
    _clear();
  }
  
  void _clear() {
    _startPoint = null;
    _currentPoint = null;
    _isDrawing = false;
  }
  
  /// Çizim aktif mi?
  bool get isDrawing => _isDrawing;
  
  /// Geçerli başlangıç noktası
  DrawingPoint? get startPoint => _startPoint;
  
  /// Geçerli bitiş noktası
  DrawingPoint? get currentPoint => _currentPoint;
  
  /// Preview için geçici shape
  Shape? get previewShape {
    if (!_isDrawing || _startPoint == null || _currentPoint == null) {
      return null;
    }
    
    return Shape.create(
      type: shapeType,
      startPoint: _startPoint!,
      endPoint: _currentPoint!,
      style: style,
      isFilled: isFilled,
    );
  }
  
  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    // Shape tool stroke oluşturmaz
    return Stroke.create(style: style);
  }
}
```

### Concrete Shape Tools

```dart
// lib/src/tools/line_tool.dart

class LineTool extends ShapeTool {
  LineTool({required StrokeStyle style}) : super(style: style);
  
  @override
  ShapeType get shapeType => ShapeType.line;
}
```

```dart
// lib/src/tools/rectangle_tool.dart

class RectangleTool extends ShapeTool {
  final bool filled;
  
  RectangleTool({
    required StrokeStyle style,
    this.filled = false,
  }) : super(style: style);
  
  @override
  ShapeType get shapeType => ShapeType.rectangle;
  
  @override
  bool get isFilled => filled;
}
```

```dart
// lib/src/tools/ellipse_tool.dart

class EllipseTool extends ShapeTool {
  final bool filled;
  
  EllipseTool({
    required StrokeStyle style,
    this.filled = false,
  }) : super(style: style);
  
  @override
  ShapeType get shapeType => ShapeType.ellipse;
  
  @override
  bool get isFilled => filled;
}
```

```dart
// lib/src/tools/arrow_tool.dart

class ArrowTool extends ShapeTool {
  ArrowTool({required StrokeStyle style}) : super(style: style);
  
  @override
  ShapeType get shapeType => ShapeType.arrow;
}
```

---

## 📦 Shape Commands

```dart
// lib/src/history/add_shape_command.dart

class AddShapeCommand implements DrawingCommand {
  final int layerIndex;
  final Shape shape;
  
  AddShapeCommand({
    required this.layerIndex,
    required this.shape,
  });
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addShape(shape);
    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeShape(shape.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  String get description => 'Add ${shape.type.name}';
}
```

```dart
// lib/src/history/remove_shape_command.dart

class RemoveShapeCommand implements DrawingCommand {
  final int layerIndex;
  final String shapeId;
  Shape? _removedShape;
  
  RemoveShapeCommand({
    required this.layerIndex,
    required this.shapeId,
  });
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _removedShape = layer.shapes.firstWhere((s) => s.id == shapeId);
    final updatedLayer = layer.removeShape(shapeId);
    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedShape == null) return document;
    
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addShape(_removedShape!);
    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  String get description => 'Remove shape';
}
```

---

## 📦 drawing_ui: Shape Painter

```dart
// lib/src/canvas/shape_painter.dart

class ShapePainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? activeShape;  // Preview için
  
  ShapePainter({
    required this.shapes,
    this.activeShape,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Committed shapes
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }
    
    // Active shape (preview)
    if (activeShape != null) {
      _drawShape(canvas, activeShape!, isPreview: true);
    }
  }
  
  void _drawShape(Canvas canvas, Shape shape, {bool isPreview = false}) {
    final paint = Paint()
      ..color = Color(shape.style.color).withOpacity(
        isPreview ? 0.5 : shape.style.opacity
      )
      ..strokeWidth = shape.style.thickness
      ..style = shape.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    
    switch (shape.type) {
      case ShapeType.line:
        _drawLine(canvas, shape, paint);
        break;
      case ShapeType.rectangle:
        _drawRectangle(canvas, shape, paint);
        break;
      case ShapeType.ellipse:
        _drawEllipse(canvas, shape, paint);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shape, paint);
        break;
    }
  }
  
  void _drawLine(Canvas canvas, Shape shape, Paint paint) {
    canvas.drawLine(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
      paint,
    );
  }
  
  void _drawRectangle(Canvas canvas, Shape shape, Paint paint) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawRect(rect, paint);
  }
  
  void _drawEllipse(Canvas canvas, Shape shape, Paint paint) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawOval(rect, paint);
  }
  
  void _drawArrow(Canvas canvas, Shape shape, Paint paint) {
    final start = Offset(shape.startPoint.x, shape.startPoint.y);
    final end = Offset(shape.endPoint.x, shape.endPoint.y);
    
    // Ana çizgi
    canvas.drawLine(start, end, paint);
    
    // Ok başı
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    
    if (length < 10) return;
    
    final unitX = dx / length;
    final unitY = dy / length;
    
    final arrowHeadSize = shape.style.thickness * 4;
    
    final baseX = end.dx - unitX * arrowHeadSize;
    final baseY = end.dy - unitY * arrowHeadSize;
    
    final perpX = -unitY * arrowHeadSize * 0.5;
    final perpY = unitX * arrowHeadSize * 0.5;
    
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(baseX + perpX, baseY + perpY)
      ..lineTo(baseX - perpX, baseY - perpY)
      ..close();
    
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);
  }
  
  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
           oldDelegate.activeShape != activeShape;
  }
}
```

---

## 🧪 Test Senaryoları

```dart
group('Shape Model', () {
  test('line bounds calculation');
  test('rectangle bounds calculation');
  test('ellipse bounds calculation');
  test('line hit test');
  test('rectangle hit test (stroke)');
  test('rectangle hit test (filled)');
  test('ellipse hit test');
  test('arrow hit test');
});

group('Shape Tools', () {
  test('LineTool creates line shape');
  test('RectangleTool creates rectangle');
  test('EllipseTool creates ellipse');
  test('ArrowTool creates arrow');
  test('minimum size validation');
  test('preview shape generation');
});
```

---

## 📋 Checklist

```
□ shape_type.dart oluşturuldu
□ shape.dart oluşturuldu
□ shape_tool.dart (abstract) oluşturuldu
□ line_tool.dart oluşturuldu
□ rectangle_tool.dart oluşturuldu
□ ellipse_tool.dart oluşturuldu
□ arrow_tool.dart oluşturuldu
□ add_shape_command.dart oluşturuldu
□ remove_shape_command.dart oluşturuldu
□ Layer model güncellendi (shapes listesi)
□ ShapePainter oluşturuldu
□ DrawingCanvas shape entegrasyonu
□ Tüm testler geçiyor
```

---

*Specification Version: 1.0*

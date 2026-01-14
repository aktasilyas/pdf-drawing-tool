import 'package:drawing_core/drawing_core.dart';

/// Shape tool için abstract base class
abstract class ShapeTool {
  DrawingPoint? _startPoint;
  DrawingPoint? _currentPoint;
  bool _isDrawing = false;

  /// Çizgi stili
  final StrokeStyle style;

  /// Constructor
  ShapeTool({required this.style});

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
}

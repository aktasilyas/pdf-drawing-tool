# Phase 4A: Eraser System - Technical Specification

> **Module**: Eraser System  
> **Package**: `drawing_core` + `drawing_ui`  
> **Priority**: 🔴 KRİTİK

---

## 🎯 Amaç

İki tip silgi implementasyonu:
1. **Pixel Eraser**: Dokunulan noktalardaki çizgi parçalarını siler
2. **Stroke Eraser**: Dokunulan çizginin tamamını siler

---

## 📐 Hit Testing Algoritması

### Temel Prensip

```
Kullanıcı Dokunuşu (x, y)
         ↓
    Tolerance Radius (örn: 10px)
         ↓
    Her Stroke İçin:
    ├── Bounding Box Check (hızlı eleme)
    │   └── Dışındaysa → SKIP
    ├── Point-to-Path Distance Check
    │   └── Mesafe > tolerance → SKIP
    └── HIT! → Stroke bulundu
```

### Bounding Box Pre-filter

```dart
bool _quickBoundsCheck(Stroke stroke, double x, double y, double tolerance) {
  final bounds = stroke.bounds;
  if (bounds == null) return false;
  
  // Tolerance ile genişletilmiş bounds
  return x >= bounds.left - tolerance &&
         x <= bounds.right + tolerance &&
         y >= bounds.top - tolerance &&
         y <= bounds.bottom + tolerance;
}
```

### Point-to-Line Segment Distance

```dart
/// Nokta ile çizgi segmenti arasındaki en kısa mesafe
double pointToSegmentDistance(
  double px, double py,  // Nokta
  double x1, double y1,  // Segment başlangıç
  double x2, double y2,  // Segment bitiş
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  
  if (dx == 0 && dy == 0) {
    // Segment aslında bir nokta
    return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
  }
  
  // Projeksiyon parametresi (0-1 arası segment üzerinde)
  final t = max(0, min(1, 
    ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
  ));
  
  // En yakın nokta
  final nearestX = x1 + t * dx;
  final nearestY = y1 + t * dy;
  
  return sqrt(pow(px - nearestX, 2) + pow(py - nearestY, 2));
}
```

### Full Stroke Hit Test

```dart
bool strokeContainsPoint(Stroke stroke, double x, double y, double tolerance) {
  final points = stroke.points;
  if (points.isEmpty) return false;
  
  // Tek nokta
  if (points.length == 1) {
    final p = points.first;
    return sqrt(pow(x - p.x, 2) + pow(y - p.y, 2)) <= tolerance;
  }
  
  // Her segment için kontrol
  for (int i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];
    
    final distance = pointToSegmentDistance(x, y, p1.x, p1.y, p2.x, p2.y);
    
    // Stroke kalınlığını da hesaba kat
    final effectiveTolerance = tolerance + (stroke.style.thickness / 2);
    
    if (distance <= effectiveTolerance) {
      return true;
    }
  }
  
  return false;
}
```

---

## 📦 drawing_core Implementasyonu

### 1. HitTester Abstract Class

```dart
// lib/src/hit_testing/hit_tester.dart

/// Hit testing için abstract interface
abstract class HitTester<T> {
  /// Verilen noktada element var mı?
  bool hitTest(T element, double x, double y, double tolerance);
  
  /// Verilen noktadaki tüm elementleri bul
  List<T> findElementsAt(List<T> elements, double x, double y, double tolerance);
  
  /// En üstteki (son çizilen) elementi bul
  T? findTopElementAt(List<T> elements, double x, double y, double tolerance);
}
```

### 2. StrokeHitTester

```dart
// lib/src/hit_testing/stroke_hit_tester.dart

class StrokeHitTester implements HitTester<Stroke> {
  const StrokeHitTester();
  
  @override
  bool hitTest(Stroke stroke, double x, double y, double tolerance) {
    // 1. Quick bounds check
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
    // Son çizilen en üstte, tersten tara
    for (int i = strokes.length - 1; i >= 0; i--) {
      if (hitTest(strokes[i], x, y, tolerance)) {
        return strokes[i];
      }
    }
    return null;
  }
  
  bool _boundsCheck(Stroke stroke, double x, double y, double tolerance) {
    final bounds = stroke.bounds;
    if (bounds == null) return false;
    
    return x >= bounds.left - tolerance &&
           x <= bounds.right + tolerance &&
           y >= bounds.top - tolerance &&
           y <= bounds.bottom + tolerance;
  }
  
  bool _segmentCheck(Stroke stroke, double x, double y, double tolerance) {
    final points = stroke.points;
    if (points.isEmpty) return false;
    
    final effectiveTolerance = tolerance + (stroke.style.thickness / 2);
    
    if (points.length == 1) {
      final p = points.first;
      return _distance(x, y, p.x, p.y) <= effectiveTolerance;
    }
    
    for (int i = 0; i < points.length - 1; i++) {
      final distance = _pointToSegmentDistance(
        x, y,
        points[i].x, points[i].y,
        points[i + 1].x, points[i + 1].y,
      );
      
      if (distance <= effectiveTolerance) {
        return true;
      }
    }
    
    return false;
  }
  
  double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
  
  double _pointToSegmentDistance(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    
    if (dx == 0 && dy == 0) {
      return _distance(px, py, x1, y1);
    }
    
    final t = max(0.0, min(1.0,
      ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    ));
    
    return _distance(px, py, x1 + t * dx, y1 + t * dy);
  }
}
```

### 3. EraserTool

```dart
// lib/src/tools/eraser_tool.dart

enum EraserMode {
  pixel,   // Nokta bazlı silme (sadece dokunulan kısım)
  stroke,  // Tüm çizgiyi sil
}

class EraserTool extends DrawingTool {
  final EraserMode mode;
  final double eraserSize;
  final StrokeHitTester _hitTester;
  
  // Silinen stroke ID'leri (bir çizim hareketi boyunca)
  final Set<String> _erasedStrokeIds = {};
  
  EraserTool({
    this.mode = EraserMode.stroke,
    this.eraserSize = 20.0,
  }) : _hitTester = const StrokeHitTester(),
       super(StrokeStyle.eraser(thickness: eraserSize));
  
  /// Verilen noktada silinecek stroke'ları bul
  List<Stroke> findStrokesToErase(
    List<Stroke> strokes,
    double x,
    double y,
  ) {
    switch (mode) {
      case EraserMode.stroke:
        // Tek stroke bul ve tamamını sil
        final stroke = _hitTester.findTopElementAt(
          strokes, x, y, eraserSize / 2,
        );
        return stroke != null ? [stroke] : [];
        
      case EraserMode.pixel:
        // TODO: Phase 4+ - Pixel bazlı silme için stroke bölme
        // Şimdilik stroke mode gibi çalışsın
        final stroke = _hitTester.findTopElementAt(
          strokes, x, y, eraserSize / 2,
        );
        return stroke != null ? [stroke] : [];
    }
  }
  
  /// Bir silme hareketi başlat
  void startErasing() {
    _erasedStrokeIds.clear();
  }
  
  /// Silme hareketinde stroke işaretle
  void markAsErased(String strokeId) {
    _erasedStrokeIds.add(strokeId);
  }
  
  /// Bu harekette zaten silindi mi?
  bool isAlreadyErased(String strokeId) {
    return _erasedStrokeIds.contains(strokeId);
  }
  
  /// Silme hareketini bitir
  Set<String> endErasing() {
    final result = Set<String>.from(_erasedStrokeIds);
    _erasedStrokeIds.clear();
    return result;
  }
  
  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    // Eraser gerçek stroke oluşturmaz
    return Stroke.create(style: style);
  }
}
```

### 4. Eraser Commands

```dart
// lib/src/history/erase_strokes_command.dart

/// Birden fazla stroke'u tek seferde silme komutu
class EraseStrokesCommand implements DrawingCommand {
  final int layerIndex;
  final List<String> strokeIds;
  final List<Stroke> _erasedStrokes = [];  // Undo için cache
  
  EraseStrokesCommand({
    required this.layerIndex,
    required this.strokeIds,
  });
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    
    // Silinecek stroke'ları cache'le
    _erasedStrokes.clear();
    _erasedStrokes.addAll(
      layer.strokes.where((s) => strokeIds.contains(s.id))
    );
    
    // Stroke'ları sil
    var updatedLayer = layer;
    for (final id in strokeIds) {
      updatedLayer = updatedLayer.removeStroke(id);
    }
    
    return document.updateLayer(layerIndex, updatedLayer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    
    // Silinen stroke'ları geri ekle
    for (final stroke in _erasedStrokes) {
      layer = layer.addStroke(stroke);
    }
    
    return document.updateLayer(layerIndex, layer);
  }
  
  @override
  String get description => 'Erase ${strokeIds.length} stroke(s)';
}
```

---

## 📦 drawing_ui Implementasyonu

### 1. Eraser Provider

```dart
// lib/src/providers/eraser_provider.dart

/// Eraser ayarları
final eraserModeProvider = StateProvider<EraserMode>((ref) => EraserMode.stroke);

final eraserSizeProvider = StateProvider<double>((ref) => 20.0);

/// Aktif eraser tool instance
final eraserToolProvider = Provider<EraserTool>((ref) {
  final mode = ref.watch(eraserModeProvider);
  final size = ref.watch(eraserSizeProvider);
  
  return EraserTool(mode: mode, eraserSize: size);
});
```

### 2. DrawingCanvas Eraser Entegrasyonu

```dart
// drawing_canvas.dart güncellemesi

void _handlePointerDown(PointerDownEvent event) {
  final toolType = ref.read(currentToolProvider);
  
  if (toolType == ToolType.eraser) {
    _handleEraserDown(event);
  } else {
    _handleDrawingDown(event);
  }
}

void _handleEraserDown(PointerDownEvent event) {
  final eraserTool = ref.read(eraserToolProvider);
  eraserTool.startErasing();
  
  _eraseAtPoint(event.localPosition);
}

void _handleEraserMove(PointerMoveEvent event) {
  _eraseAtPoint(event.localPosition);
}

void _handleEraserUp(PointerUpEvent event) {
  final eraserTool = ref.read(eraserToolProvider);
  final erasedIds = eraserTool.endErasing();
  
  if (erasedIds.isNotEmpty) {
    // Command oluştur ve execute et
    final document = ref.read(documentProvider);
    final command = EraseStrokesCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: erasedIds.toList(),
    );
    
    ref.read(historyManagerProvider.notifier).execute(command);
  }
}

void _eraseAtPoint(Offset point) {
  final transform = ref.read(canvasTransformProvider);
  final canvasPoint = (point - transform.offset) / transform.zoom;
  
  final strokes = ref.read(activeLayerStrokesProvider);
  final eraserTool = ref.read(eraserToolProvider);
  
  final toErase = eraserTool.findStrokesToErase(
    strokes,
    canvasPoint.dx,
    canvasPoint.dy,
  );
  
  for (final stroke in toErase) {
    if (!eraserTool.isAlreadyErased(stroke.id)) {
      eraserTool.markAsErased(stroke.id);
    }
  }
}
```

### 3. Eraser Cursor Indicator

```dart
// lib/src/canvas/eraser_cursor_painter.dart

class EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double size;
  final bool isActive;
  
  static final Paint _cursorPaint = Paint()
    ..color = const Color(0x40000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  
  static final Paint _fillPaint = Paint()
    ..color = const Color(0x10000000)
    ..style = PaintingStyle.fill;
  
  EraserCursorPainter({
    required this.position,
    required this.size,
    this.isActive = false,
  });
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Eraser dairesi
    canvas.drawCircle(position, size / 2, _fillPaint);
    canvas.drawCircle(position, size / 2, _cursorPaint);
  }
  
  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.size != size ||
           oldDelegate.isActive != isActive;
  }
}
```

---

## 🧪 Test Senaryoları

### Hit Testing Tests
```dart
group('StrokeHitTester', () {
  test('detects hit on straight line');
  test('detects hit on curved line');
  test('misses when outside tolerance');
  test('accounts for stroke thickness');
  test('handles single point stroke');
  test('handles empty stroke');
  test('bounding box pre-filter works');
  test('findTopElementAt returns last drawn');
});
```

### EraserTool Tests
```dart
group('EraserTool', () {
  test('stroke mode finds entire stroke');
  test('tracks erased strokes in session');
  test('prevents double-erase in same session');
  test('clears session on end');
});
```

### Integration Tests
```dart
group('Eraser Integration', () {
  test('erasing stroke removes from document');
  test('undo restores erased stroke');
  test('redo removes stroke again');
  test('erasing multiple strokes in one gesture');
});
```

---

## ⚡ Performans Hedefleri

| Operasyon | Hedef | Max |
|-----------|-------|-----|
| Single hit test | <1ms | 5ms |
| 100 stroke scan | <10ms | 50ms |
| 1000 stroke scan | <50ms | 200ms |

### Optimizasyon Stratejileri
1. Bounding box pre-filter (90%+ eleme)
2. Early exit on first hit
3. Spatial indexing (future - çok büyük dokümanlar için)

---

## 📋 Checklist

```
□ hit_tester.dart oluşturuldu
□ stroke_hit_tester.dart oluşturuldu
□ eraser_tool.dart oluşturuldu
□ erase_strokes_command.dart oluşturuldu
□ drawing_core exports güncellendi
□ eraser_provider.dart oluşturuldu
□ DrawingCanvas eraser entegrasyonu
□ Eraser cursor indicator
□ Tüm testler geçiyor
□ Performans hedefleri karşılandı
```

---

*Specification Version: 1.0*

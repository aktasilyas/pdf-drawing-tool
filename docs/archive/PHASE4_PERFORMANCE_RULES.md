# Phase 4: Performance Rules

> **ÖNEMLİ**: Phase 3 kuralları hala geçerli!
> Bu döküman Phase 4'e özel ek kuralları içerir.

---

## 📚 Phase 3 Kuralları (HALA GEÇERLİ!)

1. ✅ İki katmanlı rendering (committed vs active)
2. ✅ setState KULLANMA - ChangeNotifier/Provider kullan
3. ✅ paint() içinde allocation YAPMA
4. ✅ shouldRepaint optimize et
5. ✅ RepaintBoundary ile izole et

---

## ⚡ Phase 4 Ek Kuralları

### KURAL P4-1: Hit Testing Performansı

```
Hedef: <5ms per hit test
```

#### Bounding Box Pre-filter (ZORUNLU)

```dart
// ❌ YANLIŞ: Her stroke için segment kontrolü
bool hitTest(List<Stroke> strokes, double x, double y) {
  for (final stroke in strokes) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      // Her segment kontrol - YAVAŞ!
    }
  }
}

// ✅ DOĞRU: Önce bounding box eleme
bool hitTest(List<Stroke> strokes, double x, double y, double tolerance) {
  for (final stroke in strokes) {
    // 1. Hızlı bounds kontrolü (O(1))
    if (!_boundsCheck(stroke.bounds, x, y, tolerance)) {
      continue;  // 90%+ stroke burada elenir
    }
    
    // 2. Sadece bounds içindekiler için detaylı kontrol
    if (_segmentCheck(stroke, x, y, tolerance)) {
      return true;
    }
  }
  return false;
}
```

#### Early Exit

```dart
// ❌ YANLIŞ: Tüm stroke'ları tara
List<Stroke> findAll(List<Stroke> strokes, double x, double y) {
  return strokes.where((s) => hitTest(s, x, y)).toList();
}

// ✅ DOĞRU: İlk hit'te dur (eraser için)
Stroke? findFirst(List<Stroke> strokes, double x, double y) {
  for (final stroke in strokes) {
    if (hitTest(stroke, x, y)) return stroke;
  }
  return null;
}
```

---

### KURAL P4-2: Selection Rendering

```
Hedef: 60 FPS selection handles
```

#### Ayrı RepaintBoundary

```dart
Stack(
  children: [
    // ... other layers
    
    // Selection AYRI layer'da
    RepaintBoundary(
      child: SelectionPainter(...),
    ),
  ],
)
```

#### Lazy Bounds Calculation

```dart
class Selection {
  BoundingBox? _cachedBounds;
  
  BoundingBox get bounds {
    // Cache'den döndür, her seferinde hesaplama
    return _cachedBounds ??= _calculateBounds();
  }
  
  // Bounds değiştiğinde cache'i invalidate et
  Selection updateBounds() {
    return copyWith()
      .._cachedBounds = null;
  }
}
```

---

### KURAL P4-3: Shape Rendering

```
Hedef: <1ms per shape
```

#### Path Caching

```dart
class Shape {
  Path? _cachedPath;
  
  Path get path {
    return _cachedPath ??= _buildPath();
  }
  
  Path _buildPath() {
    switch (type) {
      case ShapeType.rectangle:
        return Path()..addRect(rect);
      case ShapeType.ellipse:
        return Path()..addOval(rect);
      // ...
    }
  }
}
```

#### Paint Object Reuse

```dart
class ShapePainter extends CustomPainter {
  // Sınıf seviyesinde cache
  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke;
  
  static final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Her shape için sadece renk/kalınlık güncelle
    _strokePaint.color = shape.color;
    _strokePaint.strokeWidth = shape.thickness;
    
    canvas.drawPath(shape.path, _strokePaint);
  }
}
```

---

### KURAL P4-4: Eraser Debouncing

```
Hedef: Maksimum 60 hit test/saniye
```

```dart
class EraserDebouncer {
  Offset? _lastPoint;
  static const double _minDistance = 5.0;
  
  bool shouldTest(Offset point) {
    if (_lastPoint == null) {
      _lastPoint = point;
      return true;
    }
    
    if ((point - _lastPoint!).distance < _minDistance) {
      return false;  // Çok yakın, atla
    }
    
    _lastPoint = point;
    return true;
  }
}
```

---

### KURAL P4-5: Command Batching

```
Hedef: Tek gesture = tek command
```

```dart
// ❌ YANLIŞ: Her silinen stroke için ayrı command
void _eraseAtPoint(Offset point) {
  final stroke = findStroke(point);
  if (stroke != null) {
    execute(RemoveStrokeCommand(stroke.id));  // Her pointer move'da!
  }
}

// ✅ DOĞRU: Gesture sonunda tek command
void _handleEraserUp() {
  if (erasedIds.isNotEmpty) {
    execute(EraseStrokesCommand(erasedIds));  // Tek command
  }
}
```

---

## 📊 Performance Metrics

### Phase 4 Specific

| Operasyon | Hedef | Warning | Critical |
|-----------|-------|---------|----------|
| Single hit test | <1ms | >3ms | >5ms |
| 100 stroke scan | <10ms | >30ms | >50ms |
| Selection render | <2ms | >5ms | >8ms |
| Shape render | <0.5ms | >1ms | >2ms |
| Move preview | <8ms | >12ms | >16ms |

### Combined (Phase 3 + 4)

| Metrik | Hedef |
|--------|-------|
| Frame time | <16ms (60 FPS) |
| Input latency | <16ms |
| Hit test per frame | Max 1 |
| Strokes per layer | Max 1000 |
| Shapes per layer | Max 500 |

---

## 🚨 Red Flags

| Red Flag | Neden Kötü | Çözüm |
|----------|-----------|-------|
| No bounds check | O(n×m) complexity | Pre-filter |
| Hit test in build() | Her frame | Move to handler |
| Path rebuild every paint | GC pressure | Cache path |
| Command per point | History overflow | Batch commands |
| Selection in same layer | Cascade repaint | Separate layer |

---

## ✅ Best Practices

| Practice | Fayda |
|----------|-------|
| Bounding box pre-filter | 90%+ early exit |
| Cached paths | No rebuild |
| Static paint objects | No allocation |
| Command batching | Clean history |
| Separate selection layer | Isolated repaint |
| Debounced hit testing | Reduced CPU |

---

## 🔧 Profiling Checklist

Phase 4 commit öncesi:

```
□ Hit test <5ms (1000 stroke ile)
□ Selection drag 60 FPS
□ Shape preview 60 FPS
□ Eraser smooth (kasma yok)
□ Undo/redo instant (<100ms)
□ Memory stable (leak yok)
```

---

*Bu kurallar Phase 3 kurallarına EK'tir, onları değiştirmez.*

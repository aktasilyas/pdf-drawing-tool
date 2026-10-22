# Phase 3: Performance Rules

> **KRİTİK**: Bu kurallar çizim performansını doğrudan etkiler.
> Kural ihlali = Kasma/Donma = Kötü UX

---

## 🎯 Hedef Metrikler

| Metrik | Hedef | Uyarı | Kritik |
|--------|-------|-------|--------|
| Frame time | <8ms | >12ms | >16ms |
| Input latency | <16ms | >24ms | >32ms |
| FPS | 60 | <50 | <30 |
| Memory/stroke | <1KB | >5KB | >10KB |
| 1000 stroke render | <100ms | >200ms | >500ms |

---

## ⚡ KURAL 1: İki Katmanlı Rendering

### Neden?
Tüm stroke'ları her frame'de çizmek = O(n) complexity = kasma

### Nasıl?
```
┌─────────────────────────────────────────┐
│   COMMITTED LAYER                        │
│   - Tamamlanmış çizimler                 │
│   - Sadece stroke eklenince repaint      │
│   - Cache'lenebilir (Picture → Image)    │
├─────────────────────────────────────────┤
│   ACTIVE LAYER                           │
│   - Şu an çizilen stroke                 │
│   - Her pointer move'da repaint          │
│   - Sadece 1 stroke = hızlı              │
└─────────────────────────────────────────┘
```

### Kod
```dart
Stack(
  children: [
    RepaintBoundary(  // İzole - diğerlerini etkilemez
      child: CustomPaint(
        painter: CommittedStrokesPainter(strokes: committedStrokes),
      ),
    ),
    RepaintBoundary(  // İzole - sadece bu repaint olur
      child: CustomPaint(
        painter: ActiveStrokePainter(points: activePoints),
      ),
    ),
  ],
)
```

---

## ⚡ KURAL 2: setState KULLANMA!

### Neden?
setState() → Widget rebuild → Tüm children rebuild → YAVAŞ

### Yanlış ❌
```dart
class _CanvasState extends State<Canvas> {
  List<Point> points = [];
  
  void onPointerMove(PointerMoveEvent e) {
    setState(() {  // 🔴 TÜM WİDGET REBUILD!
      points.add(Point(e.position));
    });
  }
}
```

### Doğru ✅
```dart
class _CanvasState extends State<Canvas> {
  final DrawingController _controller = DrawingController();
  
  void onPointerMove(PointerMoveEvent e) {
    _controller.addPoint(Point(e.position));
    // notifyListeners() sadece painter'ı tetikler
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) => CustomPaint(
        painter: ActiveStrokePainter(points: _controller.points),
      ),
    );
  }
}
```

---

## ⚡ KURAL 3: paint() İçinde Allocation YAPMA!

### Neden?
Her frame'de new object = Garbage Collection = Frame drop

### Yanlış ❌
```dart
void paint(Canvas canvas, Size size) {
  final paint = Paint()  // 🔴 HER FRAME YENİ OBJE!
    ..color = Colors.black
    ..strokeWidth = 2.0;
    
  final path = Path();  // 🔴 HER FRAME YENİ OBJE!
  // ...
}
```

### Doğru ✅
```dart
class MyPainter extends CustomPainter {
  // Önceden oluştur, tekrar kullan
  final Paint _strokePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2.0;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Cached paint kullan
    canvas.drawPath(_cachedPath, _strokePaint);
  }
}
```

---

## ⚡ KURAL 4: shouldRepaint Optimize Et!

### Neden?
shouldRepaint = true → paint() çağrılır
Gereksiz true = gereksiz render = performans kaybı

### Yanlış ❌
```dart
@override
bool shouldRepaint(CustomPainter oldDelegate) => true;  // 🔴 HER ZAMAN!
```

### Doğru ✅
```dart
@override
bool shouldRepaint(covariant MyPainter oldDelegate) {
  // Sadece gerçekten değişince
  return oldDelegate._strokeCount != _strokeCount ||
         oldDelegate._lastPointId != _lastPointId;
}
```

---

## ⚡ KURAL 5: RepaintBoundary Kullan!

### Neden?
RepaintBoundary olmadan bir child repaint olunca parent da repaint olur

### Nasıl?
```dart
Stack(
  children: [
    RepaintBoundary(  // Grid değişmez - hiç repaint olmaz
      child: GridBackground(),
    ),
    RepaintBoundary(  // Stroke eklenince repaint
      child: CommittedStrokes(),
    ),
    RepaintBoundary(  // Her pointer move'da repaint - AMA İZOLE
      child: ActiveStroke(),
    ),
    RepaintBoundary(  // UI değişince repaint - çizimi etkilemez
      child: SelectionOverlay(),
    ),
  ],
)
```

---

## ⚡ KURAL 6: Pointer Event Coalescing

### Neden?
Hızlı çizimde çok fazla event gelir → hepsini işlemek yavaşlatır

### Nasıl?
```dart
void onPointerMove(PointerMoveEvent event) {
  // Flutter otomatik coalesce yapar, ama ekstra kontrol:
  
  // Minimum mesafe kontrolü (çok yakın noktaları atla)
  if (_lastPoint != null) {
    final distance = (event.localPosition - _lastPoint!).distance;
    if (distance < 1.0) return;  // 1 pikselden yakınsa atla
  }
  
  _controller.addPoint(event.localPosition);
  _lastPoint = event.localPosition;
}
```

---

## ⚡ KURAL 7: Long Stroke Segmentation

### Neden?
Çok uzun stroke (10,000+ point) → render yavaşlar

### Nasıl?
```dart
class Stroke {
  static const int MAX_POINTS = 500;
  
  Stroke addPoint(DrawingPoint point) {
    if (points.length >= MAX_POINTS) {
      // Yeni segment başlat
      return _createNewSegment(point);
    }
    return _addPointNormally(point);
  }
}
```

---

## 📊 Performans Test Checklist

Her commit öncesi kontrol et:

```
□ DevTools Performance tab açık mı?
□ Frame time <16ms mi?
□ Jank (kırmızı frame) var mı?
□ Memory sürekli artıyor mu? (leak)
□ 1000 stroke ile test edildi mi?
□ Rapid drawing test edildi mi?
```

---

## 🔧 Debug Araçları

### Frame Time Logger
```dart
class PerformanceMonitor {
  static void trackFrame(String operation) {
    final stopwatch = Stopwatch()..start();
    
    // Operation...
    
    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 8) {
      debugPrint('⚠️ SLOW: $operation took ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}
```

### Paint Counter
```dart
class MyPainter extends CustomPainter {
  static int _paintCount = 0;
  
  @override
  void paint(Canvas canvas, Size size) {
    _paintCount++;
    debugPrint('Paint #$_paintCount');
    // ...
  }
}
```

---

## 🚨 Performans Red Flags

Bu pattern'leri gördüğünde ALARM:

| Red Flag | Neden Kötü |
|----------|-----------|
| `setState` in pointer handler | Widget rebuild |
| `new Paint()` in paint() | GC pressure |
| `shouldRepaint => true` | Gereksiz render |
| No RepaintBoundary | Cascade repaint |
| List copy in paint() | Memory allocation |
| Unbounded stroke points | Memory + render time |

---

## ✅ Performans Best Practices

| Practice | Fayda |
|----------|-------|
| Two-layer rendering | O(1) active render |
| ChangeNotifier | No widget rebuild |
| Cached Paint objects | No GC pressure |
| Smart shouldRepaint | Minimal repaints |
| RepaintBoundary | Isolated repaints |
| Point distance filter | Reduced point count |
| Stroke segmentation | Bounded render time |

---

*Bu kurallar her çizim kodu yazılırken uygulanmalıdır.*

# Phase 3: Quality Standards

> **HEDEF**: Profesyonel kalitede çizim deneyimi.
> Bulanık çizim = Amatör uygulama = KABUL EDİLEMEZ

---

## 🎨 Rendering Kalite Hedefleri

| Özellik | Hedef | Kabul Edilemez |
|---------|-------|----------------|
| Zoom netliği | Her zaman keskin | Pikselleşme |
| Çizgi smoothness | Bezier curves | Keskin köşeler |
| Anti-aliasing | Her zaman ON | Jagged edges |
| Text netliği | Her zoom'da net | Bulanık text |
| PDF netliği | Zoom-aware DPI | Düşük çözünürlük |

---

## 📐 KURAL 1: Vektör Öncelikli Yaklaşım

### Neden Vektör?
```
RASTER (Bitmap):
- Zoom in → Piksel görünür
- Kalite = Çözünürlük ile sınırlı
- Bellek = Boyut × Boyut × 4 byte

VEKTÖR (Path):
- Zoom in → Her zaman keskin
- Kalite = Sonsuz
- Bellek = Point sayısı × ~20 byte
```

### Nasıl?
```dart
// ❌ YANLIŞ: Bitmap cache
ui.Image strokeCache;  // Zoom'da bulanık!

// ✅ DOĞRU: Path olarak sakla
Path strokePath;  // Her zoom'da yeniden render
```

---

## 📐 KURAL 2: Zoom-Aware Rendering

### Zoom Sırasında
```dart
// Geçici olarak mevcut görüntüyü scale et (OK)
Transform.scale(
  scale: _currentZoom,
  child: CachedStrokesImage(),  // Geçici bulanıklık kabul edilebilir
)
```

### Zoom Sonrası
```dart
// Kullanıcı zoom'u bırakınca yeniden render et
void onScaleEnd(ScaleEndDetails details) {
  // Debounce ile bekle
  _zoomDebouncer.run(() {
    _invalidateCache();
    _rerenderAtCurrentZoom();  // Vektörden yeniden çiz
  });
}
```

### Cache Invalidation
```dart
bool _shouldInvalidateCache(double newZoom) {
  final ratio = newZoom / _cachedZoom;
  // %50'den fazla değişim varsa yeniden render
  return ratio < 0.5 || ratio > 2.0;
}
```

---

## 📐 KURAL 3: Device Pixel Ratio

### Neden?
- iPhone Retina: 2x veya 3x pixel density
- Android: 1x - 4x arası değişir
- Düşük DPI render = Retina'da bulanık

### Nasıl?
```dart
@override
void paint(Canvas canvas, Size size) {
  // Device pixel ratio al
  final dpr = WidgetsBinding.instance.window.devicePixelRatio;
  
  // Yüksek çözünürlük için hesaba kat
  // (Flutter genelde otomatik yapar, ama cache'lerde dikkat)
}

// Cache oluştururken:
Future<ui.Image> createCache(Size size) async {
  final dpr = window.devicePixelRatio;
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // DPR ile scale
  canvas.scale(dpr);
  _renderStrokes(canvas);
  
  final picture = recorder.endRecording();
  
  // Yüksek çözünürlüklü image
  return picture.toImage(
    (size.width * dpr).toInt(),
    (size.height * dpr).toInt(),
  );
}
```

---

## 📐 KURAL 4: Smooth Stroke Rendering

### Bezier Curves
```dart
Path _createSmoothPath(List<DrawingPoint> points) {
  final path = Path();
  
  if (points.length < 2) return path;
  
  path.moveTo(points[0].x, points[0].y);
  
  // Quadratic Bezier ile smooth geçiş
  for (int i = 1; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    
    // Orta nokta - smooth transition
    final midX = (p0.x + p1.x) / 2;
    final midY = (p0.y + p1.y) / 2;
    
    path.quadraticBezierTo(p0.x, p0.y, midX, midY);
  }
  
  // Son noktaya bağlan
  path.lineTo(points.last.x, points.last.y);
  
  return path;
}
```

### Catmull-Rom Spline (Daha Smooth)
```dart
// Daha gelişmiş smoothing için (Phase 4+)
Path _createCatmullRomPath(List<DrawingPoint> points) {
  // PathSmoother.smooth() kullan
  final smoothedPoints = PathSmoother.smooth(points, tension: 0.5);
  return _createSmoothPath(smoothedPoints);
}
```

---

## 📐 KURAL 5: Anti-Aliasing

### Her Zaman ON
```dart
Paint _createStrokePaint(StrokeStyle style) {
  return Paint()
    ..color = Color(style.color)
    ..strokeWidth = style.thickness
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true  // ✅ MUTLAKA!
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
```

---

## 📐 KURAL 6: Text Rendering

### Her Zaman Vektör
```dart
void renderText(Canvas canvas, String text, Offset position, double fontSize) {
  // TextPainter kullan - vektör tabanlı
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.black,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(canvas, position);
  
  // Canvas transform (zoom) otomatik olarak text'i scale eder
  // Text HER ZAMAN net görünür
}
```

---

## 📐 KURAL 7: PDF Rendering (Phase 5+)

### Zoom-Aware DPI
```dart
Future<ui.Image> renderPdfPage({
  required int pageIndex,
  required double zoom,
  required double devicePixelRatio,
}) async {
  // Hedef DPI hesapla
  // PDF default: 72 DPI
  // Target: 72 × zoom × devicePixelRatio
  final targetDPI = 72 * zoom * devicePixelRatio;
  
  // Minimum 144 DPI (2x), Maximum 576 DPI (8x)
  final clampedDPI = targetDPI.clamp(144.0, 576.0);
  
  // PDF'i bu DPI'da render et
  return await pdfRenderer.renderPage(
    pageIndex: pageIndex,
    dpi: clampedDPI,
  );
}
```

### PDF Cache Strategy
```
Zoom: 1.0x → 144 DPI cache
Zoom: 2.0x → 288 DPI cache (yeniden render)
Zoom: 4.0x → 576 DPI cache (yeniden render)
Zoom: 8.0x → 576 DPI cache (max, scale ile)
```

---

## 📐 KURAL 8: Pressure Sensitivity

### Thickness Variation
```dart
double _calculateThickness(DrawingPoint point, double baseThickness) {
  // Pressure: 0.0 (no pressure) to 1.0 (full pressure)
  // Minimum %30 kalınlık, maximum %100
  final pressureFactor = 0.3 + (point.pressure * 0.7);
  return baseThickness * pressureFactor;
}
```

### Variable Width Path
```dart
void _drawVariableWidthStroke(Canvas canvas, List<DrawingPoint> points, StrokeStyle style) {
  for (int i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];
    
    final thickness = _calculateThickness(p1, style.thickness);
    
    final paint = Paint()
      ..color = Color(style.color)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(p1.x, p1.y),
      Offset(p2.x, p2.y),
      paint,
    );
  }
}
```

---

## 🔍 Kalite Test Checklist

Her commit öncesi kontrol et:

```
□ Zoom in (%500) yapıldığında çizgiler keskin mi?
□ Zoom out (%10) yapıldığında detay kaybı var mı?
□ Text zoom'da net mi?
□ Çizgi köşeleri smooth mu (jagged değil)?
□ Retina ekranda test edildi mi?
□ Anti-aliasing açık mı?
□ Pressure sensitivity çalışıyor mu?
```

---

## 🚨 Kalite Red Flags

| Red Flag | Sonuç |
|----------|-------|
| Bitmap cache without DPI | Retina'da bulanık |
| No anti-aliasing | Jagged edges |
| Linear interpolation only | Keskin köşeler |
| Fixed resolution PDF | Zoom'da pikselleşme |
| Text as bitmap | Zoom'da bulanık |

---

## ✅ Kalite Best Practices

| Practice | Fayda |
|----------|-------|
| Path-based strokes | Infinite zoom quality |
| DPR-aware caching | Retina support |
| Bezier smoothing | Professional curves |
| Always anti-alias | Clean edges |
| TextPainter for text | Vector text |
| Zoom-aware PDF DPI | Clear documents |

---

*Bu standartlar her rendering kodu yazılırken uygulanmalıdır.*

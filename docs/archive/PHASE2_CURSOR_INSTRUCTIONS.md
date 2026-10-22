# Phase 2: Cursor Görev Talimatları

> **ÖNEMLİ**: Bu dökümanı sırayla takip et. Bir adımı bitirmeden diğerine GEÇME.

---

## 🚀 Başlangıç: Branch Oluştur

```bash
# İlk olarak feature branch oluştur
git checkout main
git pull origin main
git checkout -b feature/phase2-drawing-core
```

**Cursor'a ilk komut:**
```
Phase 2'ye başlıyoruz. feature/phase2-drawing-core branch'ini oluştur.
Sonra packages/drawing_core klasör yapısını oluştur.
pubspec.yaml dosyasını hazırla (dependencies: meta, equatable).
Henüz kod YAZMA, sadece yapıyı oluştur.
```

---

## 📋 ADIM 1: DrawingPoint Model

### Görev
```
GÖREV: DrawingPoint model oluştur

Dosya: packages/drawing_core/lib/src/models/drawing_point.dart

DrawingPoint immutable bir sınıf olacak:
- x: double (zorunlu)
- y: double (zorunlu)
- pressure: double (0.0 - 1.0, varsayılan 1.0)
- tilt: double (radyan, varsayılan 0.0)
- timestamp: int (milliseconds, varsayılan 0)

Gereksinimler:
- Equatable extend et
- copyWith metodu
- toJson / fromJson factory
- toString override

Test dosyası: test/models/drawing_point_test.dart
- Constructor test
- copyWith test
- Equality test
- JSON serialization test
- Pressure bounds test (0.0-1.0 clamp)

FLUTTER IMPORT KULLANMA!
```

### Beklenen Kod Yapısı
```dart
import 'package:equatable/equatable.dart';

class DrawingPoint extends Equatable {
  final double x;
  final double y;
  final double pressure;
  final double tilt;
  final int timestamp;

  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.timestamp = 0,
  });

  DrawingPoint copyWith({...});
  
  Map<String, dynamic> toJson() => {...};
  
  factory DrawingPoint.fromJson(Map<String, dynamic> json);

  @override
  List<Object?> get props => [x, y, pressure, tilt, timestamp];
}
```

### Tamamlama Checklist
```
□ drawing_point.dart oluşturuldu
□ drawing_point_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add DrawingPoint model with tests"
```

---

## 📋 ADIM 2: StrokeStyle Model

### Görev
```
GÖREV: StrokeStyle model oluştur

Dosya: packages/drawing_core/lib/src/models/stroke_style.dart

StrokeStyle immutable bir sınıf olacak:
- color: int (ARGB format, örn: 0xFF000000)
- thickness: double (0.1 - 50.0)
- opacity: double (0.0 - 1.0)
- nibShape: NibShape enum
- blendMode: DrawingBlendMode enum
- isEraser: bool (varsayılan false)

Enum tanımları (aynı dosyada):
- NibShape { circle, ellipse, rectangle }
- DrawingBlendMode { normal, multiply, screen, overlay, darken, lighten }

Factory constructors:
- StrokeStyle.pen() - siyah, 2.0 kalınlık, circle nib
- StrokeStyle.highlighter() - sarı, 20.0 kalınlık, rectangle nib, 0.5 opacity
- StrokeStyle.brush() - siyah, 5.0 kalınlık, ellipse nib
- StrokeStyle.eraser() - beyaz, 10.0 kalınlık, isEraser true

Test dosyası: test/models/stroke_style_test.dart
- Her factory test
- copyWith test
- JSON serialization test
- Color helper metotları test (getAlpha, getRed, getGreen, getBlue)

FLUTTER COLOR KULLANMA! int kullan.
```

### Tamamlama Checklist
```
□ stroke_style.dart oluşturuldu (enums dahil)
□ stroke_style_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add StrokeStyle model with enums and tests"
```

---

## 📋 ADIM 3: Stroke Model

### Görev
```
GÖREV: Stroke model oluştur

Dosya: packages/drawing_core/lib/src/models/stroke.dart

Stroke immutable bir sınıf olacak:
- id: String (UUID)
- points: List<DrawingPoint> (unmodifiable)
- style: StrokeStyle
- createdAt: DateTime
- bounds: Rect (hesaplanmış, lazy)

Metodlar:
- addPoint(DrawingPoint) → yeni Stroke döner
- addPoints(List<DrawingPoint>) → yeni Stroke döner
- getBounds() → {minX, minY, maxX, maxY} hesapla
- containsPoint(double x, double y, double radius) → bool (Phase 3 için stub)
- isEmpty → bool getter

Rect için custom class (Flutter Rect kullanma):
class BoundingBox {
  final double left, top, right, bottom;
  double get width => right - left;
  double get height => bottom - top;
}

Test dosyası: test/models/stroke_test.dart
- Empty stroke test
- Add point test
- Bounds calculation test
- containsPoint stub test
- JSON serialization test

ID için basit UUID: DateTime.now().microsecondsSinceEpoch.toString()
```

### Tamamlama Checklist
```
□ stroke.dart oluşturuldu
□ BoundingBox class oluşturuldu (aynı dosya veya ayrı)
□ stroke_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add Stroke model with bounds calculation"
```

---

## 📋 ADIM 4: Layer Model

### Görev
```
GÖREV: Layer model oluştur

Dosya: packages/drawing_core/lib/src/models/layer.dart

Layer immutable bir sınıf olacak:
- id: String
- name: String
- strokes: List<Stroke> (unmodifiable)
- isVisible: bool (varsayılan true)
- isLocked: bool (varsayılan false)
- opacity: double (0.0 - 1.0, varsayılan 1.0)

Metodlar:
- addStroke(Stroke) → yeni Layer döner
- removeStroke(String strokeId) → yeni Layer döner
- updateStroke(Stroke) → yeni Layer döner
- clear() → tüm stroke'ları sil
- findStrokesInRect(BoundingBox) → List<Stroke> (Phase 3 için stub)

Factory:
- Layer.empty(String name) - boş layer

Test dosyası: test/models/layer_test.dart
- Empty layer test
- Add/remove stroke test
- Visibility toggle test
- JSON serialization test
```

### Tamamlama Checklist
```
□ layer.dart oluşturuldu
□ layer_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add Layer model"
```

---

## 📋 ADIM 5: Document Model

### Görev
```
GÖREV: Document model oluştur

Dosya: packages/drawing_core/lib/src/models/document.dart

DrawingDocument immutable bir sınıf olacak:
- id: String
- title: String
- layers: List<Layer> (unmodifiable)
- activeLayerIndex: int
- createdAt: DateTime
- updatedAt: DateTime
- width: double (canvas genişlik)
- height: double (canvas yükseklik)

Getters:
- activeLayer → Layer?
- strokeCount → int (tüm layer'lardaki toplam)
- isEmpty → bool

Metodlar:
- addLayer(Layer) → yeni Document
- removeLayer(int index) → yeni Document
- updateLayer(int index, Layer) → yeni Document
- setActiveLayer(int index) → yeni Document
- addStrokeToActiveLayer(Stroke) → yeni Document

Factory:
- DrawingDocument.empty(String title, {double width, double height})
- DrawingDocument.withSingleLayer(String title)

Test dosyası: test/models/document_test.dart
- Empty document test
- Layer operations test
- Active layer test
- Stroke count test
- JSON serialization test
```

### Tamamlama Checklist
```
□ document.dart oluşturuldu
□ document_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add DrawingDocument model"
□ Push: git push origin feature/phase2-drawing-core
```

---

## 📋 ADIM 6: DrawingTool Abstract + PenTool

### Görev
```
GÖREV: DrawingTool abstract class ve PenTool oluştur

Dosya 1: packages/drawing_core/lib/src/tools/drawing_tool.dart

DrawingTool abstract class:
- currentStroke: Stroke? (protected)
- style: StrokeStyle (protected)
- isDrawing: bool getter

Abstract metodlar:
- void onPointerDown(DrawingPoint point)
- void onPointerMove(DrawingPoint point)  
- Stroke? onPointerUp() → tamamlanmış stroke döner veya null

Concrete metodlar:
- void updateStyle(StrokeStyle newStyle)
- void cancel() → çizimi iptal et

---

Dosya 2: packages/drawing_core/lib/src/tools/pen_tool.dart

PenTool extends DrawingTool:
- Varsayılan StrokeStyle.pen() kullanır
- onPointerDown: yeni stroke başlat
- onPointerMove: point ekle
- onPointerUp: stroke'u tamamla ve döndür

Test dosyası: test/tools/pen_tool_test.dart
- Tool başlatma test
- Stroke oluşturma flow test
- Style değiştirme test
- Cancel test
```

### Tamamlama Checklist
```
□ drawing_tool.dart oluşturuldu
□ pen_tool.dart oluşturuldu
□ pen_tool_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add DrawingTool abstract and PenTool"
```

---

## 📋 ADIM 7: HighlighterTool + BrushTool

### Görev
```
GÖREV: HighlighterTool ve BrushTool oluştur

Dosya 1: packages/drawing_core/lib/src/tools/highlighter_tool.dart

HighlighterTool extends DrawingTool:
- Varsayılan StrokeStyle.highlighter() kullanır
- Yarı saydam (opacity 0.5)
- Rectangle nib shape

---

Dosya 2: packages/drawing_core/lib/src/tools/brush_tool.dart

BrushTool extends DrawingTool:
- Varsayılan StrokeStyle.brush() kullanır
- Pressure-sensitive kalınlık değişimi (stub)
- Ellipse nib shape

Test dosyaları:
- test/tools/highlighter_tool_test.dart
- test/tools/brush_tool_test.dart
```

### Tamamlama Checklist
```
□ highlighter_tool.dart oluşturuldu
□ brush_tool.dart oluşturuldu
□ highlighter_tool_test.dart oluşturuldu
□ brush_tool_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add HighlighterTool and BrushTool"
```

---

## 📋 ADIM 8: Command Pattern

### Görev
```
GÖREV: DrawingCommand ve concrete command'lar oluştur

Dosya 1: packages/drawing_core/lib/src/history/drawing_command.dart

DrawingCommand abstract class:
- void execute(DrawingDocument document) → yeni document döner
- void undo(DrawingDocument document) → yeni document döner
- String get description

---

Dosya 2: packages/drawing_core/lib/src/history/add_stroke_command.dart

AddStrokeCommand implements DrawingCommand:
- layerIndex: int
- stroke: Stroke
- execute: layer'a stroke ekle
- undo: layer'dan stroke sil

---

Dosya 3: packages/drawing_core/lib/src/history/remove_stroke_command.dart

RemoveStrokeCommand implements DrawingCommand:
- layerIndex: int
- strokeId: String
- removedStroke: Stroke? (undo için cache)
- execute: layer'dan stroke sil
- undo: stroke'u geri ekle

Test dosyası: test/history/commands_test.dart
- AddStrokeCommand execute/undo test
- RemoveStrokeCommand execute/undo test
```

### Tamamlama Checklist
```
□ drawing_command.dart oluşturuldu
□ add_stroke_command.dart oluşturuldu
□ remove_stroke_command.dart oluşturuldu
□ commands_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add Command pattern for undo/redo"
```

---

## 📋 ADIM 9: HistoryManager

### Görev
```
GÖREV: HistoryManager oluştur

Dosya: packages/drawing_core/lib/src/history/history_manager.dart

HistoryManager class:
- _undoStack: List<DrawingCommand>
- _redoStack: List<DrawingCommand>
- maxHistorySize: int (varsayılan 100)

Getters:
- canUndo: bool
- canRedo: bool
- undoCount: int
- redoCount: int

Metodlar:
- DrawingDocument execute(DrawingCommand cmd, DrawingDocument doc)
  → command'ı çalıştır, undo stack'e ekle, redo stack'i temizle
- DrawingDocument? undo(DrawingDocument doc)
  → son command'ı geri al, redo stack'e taşı
- DrawingDocument? redo(DrawingDocument doc)
  → redo stack'ten al, tekrar çalıştır
- void clear() → her iki stack'i temizle

History limit aşıldığında en eski command silinir.

Test dosyası: test/history/history_manager_test.dart
- Execute test
- Undo test
- Redo test
- Max limit test
- Clear test
- canUndo/canRedo test
```

### Tamamlama Checklist
```
□ history_manager.dart oluşturuldu
□ history_manager_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Commit: "feat(core): add HistoryManager with undo/redo support"
□ Push: git push origin feature/phase2-drawing-core
```

---

## 📋 ADIM 10: PathSmoother + Export

### Görev
```
GÖREV: PathSmoother ve public API export

Dosya 1: packages/drawing_core/lib/src/input/path_smoother.dart

PathSmoother class:
- smoothPoints(List<DrawingPoint>, {double tension}) → List<DrawingPoint>
- Basit moving average veya Catmull-Rom interpolation
- Configurable smoothing level

---

Dosya 2: packages/drawing_core/lib/drawing_core.dart (PUBLIC API)

Sadece public API'ları export et:
export 'src/models/drawing_point.dart';
export 'src/models/stroke_style.dart';
export 'src/models/stroke.dart';
export 'src/models/layer.dart';
export 'src/models/document.dart';
export 'src/tools/drawing_tool.dart';
export 'src/tools/pen_tool.dart';
export 'src/tools/highlighter_tool.dart';
export 'src/tools/brush_tool.dart';
export 'src/history/drawing_command.dart';
export 'src/history/add_stroke_command.dart';
export 'src/history/remove_stroke_command.dart';
export 'src/history/history_manager.dart';
export 'src/input/path_smoother.dart';

Test dosyası: test/input/path_smoother_test.dart
```

### Tamamlama Checklist
```
□ path_smoother.dart oluşturuldu
□ drawing_core.dart exports güncellendi
□ path_smoother_test.dart oluşturuldu
□ flutter analyze hata yok
□ TÜM testler geçiyor
□ Commit: "feat(core): add PathSmoother and finalize public API"
□ Push: git push origin feature/phase2-drawing-core
```

---

## ✅ PHASE 2 FİNAL: Merge to Main

```
GÖREV: Phase 2'yi tamamla ve main'e merge et

1. Tüm testlerin geçtiğini doğrula:
   cd packages/drawing_core
   flutter test

2. Coverage raporu oluştur:
   flutter test --coverage

3. Son kontroller:
   flutter analyze
   dart format .

4. PR oluştur veya direkt merge:
   git checkout main
   git merge feature/phase2-drawing-core
   git push origin main

5. Tag oluştur:
   git tag -a v0.2.0-phase2 -m "Phase 2: Drawing Core complete"
   git push origin v0.2.0-phase2
```

---

## 📊 Phase 2 Tamamlanma Kriterleri

```
✅ Tüm 10 adım tamamlandı
✅ Tüm test dosyaları mevcut
✅ flutter analyze hata yok
✅ Tüm testler geçiyor
✅ Public API export edildi
✅ Main branch'e merge edildi
✅ Git tag oluşturuldu
```

---

*Phase 2 tahmini süre: 2-3 gün*

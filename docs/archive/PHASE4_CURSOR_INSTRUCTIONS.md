# Phase 4: Cursor Görev Talimatları

> **ÖNEMLİ**: Bu dökümanı sırayla takip et. Bir adımı bitirmeden diğerine GEÇME.
> Her adımda spesifikasyon dökümanlarına başvur!

---

## 📚 Referans Dökümanlar (HER ADIMDA KONTROL ET!)

| Döküman | İçerik |
|---------|--------|
| `PHASE4_MASTER_PLAN.md` | Genel plan ve mimari |
| `PHASE4_ERASER_SPEC.md` | Eraser detaylı implementasyon |
| `PHASE4_SELECTION_SPEC.md` | Selection detaylı implementasyon |
| `PHASE4_SHAPES_SPEC.md` | Shapes detaylı implementasyon |

---

## 🔢 Phase 4 Modül Sırası

```
Phase 4A: Eraser System     (Adım 1-7)   ← İLK
Phase 4B: Selection System  (Adım 8-16)
Phase 4C: Shape Tools       (Adım 17-24)
Phase 4D: Text Tool         (Opsiyonel)
```

---

# PHASE 4A: ERASER SYSTEM

## ADIM 4A-1: Hit Testing Altyapısı

```
GÖREV: Hit testing altyapısını oluştur (drawing_core)

📖 Referans: PHASE4_ERASER_SPEC.md - "Hit Testing Algoritması" bölümü

## Dosyalar

### 1. HitTester Abstract Class
Dosya: packages/drawing_core/lib/src/hit_testing/hit_tester.dart

```dart
import 'dart:math';

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

### 2. Klasör oluştur
packages/drawing_core/lib/src/hit_testing/

### 3. Barrel export oluştur
Dosya: packages/drawing_core/lib/src/hit_testing/hit_testing.dart

```dart
export 'hit_tester.dart';
```

## Test
packages/drawing_core/test/hit_testing/hit_tester_test.dart

## Kontrol
- [ ] hit_testing klasörü oluşturuldu
- [ ] hit_tester.dart oluşturuldu
- [ ] hit_testing.dart barrel oluşturuldu
- [ ] flutter analyze geçiyor

📝 Commit: feat(core): add hit testing infrastructure
```

---

## ADIM 4A-2: StrokeHitTester Implementasyonu

```
GÖREV: StrokeHitTester'ı implement et

📖 Referans: PHASE4_ERASER_SPEC.md - "StrokeHitTester" bölümü

## Dosya
packages/drawing_core/lib/src/hit_testing/stroke_hit_tester.dart

## Implementasyon (SPEC'ten kopyala ve adapte et)

Önemli metodlar:
- hitTest() - tek stroke kontrolü
- findElementsAt() - tüm eşleşen stroke'lar
- findTopElementAt() - en üstteki stroke
- _boundsCheck() - hızlı bounding box eleme
- _segmentCheck() - detaylı segment kontrolü
- _pointToSegmentDistance() - matematiksel mesafe

## Matematiksel Fonksiyonlar
- Point-to-line segment distance (SPEC'te formül var)
- Bounding box intersection

## Test Dosyası
packages/drawing_core/test/hit_testing/stroke_hit_tester_test.dart

Test senaryoları:
- Düz çizgi üzerinde hit
- Eğri çizgi üzerinde hit
- Tolerance dışında miss
- Stroke kalınlığı hesaba katılıyor
- Tek noktalı stroke
- Boş stroke
- Bounding box pre-filter çalışıyor
- findTopElementAt son çizileni döndürüyor

## Kontrol
- [ ] stroke_hit_tester.dart oluşturuldu
- [ ] hit_testing.dart barrel güncellendi
- [ ] Tüm testler geçiyor
- [ ] flutter analyze geçiyor

📝 Commit: feat(core): implement StrokeHitTester with segment distance
```

---

## ADIM 4A-3: EraserTool (Stroke Mode)

```
GÖREV: EraserTool'u implement et (önce stroke mode)

📖 Referans: PHASE4_ERASER_SPEC.md - "EraserTool" bölümü

## Dosya
packages/drawing_core/lib/src/tools/eraser_tool.dart

## Implementasyon

```dart
enum EraserMode {
  pixel,   // Nokta bazlı (Phase 4+ için)
  stroke,  // Tüm çizgiyi sil
}

class EraserTool extends DrawingTool {
  final EraserMode mode;
  final double eraserSize;
  final StrokeHitTester _hitTester;
  final Set<String> _erasedStrokeIds = {};
  
  // SPEC'teki implementasyonu kullan
}
```

## Metodlar
- findStrokesToErase() - silinecek stroke'ları bul
- startErasing() - silme session başlat
- markAsErased() - stroke'u işaretle
- isAlreadyErased() - tekrar silme engelle
- endErasing() - session bitir, ID'leri döndür

## Test Dosyası
packages/drawing_core/test/tools/eraser_tool_test.dart

## Barrel Export Güncelle
packages/drawing_core/lib/src/tools/tools.dart

## Kontrol
- [ ] eraser_tool.dart oluşturuldu
- [ ] tools.dart barrel güncellendi
- [ ] Tüm testler geçiyor

📝 Commit: feat(core): implement EraserTool with stroke mode
```

---

## ADIM 4A-4: EraseStrokesCommand

```
GÖREV: Eraser için undo/redo command oluştur

📖 Referans: PHASE4_ERASER_SPEC.md - "Eraser Commands" bölümü

## Dosya
packages/drawing_core/lib/src/history/erase_strokes_command.dart

## Implementasyon
- execute() - stroke'ları sil, cache'le (undo için)
- undo() - silinen stroke'ları geri ekle
- description - "Erase X stroke(s)"

## Test Dosyası
packages/drawing_core/test/history/erase_strokes_command_test.dart

Test senaryoları:
- Tek stroke silme
- Çoklu stroke silme
- Undo silinen stroke'ları geri getiriyor
- Redo tekrar siliyor

## Barrel Export Güncelle
packages/drawing_core/lib/src/history/history.dart

## drawing_core.dart Ana Export Güncelle
Yeni dosyaları export et.

## Kontrol
- [ ] erase_strokes_command.dart oluşturuldu
- [ ] history.dart barrel güncellendi
- [ ] drawing_core.dart güncellendi
- [ ] Tüm testler geçiyor

📝 Commit: feat(core): add EraseStrokesCommand for undo/redo support
```

---

## ADIM 4A-5: Eraser Provider (drawing_ui)

```
GÖREV: Eraser provider'larını oluştur

## Dosya
packages/drawing_ui/lib/src/providers/eraser_provider.dart

## Implementasyon

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Eraser mode state
final eraserModeProvider = StateProvider<EraserMode>((ref) => EraserMode.stroke);

/// Eraser size state
final eraserSizeProvider = StateProvider<double>((ref) => 20.0);

/// Aktif eraser tool instance
final eraserToolProvider = Provider<EraserTool>((ref) {
  final mode = ref.watch(eraserModeProvider);
  final size = ref.watch(eraserSizeProvider);
  
  return EraserTool(mode: mode, eraserSize: size);
});

/// Eraser aktif mi?
final isEraserActiveProvider = Provider<bool>((ref) {
  final tool = ref.watch(currentToolProvider);
  return tool == ToolType.eraser;
});
```

## Barrel Export Güncelle
packages/drawing_ui/lib/src/providers/providers.dart

## Test Dosyası
packages/drawing_ui/test/providers/eraser_provider_test.dart

## Kontrol
- [ ] eraser_provider.dart oluşturuldu
- [ ] providers.dart barrel güncellendi
- [ ] Testler geçiyor

📝 Commit: feat(ui): add eraser providers
```

---

## ADIM 4A-6: DrawingCanvas Eraser Entegrasyonu

```
GÖREV: DrawingCanvas'a eraser desteği ekle

## Dosya
packages/drawing_ui/lib/src/canvas/drawing_canvas.dart (GÜNCELLE)

## Değişiklikler

### 1. Pointer handler'ları güncelle

```dart
void _handlePointerDown(PointerDownEvent event) {
  final toolType = ref.read(currentToolProvider);
  
  if (toolType == ToolType.eraser) {
    _handleEraserDown(event);
  } else if (ref.read(isDrawingToolProvider)) {
    _handleDrawingDown(event);
  }
}

void _handlePointerMove(PointerMoveEvent event) {
  final toolType = ref.read(currentToolProvider);
  
  if (toolType == ToolType.eraser) {
    _handleEraserMove(event);
  } else if (_drawingController.isDrawing) {
    _handleDrawingMove(event);
  }
}

void _handlePointerUp(PointerUpEvent event) {
  final toolType = ref.read(currentToolProvider);
  
  if (toolType == ToolType.eraser) {
    _handleEraserUp(event);
  } else {
    _handleDrawingUp(event);
  }
}
```

### 2. Eraser handler'ları ekle

```dart
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

### 3. isDrawingToolProvider güncelle
tool_style_provider.dart'ta eraser'ı drawing tool'lardan ÇIKAR:

```dart
final isDrawingToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  return [
    ToolType.pen,
    ToolType.highlighter,
    ToolType.brush,
    // ToolType.eraser ÇIKARILDI - ayrı handle ediliyor
  ].contains(toolType);
});
```

## Test Dosyası Güncelle
packages/drawing_ui/test/canvas/drawing_canvas_test.dart

Yeni testler:
- Eraser tool seçiliyken silme çalışıyor
- Silinen stroke document'tan kaldırılıyor
- Undo silinen stroke'u geri getiriyor

## Kontrol
- [ ] drawing_canvas.dart güncellendi
- [ ] tool_style_provider.dart güncellendi
- [ ] Testler geçiyor

📝 Commit: feat(ui): integrate eraser into DrawingCanvas
```

---

## ADIM 4A-7: Eraser Manuel Test ve Polish

```
GÖREV: Eraser'ı test et ve gerekirse düzelt

## Manuel Test

```bash
cd example_app
flutter run
```

### Test Senaryoları
1. Bir kaç çizgi çiz
2. Silgi tool'u seç
3. Bir çizgiye dokun → Çizgi siliniyor mu?
4. Undo → Çizgi geri geliyor mu?
5. Redo → Çizgi tekrar siliniyor mu?
6. Hızlı sürükleyerek çoklu silme → Çalışıyor mu?

### Olası Sorunlar ve Çözümler
- Hit test çalışmıyor → tolerance değerini kontrol et
- Çizgi silinmiyor → erasedIds command'a gidiyor mu?
- Undo çalışmıyor → command doğru implement edilmiş mi?

## Eraser Cursor (Opsiyonel)

Silgi pozisyonunu gösteren daire eklenebilir.
packages/drawing_ui/lib/src/canvas/eraser_cursor_painter.dart

## Final Kontrol
- [ ] Silgi çalışıyor
- [ ] Undo/redo çalışıyor
- [ ] Performans OK (kasma yok)
- [ ] Tüm testler geçiyor

📝 Commit: feat(ui): complete eraser system

🏷️ PHASE 4A TAMAMLANDI - Commit ve tag oluştur:
git tag -a v0.4.0-phase4a -m "Phase 4A: Eraser System complete"
```

---

# PHASE 4B: SELECTION SYSTEM

## ADIM 4B-1: Selection Model

```
GÖREV: Selection model'i oluştur (drawing_core)

📖 Referans: PHASE4_SELECTION_SPEC.md - "Selection Model" bölümü

## Dosya
packages/drawing_core/lib/src/models/selection.dart

## Implementasyon
- SelectionType enum (lasso, rectangle)
- Selection class (SPEC'teki gibi)
- SelectionHandle enum ve extension

## Test Dosyası
packages/drawing_core/test/models/selection_test.dart

## Barrel Export Güncelle
packages/drawing_core/lib/src/models/models.dart

📝 Commit: feat(core): add Selection model
```

---

## ADIM 4B-2: SelectionTool Abstract

```
GÖREV: SelectionTool abstract class oluştur

📖 Referans: PHASE4_SELECTION_SPEC.md - "SelectionTool Abstract" bölümü

## Dosya
packages/drawing_core/lib/src/tools/selection_tool.dart

## Interface
- startSelection()
- updateSelection()
- endSelection()
- cancelSelection()
- isSelecting
- currentPath

📝 Commit: feat(core): add SelectionTool abstract class
```

---

## ADIM 4B-3: LassoSelectionTool

```
GÖREV: Lasso selection tool implement et

📖 Referans: PHASE4_SELECTION_SPEC.md - "LassoSelectionTool" bölümü

## Dosya
packages/drawing_core/lib/src/tools/lasso_selection_tool.dart

## Kritik Algoritma
- Point-in-polygon (ray casting) - SPEC'te kod var
- Path kapatma
- Bounds hesaplama

## Test Dosyası
packages/drawing_core/test/tools/lasso_selection_tool_test.dart

📝 Commit: feat(core): implement LassoSelectionTool
```

---

## ADIM 4B-4: RectSelectionTool

```
GÖREV: Rectangle selection tool implement et

📖 Referans: PHASE4_SELECTION_SPEC.md - "RectSelectionTool" bölümü

## Dosya
packages/drawing_core/lib/src/tools/rect_selection_tool.dart

## Kritik
- Start/end point'ten rectangle bounds
- Bounds intersection kontrolü
- Inverted rectangle handling (sağdan sola çizim)

📝 Commit: feat(core): implement RectSelectionTool
```

---

## ADIM 4B-5: Selection Commands

```
GÖREV: Selection için command'ları oluştur

📖 Referans: PHASE4_SELECTION_SPEC.md - "Selection Commands" bölümü

## Dosyalar
1. packages/drawing_core/lib/src/history/move_selection_command.dart
2. packages/drawing_core/lib/src/history/delete_selection_command.dart

## MoveSelectionCommand
- Tüm seçili stroke'ların noktalarını deltaX, deltaY kadar taşı
- Undo: ters yönde taşı

## DeleteSelectionCommand
- Seçili stroke'ları sil
- Undo: geri ekle

📝 Commit: feat(core): add selection commands
```

---

## ADIM 4B-6: SelectionProvider

```
GÖREV: Selection provider oluştur (drawing_ui)

📖 Referans: PHASE4_SELECTION_SPEC.md - "Selection Provider" bölümü

## Dosya
packages/drawing_ui/lib/src/providers/selection_provider.dart

## Providers
- selectionProvider - StateNotifier
- hasSelectionProvider - bool
- selectionCountProvider - int

📝 Commit: feat(ui): add SelectionProvider
```

---

## ADIM 4B-7: SelectionPainter

```
GÖREV: Selection görselleştirme painter'ı oluştur

📖 Referans: PHASE4_SELECTION_SPEC.md - "Selection Painter" bölümü

## Dosya
packages/drawing_ui/lib/src/canvas/selection_painter.dart

## Özellikler
- Bounds rectangle (mavi kesikli çizgi)
- 8 handle (köşeler + kenarlar)
- Lasso path (yarı saydam dolgu)

📝 Commit: feat(ui): add SelectionPainter
```

---

## ADIM 4B-8: Selection Handles Widget

```
GÖREV: Selection handles interaction widget'ı oluştur

📖 Referans: PHASE4_SELECTION_SPEC.md - "Selection Handles Widget" bölümü

## Dosya
packages/drawing_ui/lib/src/widgets/selection_handles.dart

## Özellikler
- Handle hit testing
- Drag to move
- Commit move (command execute)

📝 Commit: feat(ui): add SelectionHandles widget
```

---

## ADIM 4B-9: DrawingCanvas Selection Entegrasyonu

```
GÖREV: DrawingCanvas'a selection desteği ekle

## Değişiklikler
1. Selection tool handler'ları
2. Selection layer (RepaintBoundary)
3. Selection state yönetimi
4. Keyboard shortcuts (Delete key)

## Render Layer Ekleme
Stack'e yeni layer ekle:
```dart
// LAYER 5: Selection Overlay
RepaintBoundary(
  child: Consumer(
    builder: (context, ref, _) {
      final selection = ref.watch(selectionProvider);
      return CustomPaint(
        painter: SelectionPainter(
          selection: selection,
          zoom: ref.watch(zoomLevelProvider),
        ),
      );
    },
  ),
),
```

📝 Commit: feat(ui): integrate selection into DrawingCanvas

🏷️ PHASE 4B TAMAMLANDI - Tag oluştur:
git tag -a v0.4.0-phase4b -m "Phase 4B: Selection System complete"
```

---

# PHASE 4C: SHAPE TOOLS

## ADIM 4C-1: Shape Model

```
GÖREV: Shape model oluştur

📖 Referans: PHASE4_SHAPES_SPEC.md - "Shape Model" bölümü

## Dosyalar
1. packages/drawing_core/lib/src/models/shape_type.dart
2. packages/drawing_core/lib/src/models/shape.dart

## Shape Class Özellikleri
- id, type, startPoint, endPoint, style, isFilled
- bounds hesaplama
- containsPoint() hit testing (her shape tipi için)
- copyWith(), toJson(), fromJson()

📝 Commit: feat(core): add Shape model
```

---

## ADIM 4C-2: Layer Model Güncelleme

```
GÖREV: Layer model'e shapes listesi ekle

## Dosya
packages/drawing_core/lib/src/models/layer.dart (GÜNCELLE)

## Değişiklikler
```dart
class Layer {
  final String id;
  final String name;
  final List<Stroke> strokes;
  final List<Shape> shapes;  // YENİ
  final bool isVisible;
  final bool isLocked;
  
  // Yeni metodlar:
  Layer addShape(Shape shape);
  Layer removeShape(String shapeId);
  Layer updateShape(Shape shape);
}
```

⚠️ DİKKAT: Mevcut testlerin kırılmadığından emin ol!

📝 Commit: feat(core): add shapes support to Layer model
```

---

## ADIM 4C-3: ShapeTool Abstract ve Concrete Tools

```
GÖREV: Shape tool'larını implement et

📖 Referans: PHASE4_SHAPES_SPEC.md - "Shape Tools" bölümü

## Dosyalar
1. packages/drawing_core/lib/src/tools/shape_tool.dart (abstract)
2. packages/drawing_core/lib/src/tools/line_tool.dart
3. packages/drawing_core/lib/src/tools/rectangle_tool.dart
4. packages/drawing_core/lib/src/tools/ellipse_tool.dart
5. packages/drawing_core/lib/src/tools/arrow_tool.dart

## ShapeTool Abstract
- startShape(), updateShape(), endShape(), cancelShape()
- previewShape getter

📝 Commit: feat(core): implement shape tools
```

---

## ADIM 4C-4: Shape Commands

```
GÖREV: Shape için command'lar oluştur

## Dosyalar
1. packages/drawing_core/lib/src/history/add_shape_command.dart
2. packages/drawing_core/lib/src/history/remove_shape_command.dart

📝 Commit: feat(core): add shape commands
```

---

## ADIM 4C-5: ShapePainter

```
GÖREV: Shape rendering painter'ı oluştur

📖 Referans: PHASE4_SHAPES_SPEC.md - "ShapePainter" bölümü

## Dosya
packages/drawing_ui/lib/src/canvas/shape_painter.dart

## Render Metodları
- _drawLine()
- _drawRectangle()
- _drawEllipse()
- _drawArrow() (ok başı ile)

📝 Commit: feat(ui): add ShapePainter
```

---

## ADIM 4C-6: Shape Provider ve Tool Integration

```
GÖREV: Shape tool entegrasyonu

## Provider Dosyası
packages/drawing_ui/lib/src/providers/shape_provider.dart

## DrawingCanvas Entegrasyonu
- Shape tool handler'ları
- Active shape preview layer
- Shape commit (AddShapeCommand)

📝 Commit: feat(ui): integrate shape tools into DrawingCanvas

🏷️ PHASE 4C TAMAMLANDI - Tag oluştur:
git tag -a v0.4.0-phase4c -m "Phase 4C: Shape Tools complete"
```

---

# FINAL: Phase 4 Tamamlama

## ADIM FINAL: Merge ve Tag

```
GÖREV: Phase 4'ü tamamla

## Tüm Testleri Çalıştır
```bash
cd packages/drawing_core && flutter test
cd packages/drawing_ui && flutter test
flutter analyze
```

## Main Branch'e Merge
```bash
git checkout main
git merge feature/phase4-advanced-features
git push origin main
```

## Final Tag
```bash
git tag -a v0.4.0-phase4 -m "Phase 4: Advanced Features complete

Features:
- Eraser (stroke mode)
- Lasso Selection
- Rectangle Selection
- Selection Move/Delete
- Line Tool
- Rectangle Tool
- Ellipse Tool
- Arrow Tool
- Full undo/redo support"

git push origin v0.4.0-phase4
```

🎉 PHASE 4 TAMAMLANDI!
```

---

## 📊 İlerleme Takibi

### Phase 4A: Eraser
| Adım | Durum |
|------|-------|
| 4A-1 | ❌ |
| 4A-2 | ❌ |
| 4A-3 | ❌ |
| 4A-4 | ❌ |
| 4A-5 | ❌ |
| 4A-6 | ❌ |
| 4A-7 | ❌ |

### Phase 4B: Selection
| Adım | Durum |
|------|-------|
| 4B-1 | ❌ |
| 4B-2 | ❌ |
| 4B-3 | ❌ |
| 4B-4 | ❌ |
| 4B-5 | ❌ |
| 4B-6 | ❌ |
| 4B-7 | ❌ |
| 4B-8 | ❌ |
| 4B-9 | ❌ |

### Phase 4C: Shapes
| Adım | Durum |
|------|-------|
| 4C-1 | ❌ |
| 4C-2 | ❌ |
| 4C-3 | ❌ |
| 4C-4 | ❌ |
| 4C-5 | ❌ |
| 4C-6 | ❌ |

---

*Document Version: 1.0*
*Created: 2025-01-13*

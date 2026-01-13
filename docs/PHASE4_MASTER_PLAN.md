# Phase 4: Advanced Features - Master Plan

> **Status**: NOT STARTED  
> **Branch**: `feature/phase4-advanced-features`  
> **Package**: `packages/drawing_core` + `packages/drawing_ui`  
> **Depends on**: Phase 3 ✅

---

## 🎯 Phase 4 Amacı

Çizim uygulamasına gelişmiş özellikler eklemek: Silgi, Seçim, Şekiller ve Metin.

**Sonuç:** Kullanıcı silgi ile çizgileri silebilecek, seçim yapabilecek, şekil çizebilecek ve metin ekleyebilecek.

---

## 📊 Phase 4 Kapsamı

```
Phase 4: Advanced Features
├── 4A: Eraser System (~4-6 saat)
│   ├── Pixel Eraser (nokta silme)
│   ├── Stroke Eraser (tüm çizgi silme)
│   └── Eraser Tool Integration
│
├── 4B: Selection System (~6-8 saat)
│   ├── Selection Model
│   ├── Lasso Selection Tool
│   ├── Rectangle Selection Tool
│   ├── Selection Rendering
│   └── Selection Actions (move, delete, copy)
│
├── 4C: Shape Tools (~4-6 saat)
│   ├── Shape Model
│   ├── Line Tool
│   ├── Rectangle Tool
│   ├── Ellipse Tool
│   ├── Arrow Tool
│   └── Shape Rendering
│
└── 4D: Text Tool (~4-6 saat) [OPSIYONEL]
    ├── Text Element Model
    ├── Text Input Handler
    └── Text Rendering
```

**Tahmini Toplam Süre:** 18-26 saat (4D opsiyonel)

---

## 🏗️ Mimari Genel Bakış

### Layer Yapısı (Güncellenmiş)

```
DrawingDocument
├── layers: List<Layer>
│   └── Layer
│       ├── strokes: List<Stroke>      ← Mevcut
│       ├── shapes: List<Shape>        ← YENİ (Phase 4C)
│       └── textElements: List<Text>   ← YENİ (Phase 4D)
│
├── selection: Selection?              ← YENİ (Phase 4B)
└── activeElement: Element?            ← YENİ (seçili element)
```

### Rendering Katmanları (Güncellenmiş)

```
┌─────────────────────────────────────────┐
│ Layer 5: Selection Overlay              │ ← YENİ
├─────────────────────────────────────────┤
│ Layer 4: Active Element (shape/text)    │ ← YENİ
├─────────────────────────────────────────┤
│ Layer 3: Active Stroke                  │ ← Mevcut
├─────────────────────────────────────────┤
│ Layer 2: Committed Elements             │ ← Genişletildi
│          (strokes + shapes + text)      │
├─────────────────────────────────────────┤
│ Layer 1: Background/Grid                │ ← Mevcut
└─────────────────────────────────────────┘
```

---

## 📁 Yeni Dosya Yapısı

### drawing_core (Yeni Eklemeler)

```
packages/drawing_core/lib/src/
├── models/
│   ├── ... (mevcut)
│   ├── shape.dart                 ← YENİ
│   ├── shape_type.dart            ← YENİ
│   ├── text_element.dart          ← YENİ
│   ├── selection.dart             ← YENİ
│   └── element.dart               ← YENİ (abstract base)
│
├── tools/
│   ├── ... (mevcut)
│   ├── eraser_tool.dart           ← YENİ
│   ├── lasso_selection_tool.dart  ← YENİ
│   ├── rect_selection_tool.dart   ← YENİ
│   ├── line_tool.dart             ← YENİ
│   ├── rectangle_tool.dart        ← YENİ
│   ├── ellipse_tool.dart          ← YENİ
│   ├── arrow_tool.dart            ← YENİ
│   └── text_tool.dart             ← YENİ
│
├── history/
│   ├── ... (mevcut)
│   ├── add_shape_command.dart     ← YENİ
│   ├── remove_shape_command.dart  ← YENİ
│   ├── move_elements_command.dart ← YENİ
│   └── add_text_command.dart      ← YENİ
│
└── hit_testing/                   ← YENİ KLASÖR
    ├── hit_tester.dart            ← YENİ
    ├── stroke_hit_tester.dart     ← YENİ
    └── shape_hit_tester.dart      ← YENİ
```

### drawing_ui (Yeni Eklemeler)

```
packages/drawing_ui/lib/src/
├── canvas/
│   ├── ... (mevcut)
│   ├── shape_painter.dart         ← YENİ
│   ├── selection_painter.dart     ← YENİ
│   └── text_painter.dart          ← YENİ
│
├── providers/
│   ├── ... (mevcut)
│   ├── selection_provider.dart    ← YENİ
│   └── shape_provider.dart        ← YENİ
│
└── widgets/
    ├── ... (mevcut)
    ├── selection_handles.dart     ← YENİ
    └── text_input_overlay.dart    ← YENİ
```

---

## 🔢 Geliştirme Sırası

### Phase 4A: Eraser System (7 Adım)
```
4A-1: Hit Testing altyapısı (drawing_core)
4A-2: StrokeHitTester implementasyonu
4A-3: EraserTool (pixel mode)
4A-4: EraserTool (stroke mode)
4A-5: Eraser UI entegrasyonu
4A-6: RemoveStrokeCommand entegrasyonu
4A-7: Test ve doğrulama
```

### Phase 4B: Selection System (9 Adım)
```
4B-1: Selection model (drawing_core)
4B-2: SelectionTool abstract class
4B-3: LassoSelectionTool
4B-4: RectSelectionTool
4B-5: SelectionProvider (drawing_ui)
4B-6: SelectionPainter (handles, bounds)
4B-7: Selection actions (move, delete)
4B-8: Selection commands (undo/redo)
4B-9: Test ve doğrulama
```

### Phase 4C: Shape Tools (8 Adım)
```
4C-1: Shape model (drawing_core)
4C-2: ShapeTool abstract class
4C-3: LineTool
4C-4: RectangleTool
4C-5: EllipseTool
4C-6: ArrowTool
4C-7: ShapePainter (drawing_ui)
4C-8: Shape commands ve test
```

### Phase 4D: Text Tool (6 Adım) [OPSİYONEL]
```
4D-1: TextElement model
4D-2: TextTool
4D-3: TextInputOverlay widget
4D-4: TextPainter
4D-5: Text commands
4D-6: Test ve doğrulama
```

---

## ⚡ Performans Gereksinimleri

### Hit Testing
```
Hedef: <5ms per hit test
Strateji:
├── Bounding box pre-filter
├── Spatial indexing (büyük dokümanlar için)
└── Early exit optimizasyonu
```

### Selection Rendering
```
Hedef: 60 FPS selection handles
Strateji:
├── Ayrı RepaintBoundary
├── Transform-aware handles
└── Lazy bounds calculation
```

### Shape Rendering
```
Hedef: <1ms per shape
Strateji:
├── Path caching
├── Paint object reuse
└── Clip rect optimization
```

---

## 🎨 Kalite Gereksinimleri

### Eraser
- Pixel eraser: hassas silme (nokta bazlı)
- Stroke eraser: tüm çizgiyi tek dokunuşla sil
- Visual feedback: silme alanı göstergesi

### Selection
- Smooth handles: 8 nokta (köşeler + kenarlar)
- Multi-select: birden fazla element seçimi
- Visual feedback: seçim sınırları ve highlight

### Shapes
- Perfect geometry: düzgün çizgiler ve şekiller
- Shift-constraint: 45° açı ve kare/daire zorlama (gelecek)
- Anti-aliased rendering

---

## 🔗 drawing_core Değişiklikleri

### Mevcut Sınıflarda Değişiklik
```dart
// Layer model güncelleme
class Layer {
  final List<Stroke> strokes;
  final List<Shape> shapes;      // YENİ
  final List<TextElement> texts; // YENİ (4D)
}

// DrawingDocument güncelleme
class DrawingDocument {
  // ... mevcut
  final Selection? selection;    // YENİ
}

// Stroke model güncelleme (hit testing için)
class Stroke {
  // ... mevcut
  bool containsPoint(double x, double y, double tolerance);  // Implement et
}
```

### Yeni Abstract Class
```dart
/// Tüm çizilebilir elementler için base class
abstract class DrawableElement {
  String get id;
  BoundingBox get bounds;
  bool containsPoint(double x, double y, double tolerance);
  DrawableElement copyWith();
  Map<String, dynamic> toJson();
}
```

---

## 🧪 Test Gereksinimleri

### Her Modül İçin
```
- Unit tests: Model ve logic testleri
- Widget tests: UI component testleri
- Integration tests: End-to-end flow testleri
- Performance tests: Hit testing ve rendering benchmark
```

### Test Coverage Hedefi
```
Phase 4A (Eraser): >90%
Phase 4B (Selection): >85%
Phase 4C (Shapes): >90%
Phase 4D (Text): >80%
```

---

## ⚠️ Riskler ve Çözümler

| Risk | Etki | Çözüm |
|------|------|-------|
| Hit testing yavaş | UX bozulur | Spatial indexing, bounding box filter |
| Selection handles karmaşık | Kod karmaşası | Ayrı widget, clean abstraction |
| Shape/Stroke uyumsuzluğu | Render hataları | Common DrawableElement base |
| Text input platform farklılıkları | Bug | Flutter TextField kullan |

---

## 📅 Öncelik Sırası

```
🔴 KRİTİK (İlk yapılacak):
├── 4A: Eraser System (temel özellik)
└── 4B: Selection System (temel özellik)

🟡 YÜKSEK (Sonra yapılacak):
└── 4C: Shape Tools (beklenen özellik)

🟢 DÜŞÜK (Opsiyonel):
└── 4D: Text Tool (nice-to-have)
```

---

## 📚 Referans Dökümanlar

- `docs/PHASE4_CURSOR_INSTRUCTIONS.md` - Adım adım görevler
- `docs/PHASE4_ERASER_SPEC.md` - Eraser detaylı spesifikasyon
- `docs/PHASE4_SELECTION_SPEC.md` - Selection detaylı spesifikasyon
- `docs/PHASE4_SHAPES_SPEC.md` - Shapes detaylı spesifikasyon
- `docs/ARCHITECTURE.md` - Package boundaries
- `docs/PERFORMANCE_STRATEGY.md` - Performance rules

---

## ✅ Başarı Kriterleri

Phase 4 TAMAMLANDI sayılması için:

```
Phase 4A (Eraser):
✅ Pixel eraser çalışıyor
✅ Stroke eraser çalışıyor
✅ Undo/redo ile entegre

Phase 4B (Selection):
✅ Lasso selection çalışıyor
✅ Rectangle selection çalışıyor
✅ Move/delete actions çalışıyor
✅ Undo/redo ile entegre

Phase 4C (Shapes):
✅ Line tool çalışıyor
✅ Rectangle tool çalışıyor
✅ Ellipse tool çalışıyor
✅ Arrow tool çalışıyor
✅ Undo/redo ile entegre

Phase 4D (Text) [Opsiyonel]:
✅ Text ekleme çalışıyor
✅ Text düzenleme çalışıyor

Genel:
✅ Tüm testler geçiyor
✅ 60 FPS performans
✅ Main branch'e merge
```

---

*Document Version: 1.0*  
*Created: 2025-01-13*  
*Phase 4 Progress: 0%*

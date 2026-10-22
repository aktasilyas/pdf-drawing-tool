# Elyanotes Drawing Library - Project Context

> **Tek dosya bağlam referansı** - Claude Project için optimize edildi
> Son güncelleme: 2025-01-15

---

## 🎯 Proje Özeti

**Amaç:** Flutter drawing/annotation kütüphanesi (pub.dev için)  
**Referans:** Elyanotes, GoodNotes, Notability, Samsung Notes, OneNote

---

## 📊 Mevcut Durum

| Phase | Durum | İçerik |
|-------|-------|--------|
| Phase 0-3 | ✅ COMPLETE | Scaffolding, UI, Drawing Core, Canvas |
| Phase 4A | ✅ COMPLETE | Eraser System |
| Phase 4B | ✅ COMPLETE | Selection System (lasso + rect) |
| Phase 4C | ✅ COMPLETE | Shape Tools (10 tip) |
| Phase 4D | ✅ COMPLETE | Text Tool |
| **Phase 4E** | 🔄 ACTIVE | Enhancement & Cleanup |
| Phase 5 | ❌ PENDING | Multi-Page & PDF |

**Test Coverage:** ~270+ test  
**Performans:** 60 FPS, <5ms hit test ✅

---

## 🏗️ Mimari

### Paket Yapısı
```
packages/
├── drawing_core/    # Pure Dart - modeller, araçlar, history
├── drawing_ui/      # Flutter - widget'lar, painter'lar
└── drawing_toolkit/ # Umbrella - pub.dev public API
```

### Bağımlılık Yönü
```
example_app → drawing_toolkit → drawing_ui → drawing_core
```

### Barrel Export Pattern (ZORUNLU)
```dart
// ✅ DOĞRU
import 'package:drawing_core/drawing_core.dart';

// ❌ YASAK - relative import
import '../models/stroke.dart';
```

---

## 📁 Mevcut Dosya Yapısı

### drawing_core
```
lib/src/
├── models/
│   ├── drawing_point.dart
│   ├── stroke.dart, stroke_style.dart
│   ├── layer.dart, drawing_document.dart
│   ├── bounding_box.dart
│   ├── selection.dart
│   ├── shape.dart, shape_type.dart (10 tip)
│   └── text_element.dart
├── tools/
│   ├── drawing_tool.dart (abstract)
│   ├── pen_tool.dart, highlighter_tool.dart, brush_tool.dart
│   ├── eraser_tool.dart
│   ├── selection tools (lasso, rect)
│   ├── shape tools (line, rect, ellipse, arrow, generic)
│   └── text_tool.dart
├── history/
│   ├── command.dart, history_manager.dart
│   ├── add_stroke_command.dart
│   ├── erase_strokes_command.dart
│   ├── selection commands (move, delete)
│   ├── shape commands (add, remove)
│   └── text commands (add, remove, update)
├── hit_testing/
│   └── stroke_hit_tester.dart
└── utils/
    └── path_smoother.dart
```

### drawing_ui
```
lib/src/
├── canvas/
│   ├── drawing_canvas.dart
│   ├── committed_strokes_painter.dart
│   ├── active_stroke_painter.dart
│   ├── selection_painter.dart
│   ├── shape_painter.dart
│   └── text_painter.dart
├── providers/
│   ├── document_provider.dart
│   ├── tool_provider.dart
│   ├── history_provider.dart
│   ├── selection_provider.dart
│   └── shape_provider.dart
├── widgets/
│   ├── selection_handles.dart
│   ├── text_input_overlay.dart
│   ├── text_context_menu.dart
│   └── text_style_popup.dart
└── panels/
    ├── toolbar (two-row)
    ├── pen_box (floating)
    └── settings panels
```

---

## ⚡ Performans Kuralları

### Rendering
1. **İki katmanlı rendering:** committed (static) vs active (dynamic)
2. **setState KULLANMA** - ChangeNotifier/Provider kullan
3. **paint() içinde allocation YAPMA** - Paint objelerini cache'le
4. **RepaintBoundary** ile izole et

### Hit Testing
```dart
// ZORUNLU: Bounding box pre-filter
if (!_boundsCheck(stroke.bounds, x, y, tolerance)) {
  continue;  // 90%+ eleme
}
```

### Command Batching
```dart
// ✅ Tek gesture = tek command
void onPointerUp() {
  execute(EraseStrokesCommand(allErasedIds));  // Batch
}
```

### Metrikler
| Operasyon | Hedef |
|-----------|-------|
| Frame time | <16ms (60 FPS) |
| Hit test | <5ms |
| Selection render | <2ms |
| Shape render | <0.5ms |

---

## 🎨 Mevcut Özellikler

### Kalem Tipleri (5)
- Pencil, Ballpoint Pen, Fountain Pen, Brush, Highlighter

### Shape Tipleri (10)
- Line, Arrow, Rectangle, Ellipse, Triangle
- Diamond, Star, Pentagon, Hexagon, Plus

### Selection
- Lasso (point-in-polygon algorithm)
- Rectangle (bounds intersection)
- Move, Delete, Copy

### Text Tool
- Context menu (Edit, Delete, Style, Duplicate, Move)
- Style editor (color, size, B/I/U)

---

## 📋 Phase 4E Kapsamı

### 4E-A: Pen System Enhancement
- Yeni kalem tipleri (toplam 10)
- StrokeStyle genişletme

### 4E-B: Custom Pen Icons
- Canvas-based rendering
- Profesyonel görünüm

### 4E-C: Eraser Modes
- Pixel eraser
- Lasso eraser
- Visual feedback

### 4E-D: Advanced Color Picker
- HSV/RGB wheel
- Kategorize paletler
- Recent colors

### 4E-E: Toolbar Enhancement
- Settings panel
- Tool reordering

### 4E-F: Code Cleanup
- Enum conflicts fix
- Provider exports
- Refactoring

### 4E-G: Performance & Testing
- Optimizations
- Test coverage >85%

---

## 🔧 Çalışma Formatı

1. **Claude (Architect):** Spec/plan oluşturur
2. **Cursor (Developer):** Talimatları implement eder
3. **İlyas (Product Owner):** Review ve onay

### Cursor Talimat Formatı
```
GÖREV: [Kısa açıklama]

📖 Referans: [İlgili spec dosyası]

## Dosya
[path/to/file.dart]

## Implementasyon
[Kod veya açıklama]

## Test
[Test gereksinimleri]

## Commit
feat(core/ui): [mesaj]
```

---

## ❌ Yasak Eylemler

- setState pointer handler'larda
- paint() içinde allocation
- shouldRepaint => true
- Hit test bounds check olmadan
- Her pointer move'da command
- Relative import
- Phase 3 kodunu gereksiz değiştirme

---

## ✅ İzin Verilen

- ChangeNotifier/ValueNotifier
- ListenableBuilder
- Cached Paint/Path
- RepaintBoundary isolation
- Bounding box pre-filter
- Command batching
- Barrel exports

---

*Bu dosya 20 ayrı dökümanın özeti olarak Claude Project'e eklenmiştir.*

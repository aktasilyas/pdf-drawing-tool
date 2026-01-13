# Phase 2: Drawing Core - Master Plan

> **Status**: IN PROGRESS  
> **Branch**: `feature/phase2-drawing-core`  
> **Package**: `packages/drawing_core`

---

## 🎯 Phase 2 Amacı

UI-agnostic, pub.dev kalitesinde bir drawing core library oluşturmak.

**Kurallar:**
- ❌ Flutter import YOK (dart:ui hariç minimal kullanım)
- ❌ Widget YOK
- ❌ Premium/AI logic YOK
- ✅ Pure Dart
- ✅ %100 test coverage hedefi
- ✅ Immutable models
- ✅ Clean Architecture

---

## 📦 Package Yapısı

```
packages/drawing_core/
├── lib/
│   ├── drawing_core.dart          # Public API exports
│   └── src/
│       ├── models/
│       │   ├── drawing_point.dart
│       │   ├── stroke.dart
│       │   ├── stroke_style.dart
│       │   ├── layer.dart
│       │   └── document.dart
│       ├── tools/
│       │   ├── drawing_tool.dart
│       │   ├── pen_tool.dart
│       │   ├── highlighter_tool.dart
│       │   └── brush_tool.dart
│       ├── history/
│       │   ├── history_manager.dart
│       │   ├── drawing_command.dart
│       │   ├── add_stroke_command.dart
│       │   └── remove_stroke_command.dart
│       ├── input/
│       │   ├── input_processor.dart
│       │   └── path_smoother.dart
│       └── rendering/
│           └── stroke_renderer.dart
├── test/
│   ├── models/
│   │   ├── drawing_point_test.dart
│   │   ├── stroke_test.dart
│   │   ├── stroke_style_test.dart
│   │   ├── layer_test.dart
│   │   └── document_test.dart
│   ├── tools/
│   │   ├── pen_tool_test.dart
│   │   ├── highlighter_tool_test.dart
│   │   └── brush_tool_test.dart
│   ├── history/
│   │   ├── history_manager_test.dart
│   │   └── commands_test.dart
│   └── input/
│       └── path_smoother_test.dart
└── pubspec.yaml
```

---

## 🔢 Geliştirme Sırası (10 Adım)

### Adım 1: DrawingPoint Model
### Adım 2: StrokeStyle Model  
### Adım 3: Stroke Model
### Adım 4: Layer Model
### Adım 5: Document Model
### Adım 6: DrawingTool Abstract + PenTool
### Adım 7: HighlighterTool + BrushTool
### Adım 8: DrawingCommand + AddStrokeCommand
### Adım 9: HistoryManager
### Adım 10: PathSmoother + InputProcessor

---

## 📋 Her Adım İçin Checklist

Her adımda Cursor şunları YAPMALI:

```
□ Kodu yaz
□ Test dosyası oluştur
□ flutter analyze çalıştır (hata 0 olmalı)
□ flutter test çalıştır (tüm testler geçmeli)
□ Değişiklikleri listele
□ Commit mesajı öner
□ Kullanıcı onayı ile commit & push
```

---

## ⚠️ Kritik Kurallar

### YAPILMAMALI (DON'T)
```dart
// ❌ Flutter Color kullanma
import 'package:flutter/material.dart';
Color strokeColor; // YANLIŞ

// ❌ Flutter BlendMode kullanma
BlendMode blendMode; // YANLIŞ

// ❌ Widget oluşturma
class StrokeWidget extends StatelessWidget // YANLIŞ

// ❌ Mutable state
class Stroke {
  List<DrawingPoint> points = []; // YANLIŞ - mutable
}
```

### YAPILMALI (DO)
```dart
// ✅ int olarak ARGB renk
final int color; // 0xFFRRGGBB formatında

// ✅ Custom enum
enum DrawingBlendMode { normal, multiply, screen, overlay }

// ✅ Immutable model
class Stroke {
  final List<DrawingPoint> points; // final = immutable
  
  Stroke copyWith({List<DrawingPoint>? points}) {
    return Stroke(points: points ?? this.points);
  }
}

// ✅ Factory constructors
factory StrokeStyle.pen({...})
factory StrokeStyle.highlighter({...})
```

---

## 🧪 Test Gereksinimleri

Her model/class için minimum testler:

### Model Testleri
```dart
// Her model için:
- Constructor testi
- copyWith testi
- Equality testi (== ve hashCode)
- JSON serialization testi (toJson/fromJson)
- Edge case testleri (null, empty, max values)
```

### Tool Testleri
```dart
// Her tool için:
- onPointerDown testi
- onPointerMove testi
- onPointerUp testi
- Stroke oluşturma testi
- Style uygulama testi
```

### History Testleri
```dart
// HistoryManager için:
- execute testi
- undo testi
- redo testi
- canUndo/canRedo testi
- Max history limit testi
- Clear testi
```

---

## 📊 Başarı Kriterleri

Phase 2 TAMAMLANDI sayılması için:

```
✅ Tüm models implement edildi
✅ Tüm tools implement edildi
✅ HistoryManager çalışıyor
✅ %90+ test coverage
✅ flutter analyze hata yok
✅ Tüm testler geçiyor
✅ API documentation yazıldı
✅ Main branch'e merge edildi
```

---

## 🔗 Bağımlılıklar

### drawing_core/pubspec.yaml
```yaml
name: drawing_core
description: UI-agnostic drawing engine core
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  # Minimal dependencies - pure Dart preferred
  meta: ^1.9.0
  equatable: ^2.0.5

dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

---

*Document Version: 1.0*
*Created: 2025-01-13*

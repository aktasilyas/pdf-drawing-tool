# Phase 3: Canvas Integration - Master Plan

> **Status**: IN PROGRESS  
> **Branch**: `feature/phase3-canvas-integration`  
> **Package**: `packages/drawing_ui`  
> **Depends on**: `packages/drawing_core` (Phase 2 ✅)

---

## 🎯 Phase 3 Amacı

drawing_core kütüphanesini drawing_ui'a bağlayarak gerçek çizim deneyimi oluşturmak.

**Sonuç:** Kullanıcı ekrana dokunduğunda gerçek çizgiler görecek, undo/redo çalışacak.

---

## 📊 Başarı Kriterleri

| Kriter | Hedef | Ölçüm |
|--------|-------|-------|
| Frame rate | 60 FPS | DevTools |
| Input latency | <16ms | Stopwatch |
| 1000 stroke render | <100ms | Stopwatch |
| Zoom kalitesi | Piksel yok | Görsel |
| Memory leak | 0 | DevTools |
| Test coverage | >80% | flutter test --coverage |

---

## 🏗️ Mimari Genel Bakış

```
┌─────────────────────────────────────────────────────────────────┐
│                         DrawingScreen                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    TopNavigationBar                        │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │                       ToolBar                              │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │                                                            │  │
│  │   ┌─────────────────────────────────────────────────────┐ │  │
│  │   │                 DrawingCanvas                        │ │  │
│  │   │  ┌─────────────────────────────────────────────────┐│ │  │
│  │   │  │ RepaintBoundary: Background/Grid                ││ │  │
│  │   │  ├─────────────────────────────────────────────────┤│ │  │
│  │   │  │ RepaintBoundary: CommittedStrokesPainter        ││ │  │
│  │   │  ├─────────────────────────────────────────────────┤│ │  │
│  │   │  │ RepaintBoundary: ActiveStrokePainter            ││ │  │
│  │   │  ├─────────────────────────────────────────────────┤│ │  │
│  │   │  │ RepaintBoundary: SelectionOverlay               ││ │  │
│  │   │  └─────────────────────────────────────────────────┘│ │  │
│  │   └─────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │   [FloatingPenBox]              [AI Button]               │  │
│  │   [Tool Panels]                                           │  │
│  │                                                            │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Veri Akışı

```
User Touch → Pointer Event → DrawingController → Tool
                                    ↓
                              Add Point
                                    ↓
                           notifyListeners()
                                    ↓
                         ActiveStrokePainter.repaint()
                                    ↓
User Lifts  → Pointer Up → DrawingController.endStroke()
                                    ↓
                              Create Stroke
                                    ↓
                    HistoryManager.execute(AddStrokeCommand)
                                    ↓
                         DocumentProvider.update()
                                    ↓
                      CommittedStrokesPainter.repaint()
```

---

## 📁 Dosya Yapısı

```
packages/drawing_ui/lib/src/
├── canvas/
│   ├── mock_canvas.dart              # Mevcut (Phase 1)
│   ├── drawing_canvas.dart           # YENİ - Ana canvas widget
│   ├── stroke_painter.dart           # ✅ Tamamlandı
│   ├── canvas_controller.dart        # YENİ - Zoom/pan/gesture
│   └── canvas_gestures.dart          # YENİ - Gesture detection
├── rendering/
│   ├── flutter_stroke_renderer.dart  # ✅ Tamamlandı
│   └── canvas_cache_manager.dart     # YENİ - Performans cache
├── providers/
│   ├── drawing_providers.dart        # Güncellenecek
│   ├── document_provider.dart        # YENİ - DrawingDocument state
│   └── history_provider.dart         # YENİ - HistoryManager state
├── controllers/
│   └── drawing_controller.dart       # Taşınacak/düzenlenecek
└── screens/
    └── drawing_screen.dart           # Güncellenecek
```

---

## 📋 Adım Listesi (12 Adım)

| # | Adım | Açıklama | Öncelik |
|---|------|----------|---------|
| 1 | Branch + Yapı | Klasör yapısı | ✅ Tamamlandı |
| 2 | FlutterStrokeRenderer | Stroke→Canvas | ✅ Tamamlandı |
| 3 | StrokePainter | CustomPainter | ✅ Tamamlandı |
| 4 | DrawingCanvas Basic | Temel widget | 🔴 Kritik |
| 5 | Gesture Handling | Pointer events | 🔴 Kritik |
| 6 | Live Stroke Preview | Aktif çizim | 🔴 Kritik |
| 7 | DocumentProvider | Document state | 🔴 Kritik |
| 8 | HistoryProvider | Undo/redo state | 🔴 Kritik |
| 9 | Tool Integration | UI↔Core bağlantı | 🔴 Kritik |
| 10 | Undo/Redo Buttons | Buton aktivasyonu | 🟡 Yüksek |
| 11 | Zoom/Pan Support | Transform | 🟡 Yüksek |
| 12 | Final Integration | Test & polish | 🟡 Yüksek |

---

## ⚡ Performans Gereksinimleri

### Rendering Pipeline
```
60 FPS = 16.67ms per frame

Frame Budget:
├── Input processing: <2ms
├── State update: <2ms
├── Paint (active): <4ms
├── Paint (committed): <4ms (cached)
├── Compositing: <2ms
└── Buffer: ~2ms
```

### Memory Limits
```
├── Stroke başına: <1KB
├── Document (1000 stroke): <10MB
├── Undo history: Max 100 command
├── Cache: Max 50MB
└── Active points: Max 10,000
```

---

## 🎨 Kalite Gereksinimleri

### Zoom/Pan
- Minimum zoom: 0.1x (10%)
- Maximum zoom: 10x (1000%)
- Zoom sırasında: geçici scale OK
- Zoom sonrası: vektörden yeniden render
- Pinch-to-zoom: smooth, 60 FPS

### Stroke Kalitesi
- Anti-aliasing: her zaman ON
- Bezier smoothing: quadratic curves
- Pressure sensitivity: destekli
- Nib shapes: circle, ellipse, rectangle

### Display
- Retina/HiDPI: devicePixelRatio aware
- Text: her zaman vektör (TextPainter)
- PDF (future): zoom-aware DPI

---

## 🔗 drawing_core Entegrasyonu

### Kullanılacak Sınıflar
```dart
// Models
import 'package:drawing_core/drawing_core.dart';
- DrawingPoint
- Stroke
- StrokeStyle
- Layer
- DrawingDocument

// Tools
- PenTool
- HighlighterTool
- BrushTool

// History
- HistoryManager
- AddStrokeCommand
- RemoveStrokeCommand

// Utilities
- PathSmoother
```

### Provider Mapping
```
UI Provider          →  Core Class
─────────────────────────────────────
documentProvider     →  DrawingDocument
historyProvider      →  HistoryManager
currentToolProvider  →  DrawingTool (PenTool, etc.)
penSettingsProvider  →  StrokeStyle
canUndoProvider      →  historyManager.canUndo
canRedoProvider      →  historyManager.canRedo
```

---

## 🧪 Test Gereksinimleri

### Unit Tests
- DrawingController state transitions
- Gesture → Point conversion
- Zoom/pan calculations

### Widget Tests
- DrawingCanvas renders correctly
- Pointer events fire correctly
- Painter repaint optimization

### Integration Tests
- Full draw flow (down→move→up)
- Undo/redo cycle
- Tool switching mid-stroke

### Performance Tests
- 1000 stroke render time
- Rapid point addition (no frame drop)
- Memory usage over time

---

## ⚠️ Riskler ve Çözümler

| Risk | Etki | Çözüm |
|------|------|-------|
| Frame drop çizim sırasında | UX bozulur | Two-layer rendering |
| Memory leak undo history | Crash | Max 100 limit, dispose |
| Zoom'da bulanıklık | Amatör görünüm | Vektör rendering |
| Gesture conflict | Yanlış input | Gesture arena priority |

---

## 📅 Tahmini Süre

| Adım Grubu | Süre |
|------------|------|
| Adım 4-6 (Canvas + Gesture) | 3-4 saat |
| Adım 7-9 (Providers + Integration) | 2-3 saat |
| Adım 10-12 (Polish) | 2-3 saat |
| **Toplam** | **7-10 saat** |

---

## 📚 Referans Dökümanlar

- `docs/ARCHITECTURE.md` - Package boundaries
- `docs/PERFORMANCE_STRATEGY.md` - Performance rules
- `docs/PHASE3_CURSOR_INSTRUCTIONS.md` - Step-by-step tasks
- `packages/drawing_core/lib/drawing_core.dart` - Core API

---

*Document Version: 1.0*  
*Created: 2025-01-13*  
*Phase 3 Progress: 3/12 steps complete*

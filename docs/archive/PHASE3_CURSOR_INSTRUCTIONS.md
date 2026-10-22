# Phase 3: Cursor Görev Talimatları

> **ÖNEMLİ**: Bu dökümanı sırayla takip et. Bir adımı bitirmeden diğerine GEÇME.
> Her adımda performans kurallarını uygula!

---

## ✅ Tamamlanan Adımlar

### ADIM 1: Branch + Yapı ✅
- Branch: `feature/phase3-canvas-integration`
- Klasör yapısı hazır

### ADIM 2: FlutterStrokeRenderer ✅
- Dosya: `rendering/flutter_stroke_renderer.dart`
- 26 test geçti

### ADIM 3: StrokePainter + Controller ✅
- Dosya: `canvas/stroke_painter.dart`
- CommittedStrokesPainter, ActiveStrokePainter, DrawingController

---

## 📋 ADIM 4: DrawingCanvas Widget

### Görev
```
GÖREV: DrawingCanvas widget oluştur

Dosya: packages/drawing_ui/lib/src/canvas/drawing_canvas.dart

## ⚠️ PERFORMANS KURALLARI
1. setState KULLANMA - ChangeNotifier kullan
2. RepaintBoundary ile katmanları izole et
3. paint() içinde allocation YAPMA

## DrawingCanvas Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'stroke_painter.dart';
import '../rendering/flutter_stroke_renderer.dart';

class DrawingCanvas extends ConsumerStatefulWidget {
  final double width;
  final double height;
  
  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });
  
  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  // Controller - setState yerine bu kullanılacak
  late final DrawingController _drawingController;
  
  // Renderer - cache'lenmiş instance
  final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();
  
  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();
  }
  
  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Provider'dan document al (Adım 7'de bağlanacak)
    // final document = ref.watch(documentProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            children: [
              // Layer 1: Background/Grid
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _GridPainter(),
                ),
              ),
              
              // Layer 2: Committed Strokes (nadiren repaint)
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: _drawingController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: CommittedStrokesPainter(
                        strokes: [], // Adım 7'de document.strokes
                        renderer: _renderer,
                      ),
                    );
                  },
                ),
              ),
              
              // Layer 3: Active Stroke (her frame)
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: _drawingController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: ActiveStrokePainter(
                        points: _drawingController.activePoints,
                        style: _drawingController.activeStyle,
                        renderer: _renderer,
                      ),
                    );
                  },
                ),
              ),
              
              // Layer 4: Gesture Detection (Adım 5'te eklenecek)
              // Positioned.fill(child: GestureLayer()),
            ],
          ),
        );
      },
    );
  }
}

/// Basit grid painter (mock_canvas'tan alınabilir)
class _GridPainter extends CustomPainter {
  final Paint _gridPaint = Paint()
    ..color = const Color(0xFFE0E0E0)
    ..strokeWidth = 0.5;
  
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 20.0;
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    
    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
```

## Test Dosyası
packages/drawing_ui/test/canvas/drawing_canvas_test.dart

Test senaryoları:
- Widget renderlanıyor mu
- RepaintBoundary'ler var mı
- Grid çiziliyor mu
- Controller dispose ediliyor mu
- Size constraints çalışıyor mu

## Kurallar
✅ RepaintBoundary her katmanda
✅ ListenableBuilder (setState değil)
✅ Renderer cache'lenmiş
✅ Dispose düzgün yapılıyor
❌ setState KULLANMA

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 5: Gesture Handling

### Görev
```
GÖREV: Gesture handling ekle

Dosya: packages/drawing_ui/lib/src/canvas/drawing_canvas.dart (güncelle)

## Pointer Event Handling

DrawingCanvas'a gesture detection ekle:

```dart
// _DrawingCanvasState içine ekle:

void _handlePointerDown(PointerDownEvent event) {
  final point = _createDrawingPoint(event);
  final style = _getCurrentStyle(); // Provider'dan alınacak
  _drawingController.startStroke(point, style);
}

void _handlePointerMove(PointerMoveEvent event) {
  if (!_drawingController.isDrawing) return;
  
  // Coalesced events - daha smooth çizim
  final pointerEvent = event;
  
  // Historical points (daha hassas input)
  // Flutter'da event.original?.historyEntries kullanılabilir
  
  final point = _createDrawingPoint(event);
  _drawingController.addPoint(point);
}

void _handlePointerUp(PointerUpEvent event) {
  final stroke = _drawingController.endStroke();
  if (stroke != null) {
    // Adım 8'de: HistoryManager'a gönder
    // ref.read(historyProvider.notifier).addStroke(stroke);
  }
}

void _handlePointerCancel(PointerCancelEvent event) {
  _drawingController.cancelStroke();
}

DrawingPoint _createDrawingPoint(PointerEvent event) {
  return DrawingPoint(
    x: event.localPosition.dx,
    y: event.localPosition.dy,
    pressure: event.pressure, // Stylus pressure
    tilt: 0.0, // event.tilt kullanılabilir
    timestamp: event.timeStamp.inMilliseconds,
  );
}

StrokeStyle _getCurrentStyle() {
  // Şimdilik default, Adım 9'da provider'dan alınacak
  return StrokeStyle.pen();
}
```

## Widget Build Güncelle

```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return Listener(
        // Listener kullan, GestureDetector DEĞİL (raw pointer için)
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        behavior: HitTestBehavior.opaque,
        child: ClipRect(
          child: Stack(
            children: [
              // ... mevcut katmanlar
            ],
          ),
        ),
      );
    },
  );
}
```

## Test Senaryoları
- onPointerDown → isDrawing true
- onPointerMove → point ekleniyor
- onPointerUp → stroke oluşuyor
- onPointerCancel → stroke iptal
- Pressure değeri alınıyor mu

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 6: Live Stroke Preview

### Görev
```
GÖREV: Live stroke preview'ı test et ve optimize et

Bu adım Adım 4 ve 5'in birleşimi. 
Çizim yapıldığında canlı görüntüleme çalışmalı.

## Kontrol Listesi

1. Finger/stylus down → çizim başlıyor mu?
2. Hareket ettirince → çizgi görünüyor mu?
3. Kaldırınca → çizgi kalıyor mu?
4. FPS 60'ta mı? (DevTools ile kontrol)
5. Gecikme var mı?

## Debug Mode Ekle (Opsiyonel)

```dart
// Performans debug için
class _DrawingCanvasState ... {
  // Debug: frame sayacı
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  
  void _debugFrameRate() {
    _frameCount++;
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final diff = now.difference(_lastFrameTime!).inMilliseconds;
      if (diff > 20) { // 20ms = 50fps altı
        debugPrint('⚠️ Frame drop: ${diff}ms');
      }
    }
    _lastFrameTime = now;
  }
}
```

## Olası Sorunlar ve Çözümler

### Sorun: Çizgi görünmüyor
- ActiveStrokePainter doğru points alıyor mu?
- ListenableBuilder tetikleniyor mu?

### Sorun: Kasma var
- shouldRepaint her zaman true mu dönüyor?
- paint() içinde allocation var mı?

### Sorun: Gecikme var
- setState kullanılmış mı?
- Çok fazla listener var mı?

## Manuel Test

Uygulamayı çalıştır ve test et:
1. cd example_app
2. flutter run
3. Parmakla/mouse ile çiz
4. Smooth mu?

Bittiğinde sonuçları raporla.
```

---

## 📋 ADIM 7: DocumentProvider

### Görev
```
GÖREV: DocumentProvider oluştur

Dosya: packages/drawing_ui/lib/src/providers/document_provider.dart

## DrawingDocument State Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Document state provider
final documentProvider = StateNotifierProvider<DocumentNotifier, DrawingDocument>((ref) {
  return DocumentNotifier();
});

/// Active layer strokes (convenience getter)
final activeLayerStrokesProvider = Provider<List<Stroke>>((ref) {
  final document = ref.watch(documentProvider);
  return document.activeLayer?.strokes ?? [];
});

/// Total stroke count
final strokeCountProvider = Provider<int>((ref) {
  final document = ref.watch(documentProvider);
  return document.strokeCount;
});

class DocumentNotifier extends StateNotifier<DrawingDocument> {
  DocumentNotifier() : super(DrawingDocument.empty('Untitled'));
  
  /// Add stroke to active layer
  void addStroke(Stroke stroke) {
    state = state.addStrokeToActiveLayer(stroke);
  }
  
  /// Remove stroke from active layer
  void removeStroke(String strokeId) {
    state = state.removeStrokeFromActiveLayer(strokeId);
  }
  
  /// Update document
  void updateDocument(DrawingDocument document) {
    state = document;
  }
  
  /// Clear active layer
  void clearActiveLayer() {
    final activeLayer = state.activeLayer;
    if (activeLayer != null) {
      state = state.updateLayer(
        state.activeLayerIndex,
        activeLayer.clear(),
      );
    }
  }
  
  /// Set active layer
  void setActiveLayer(int index) {
    state = state.setActiveLayer(index);
  }
  
  /// Add new layer
  void addLayer(String name) {
    state = state.addLayer(Layer.empty(name));
  }
  
  /// New document
  void newDocument(String title) {
    state = DrawingDocument.empty(title);
  }
}
```

## drawing_providers.dart Güncelle

Mevcut dosyaya import ekle ve bağla:
```dart
// Mevcut canUndoProvider ve canRedoProvider'ı güncelle
// Adım 8'de HistoryProvider ile bağlanacak
```

## Test Dosyası
packages/drawing_ui/test/providers/document_provider_test.dart

Test senaryoları:
- Initial state boş document
- addStroke stroke ekliyor mu
- removeStroke stroke siliyor mu
- activeLayerStrokesProvider doğru listeyi döndürüyor mu
- strokeCount doğru mu

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 8: HistoryProvider

### Görev
```
GÖREV: HistoryProvider oluştur

Dosya: packages/drawing_ui/lib/src/providers/history_provider.dart

## HistoryManager State Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'document_provider.dart';

/// History manager instance
final historyManagerProvider = Provider<HistoryManager>((ref) {
  return HistoryManager(maxHistorySize: 100);
});

/// Can undo state
final canUndoProvider = Provider<bool>((ref) {
  final history = ref.watch(historyManagerProvider);
  // History state'ini izle (Notifier ile)
  return history.canUndo;
});

/// Can redo state
final canRedoProvider = Provider<bool>((ref) {
  final history = ref.watch(historyManagerProvider);
  return history.canRedo;
});

/// History actions notifier
final historyActionsProvider = Provider<HistoryActions>((ref) {
  return HistoryActions(ref);
});

class HistoryActions {
  final Ref _ref;
  
  HistoryActions(this._ref);
  
  /// Execute command and update document
  void execute(DrawingCommand command) {
    final history = _ref.read(historyManagerProvider);
    final document = _ref.read(documentProvider);
    
    final newDocument = history.execute(command, document);
    _ref.read(documentProvider.notifier).updateDocument(newDocument);
  }
  
  /// Add stroke (convenience method)
  void addStroke(Stroke stroke, {int? layerIndex}) {
    final document = _ref.read(documentProvider);
    final targetLayer = layerIndex ?? document.activeLayerIndex;
    
    final command = AddStrokeCommand(
      layerIndex: targetLayer,
      stroke: stroke,
    );
    execute(command);
  }
  
  /// Undo last action
  void undo() {
    final history = _ref.read(historyManagerProvider);
    final document = _ref.read(documentProvider);
    
    final newDocument = history.undo(document);
    if (newDocument != null) {
      _ref.read(documentProvider.notifier).updateDocument(newDocument);
    }
  }
  
  /// Redo last undone action
  void redo() {
    final history = _ref.read(historyManagerProvider);
    final document = _ref.read(documentProvider);
    
    final newDocument = history.redo(document);
    if (newDocument != null) {
      _ref.read(documentProvider.notifier).updateDocument(newDocument);
    }
  }
  
  /// Clear history
  void clearHistory() {
    _ref.read(historyManagerProvider).clear();
  }
}
```

## drawing_providers.dart Güncelle

Mevcut canUndoProvider ve canRedoProvider'ı yeni provider'lara yönlendir.

## Test Dosyası
packages/drawing_ui/test/providers/history_provider_test.dart

Test senaryoları:
- addStroke command execute
- undo stroke'u geri alıyor mu
- redo tekrar ekliyor mu
- canUndo/canRedo doğru mu

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 9: Tool Integration

### Görev
```
GÖREV: UI tool'larını drawing_core tool'larına bağla

Dosya: Birden fazla dosya güncellenecek

## 1. Tool Instance Provider

```dart
// providers/tool_provider.dart (yeni veya mevcut güncelle)

final activeToolProvider = Provider<DrawingTool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  final style = _getStyleForTool(ref, toolType);
  
  switch (toolType) {
    case ToolType.pen:
      return PenTool(style: style);
    case ToolType.highlighter:
      return HighlighterTool(style: style);
    case ToolType.brush:
      return BrushTool(style: style);
    default:
      return PenTool(style: style);
  }
});

StrokeStyle _getStyleForTool(Ref ref, ToolType type) {
  switch (type) {
    case ToolType.pen:
      final settings = ref.watch(penSettingsProvider(type));
      return StrokeStyle(
        color: settings.color.value, // Flutter Color → int
        thickness: settings.thickness,
        opacity: 1.0,
        nibShape: _convertNibShape(settings.nibShape),
      );
    // ... diğer tool'lar
  }
}
```

## 2. DrawingCanvas Güncelle

```dart
// drawing_canvas.dart

StrokeStyle _getCurrentStyle() {
  // Artık provider'dan al
  final tool = ref.read(activeToolProvider);
  return tool.style;
}

void _handlePointerUp(PointerUpEvent event) {
  final stroke = _drawingController.endStroke();
  if (stroke != null) {
    // HistoryActions kullan
    ref.read(historyActionsProvider).addStroke(stroke);
  }
}
```

## 3. DrawingScreen Güncelle

```dart
// MockCanvas yerine DrawingCanvas kullan

// Mevcut:
// MockCanvas()

// Yeni:
DrawingCanvas()
```

## Test Senaryoları
- Pen tool seçiliyken pen style kullanılıyor mu
- Highlighter seçiliyken yarı saydam mı
- Tool değişince style değişiyor mu
- Çizim document'a ekleniyor mu

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 10: Undo/Redo Button Activation

### Görev
```
GÖREV: Undo/Redo butonlarını aktif et

Dosya: packages/drawing_ui/lib/src/toolbar/tool_bar.dart (güncelle)

## Undo/Redo Butonları

```dart
// ToolBar içinde

Consumer(
  builder: (context, ref, _) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.undo),
          onPressed: canUndo 
            ? () => ref.read(historyActionsProvider).undo()
            : null,
          tooltip: 'Geri Al',
        ),
        IconButton(
          icon: Icon(Icons.redo),
          onPressed: canRedo
            ? () => ref.read(historyActionsProvider).redo()
            : null,
          tooltip: 'Yinele',
        ),
      ],
    );
  },
)
```

## Test Senaryoları
- Başlangıçta undo/redo disabled
- Çizim sonrası undo enabled
- Undo sonrası redo enabled
- Undo çizimi geri alıyor mu
- Redo çizimi geri getiriyor mu

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 11: Zoom/Pan Support

### Görev
```
GÖREV: Temel zoom/pan desteği ekle

Dosya: packages/drawing_ui/lib/src/canvas/drawing_canvas.dart (güncelle)

## ⚠️ KALİTE KURALI
- Zoom'da vektör rendering (bulanıklık YOK)
- Pan smooth olmalı (60 FPS)

## Zoom/Pan State

```dart
class _DrawingCanvasState ... {
  // Zoom/Pan state
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;
  
  // Zoom limits
  static const double _minZoom = 0.1;
  static const double _maxZoom = 10.0;
  
  // Transform matrix
  Matrix4 get _transformMatrix {
    return Matrix4.identity()
      ..translate(_panOffset.dx, _panOffset.dy)
      ..scale(_zoom);
  }
}
```

## Gesture Detection

```dart
// İki parmak gesture için GestureDetector ekle
GestureDetector(
  onScaleStart: _handleScaleStart,
  onScaleUpdate: _handleScaleUpdate,
  onScaleEnd: _handleScaleEnd,
  child: Listener(
    // Tek parmak = çizim
    onPointerDown: _handlePointerDown,
    ...
  ),
)

void _handleScaleUpdate(ScaleUpdateDetails details) {
  setState(() { // Zoom için setState OK (sık değil)
    _zoom = (_zoom * details.scale).clamp(_minZoom, _maxZoom);
    _panOffset += details.focalPointDelta;
  });
}
```

## Transform Uygula

```dart
@override
Widget build(BuildContext context) {
  return Transform(
    transform: _transformMatrix,
    child: Stack(
      children: [
        // ... katmanlar
      ],
    ),
  );
}
```

## Test Senaryoları
- Pinch zoom çalışıyor mu
- Two-finger pan çalışıyor mu
- Zoom sınırları çalışıyor mu
- Çizim hala doğru koordinatlarda mı

Bittiğinde sonuçları göster, commit için onay bekle.
```

---

## 📋 ADIM 12: Final Integration & Test

### Görev
```
GÖREV: Final entegrasyon ve test

## Kontrol Listesi

### Fonksiyonel
- [ ] Çizim çalışıyor
- [ ] Undo çalışıyor
- [ ] Redo çalışıyor
- [ ] Tool değişimi çalışıyor
- [ ] Renk değişimi çalışıyor
- [ ] Kalınlık değişimi çalışıyor
- [ ] Zoom çalışıyor
- [ ] Pan çalışıyor

### Performans
- [ ] Çizim sırasında kasma yok
- [ ] 60 FPS
- [ ] Memory leak yok

### Kalite
- [ ] Zoom'da bulanıklık yok
- [ ] Çizgiler smooth

## Tüm Testleri Çalıştır

```bash
cd packages/drawing_ui
flutter test
flutter analyze
```

## Export Güncelle

drawing_ui.dart dosyasına yeni export'ları ekle.

## Son Commit ve Push

```bash
git add .
git commit -m "feat(ui): complete Phase 3 canvas integration"
git push origin feature/phase3-canvas-integration
```

## Main'e Merge

```bash
git checkout main
git merge feature/phase3-canvas-integration
git push origin main
git tag -a v0.3.0-phase3 -m "Phase 3: Canvas Integration complete"
git push origin v0.3.0-phase3
```

Phase 3 tamamlandı! 🎉
```

---

## 📊 İlerleme Takibi

| Adım | Durum | Tarih |
|------|-------|-------|
| 1 | ✅ | - |
| 2 | ✅ | - |
| 3 | ✅ | - |
| 4 | ❌ | - |
| 5 | ❌ | - |
| 6 | ❌ | - |
| 7 | ❌ | - |
| 8 | ❌ | - |
| 9 | ❌ | - |
| 10 | ❌ | - |
| 11 | ❌ | - |
| 12 | ❌ | - |

---

*Document Version: 1.0*
*Created: 2025-01-13*

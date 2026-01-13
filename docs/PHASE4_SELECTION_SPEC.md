# Phase 4B: Selection System - Technical Specification

> **Module**: Selection System  
> **Package**: `drawing_core` + `drawing_ui`  
> **Priority**: 🔴 KRİTİK

---

## 🎯 Amaç

Elementleri seçme ve manipüle etme sistemi:
1. **Lasso Selection**: Serbest çizim ile seçim alanı
2. **Rectangle Selection**: Dikdörtgen ile seçim alanı
3. **Selection Actions**: Taşıma, silme, kopyalama

---

## 📐 Selection Model

### Selection State

```dart
// lib/src/models/selection.dart

enum SelectionType {
  lasso,
  rectangle,
}

/// Seçim durumunu temsil eder
class Selection {
  final String id;
  final SelectionType type;
  final List<String> selectedStrokeIds;
  final List<String> selectedShapeIds;  // Phase 4C
  final BoundingBox bounds;
  final List<DrawingPoint>? lassoPath;  // Lasso için
  
  const Selection({
    required this.id,
    required this.type,
    required this.selectedStrokeIds,
    this.selectedShapeIds = const [],
    required this.bounds,
    this.lassoPath,
  });
  
  /// Seçim boş mu?
  bool get isEmpty => 
    selectedStrokeIds.isEmpty && selectedShapeIds.isEmpty;
  
  /// Toplam seçili element sayısı
  int get count => selectedStrokeIds.length + selectedShapeIds.length;
  
  /// Seçim merkezini hesapla
  Offset get center => Offset(
    (bounds.left + bounds.right) / 2,
    (bounds.top + bounds.bottom) / 2,
  );
  
  Selection copyWith({
    List<String>? selectedStrokeIds,
    List<String>? selectedShapeIds,
    BoundingBox? bounds,
  });
  
  Map<String, dynamic> toJson();
  factory Selection.fromJson(Map<String, dynamic> json);
}
```

### Selection Handle Positions

```
    TL ────── T ────── TR
    │                   │
    │                   │
    L        [C]        R
    │                   │
    │                   │
    BL ────── B ────── BR

TL = Top Left       T = Top Center      TR = Top Right
L  = Middle Left    C = Center          R  = Middle Right
BL = Bottom Left    B = Bottom Center   BR = Bottom Right
```

```dart
enum SelectionHandle {
  topLeft,
  topCenter,
  topRight,
  middleLeft,
  middleRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  center,  // Taşıma için
}

extension SelectionHandlePosition on SelectionHandle {
  Offset getPosition(BoundingBox bounds) {
    switch (this) {
      case SelectionHandle.topLeft:
        return Offset(bounds.left, bounds.top);
      case SelectionHandle.topCenter:
        return Offset((bounds.left + bounds.right) / 2, bounds.top);
      case SelectionHandle.topRight:
        return Offset(bounds.right, bounds.top);
      case SelectionHandle.middleLeft:
        return Offset(bounds.left, (bounds.top + bounds.bottom) / 2);
      case SelectionHandle.middleRight:
        return Offset(bounds.right, (bounds.top + bounds.bottom) / 2);
      case SelectionHandle.bottomLeft:
        return Offset(bounds.left, bounds.bottom);
      case SelectionHandle.bottomCenter:
        return Offset((bounds.left + bounds.right) / 2, bounds.bottom);
      case SelectionHandle.bottomRight:
        return Offset(bounds.right, bounds.bottom);
      case SelectionHandle.center:
        return Offset(
          (bounds.left + bounds.right) / 2,
          (bounds.top + bounds.bottom) / 2,
        );
    }
  }
}
```

---

## 📦 drawing_core Implementasyonu

### 1. SelectionTool Abstract

```dart
// lib/src/tools/selection_tool.dart

abstract class SelectionTool {
  /// Seçim başlat
  void startSelection(DrawingPoint point);
  
  /// Seçim alanını güncelle
  void updateSelection(DrawingPoint point);
  
  /// Seçimi tamamla ve Selection döndür
  Selection? endSelection(List<Stroke> strokes);
  
  /// Seçimi iptal et
  void cancelSelection();
  
  /// Seçim aktif mi?
  bool get isSelecting;
  
  /// Geçici seçim path'i (preview için)
  List<DrawingPoint> get currentPath;
}
```

### 2. LassoSelectionTool

```dart
// lib/src/tools/lasso_selection_tool.dart

class LassoSelectionTool implements SelectionTool {
  final List<DrawingPoint> _path = [];
  bool _isSelecting = false;
  
  @override
  void startSelection(DrawingPoint point) {
    _path.clear();
    _path.add(point);
    _isSelecting = true;
  }
  
  @override
  void updateSelection(DrawingPoint point) {
    if (!_isSelecting) return;
    _path.add(point);
  }
  
  @override
  Selection? endSelection(List<Stroke> strokes) {
    if (!_isSelecting || _path.length < 3) {
      cancelSelection();
      return null;
    }
    
    _isSelecting = false;
    
    // Path'i kapat
    _path.add(_path.first);
    
    // Seçim alanı içindeki stroke'ları bul
    final selectedIds = _findStrokesInLasso(strokes);
    
    if (selectedIds.isEmpty) {
      _path.clear();
      return null;
    }
    
    // Seçilen stroke'ların bounds'unu hesapla
    final bounds = _calculateSelectionBounds(strokes, selectedIds);
    
    return Selection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: SelectionType.lasso,
      selectedStrokeIds: selectedIds,
      bounds: bounds,
      lassoPath: List.from(_path),
    );
  }
  
  @override
  void cancelSelection() {
    _path.clear();
    _isSelecting = false;
  }
  
  @override
  bool get isSelecting => _isSelecting;
  
  @override
  List<DrawingPoint> get currentPath => List.unmodifiable(_path);
  
  List<String> _findStrokesInLasso(List<Stroke> strokes) {
    final selectedIds = <String>[];
    
    for (final stroke in strokes) {
      if (_isStrokeInLasso(stroke)) {
        selectedIds.add(stroke.id);
      }
    }
    
    return selectedIds;
  }
  
  bool _isStrokeInLasso(Stroke stroke) {
    // Stroke'un herhangi bir noktası lasso içindeyse seçili say
    // Veya tüm noktalar içinde olmalı (strict mode)
    for (final point in stroke.points) {
      if (_isPointInPolygon(point.x, point.y)) {
        return true;
      }
    }
    return false;
  }
  
  /// Ray casting algoritması ile point-in-polygon testi
  bool _isPointInPolygon(double x, double y) {
    if (_path.length < 3) return false;
    
    bool inside = false;
    int j = _path.length - 1;
    
    for (int i = 0; i < _path.length; i++) {
      final xi = _path[i].x;
      final yi = _path[i].y;
      final xj = _path[j].x;
      final yj = _path[j].y;
      
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      
      j = i;
    }
    
    return inside;
  }
  
  BoundingBox _calculateSelectionBounds(
    List<Stroke> strokes,
    List<String> selectedIds,
  ) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final stroke in strokes) {
      if (!selectedIds.contains(stroke.id)) continue;
      
      final bounds = stroke.bounds;
      if (bounds == null) continue;
      
      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }
    
    return BoundingBox(
      left: minX,
      top: minY,
      right: maxX,
      bottom: maxY,
    );
  }
}
```

### 3. RectSelectionTool

```dart
// lib/src/tools/rect_selection_tool.dart

class RectSelectionTool implements SelectionTool {
  DrawingPoint? _startPoint;
  DrawingPoint? _endPoint;
  bool _isSelecting = false;
  
  @override
  void startSelection(DrawingPoint point) {
    _startPoint = point;
    _endPoint = point;
    _isSelecting = true;
  }
  
  @override
  void updateSelection(DrawingPoint point) {
    if (!_isSelecting) return;
    _endPoint = point;
  }
  
  @override
  Selection? endSelection(List<Stroke> strokes) {
    if (!_isSelecting || _startPoint == null || _endPoint == null) {
      cancelSelection();
      return null;
    }
    
    _isSelecting = false;
    
    // Selection rectangle bounds
    final selectionBounds = BoundingBox(
      left: min(_startPoint!.x, _endPoint!.x),
      top: min(_startPoint!.y, _endPoint!.y),
      right: max(_startPoint!.x, _endPoint!.x),
      bottom: max(_startPoint!.y, _endPoint!.y),
    );
    
    // Minimum size kontrolü
    if (selectionBounds.width < 5 || selectionBounds.height < 5) {
      _clear();
      return null;
    }
    
    // Stroke'ları bul
    final selectedIds = _findStrokesInRect(strokes, selectionBounds);
    
    if (selectedIds.isEmpty) {
      _clear();
      return null;
    }
    
    // Seçilen stroke'ların gerçek bounds'u
    final actualBounds = _calculateSelectionBounds(strokes, selectedIds);
    
    return Selection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: SelectionType.rectangle,
      selectedStrokeIds: selectedIds,
      bounds: actualBounds,
    );
  }
  
  @override
  void cancelSelection() {
    _clear();
  }
  
  void _clear() {
    _startPoint = null;
    _endPoint = null;
    _isSelecting = false;
  }
  
  @override
  bool get isSelecting => _isSelecting;
  
  @override
  List<DrawingPoint> get currentPath {
    if (_startPoint == null || _endPoint == null) return [];
    
    // Rectangle olarak 4 köşe döndür
    return [
      DrawingPoint(x: _startPoint!.x, y: _startPoint!.y),
      DrawingPoint(x: _endPoint!.x, y: _startPoint!.y),
      DrawingPoint(x: _endPoint!.x, y: _endPoint!.y),
      DrawingPoint(x: _startPoint!.x, y: _endPoint!.y),
      DrawingPoint(x: _startPoint!.x, y: _startPoint!.y),  // Kapat
    ];
  }
  
  List<String> _findStrokesInRect(
    List<Stroke> strokes,
    BoundingBox selectionBounds,
  ) {
    return strokes
      .where((s) => _isStrokeInRect(s, selectionBounds))
      .map((s) => s.id)
      .toList();
  }
  
  bool _isStrokeInRect(Stroke stroke, BoundingBox rect) {
    final bounds = stroke.bounds;
    if (bounds == null) return false;
    
    // Bounds kesişimi kontrolü
    return bounds.left < rect.right &&
           bounds.right > rect.left &&
           bounds.top < rect.bottom &&
           bounds.bottom > rect.top;
  }
  
  // ... _calculateSelectionBounds aynı LassoSelectionTool'daki gibi
}
```

### 4. Selection Commands

```dart
// lib/src/history/move_selection_command.dart

class MoveSelectionCommand implements DrawingCommand {
  final int layerIndex;
  final List<String> strokeIds;
  final double deltaX;
  final double deltaY;
  
  MoveSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    required this.deltaX,
    required this.deltaY,
  });
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    
    for (final id in strokeIds) {
      final stroke = layer.strokes.firstWhere(
        (s) => s.id == id,
        orElse: () => throw StateError('Stroke not found: $id'),
      );
      
      // Tüm noktaları taşı
      final movedPoints = stroke.points.map((p) => DrawingPoint(
        x: p.x + deltaX,
        y: p.y + deltaY,
        pressure: p.pressure,
        tilt: p.tilt,
        timestamp: p.timestamp,
      )).toList();
      
      final movedStroke = stroke.copyWith(points: movedPoints);
      layer = layer.updateStroke(movedStroke);
    }
    
    return document.updateLayer(layerIndex, layer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    // Ters yönde taşı
    return MoveSelectionCommand(
      layerIndex: layerIndex,
      strokeIds: strokeIds,
      deltaX: -deltaX,
      deltaY: -deltaY,
    ).execute(document);
  }
  
  @override
  String get description => 'Move ${strokeIds.length} element(s)';
}
```

```dart
// lib/src/history/delete_selection_command.dart

class DeleteSelectionCommand implements DrawingCommand {
  final int layerIndex;
  final List<String> strokeIds;
  final List<Stroke> _deletedStrokes = [];
  
  DeleteSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
  });
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    
    _deletedStrokes.clear();
    _deletedStrokes.addAll(
      layer.strokes.where((s) => strokeIds.contains(s.id))
    );
    
    for (final id in strokeIds) {
      layer = layer.removeStroke(id);
    }
    
    return document.updateLayer(layerIndex, layer);
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    
    for (final stroke in _deletedStrokes) {
      layer = layer.addStroke(stroke);
    }
    
    return document.updateLayer(layerIndex, layer);
  }
  
  @override
  String get description => 'Delete ${strokeIds.length} element(s)';
}
```

---

## 📦 drawing_ui Implementasyonu

### 1. Selection Provider

```dart
// lib/src/providers/selection_provider.dart

/// Aktif seçim state
final selectionProvider = StateNotifierProvider<SelectionNotifier, Selection?>((ref) {
  return SelectionNotifier();
});

/// Seçim var mı?
final hasSelectionProvider = Provider<bool>((ref) {
  return ref.watch(selectionProvider) != null;
});

/// Seçili element sayısı
final selectionCountProvider = Provider<int>((ref) {
  return ref.watch(selectionProvider)?.count ?? 0;
});

class SelectionNotifier extends StateNotifier<Selection?> {
  SelectionNotifier() : super(null);
  
  void setSelection(Selection? selection) {
    state = selection;
  }
  
  void clearSelection() {
    state = null;
  }
  
  void updateBounds(BoundingBox newBounds) {
    if (state != null) {
      state = state!.copyWith(bounds: newBounds);
    }
  }
}
```

### 2. Selection Painter

```dart
// lib/src/canvas/selection_painter.dart

class SelectionPainter extends CustomPainter {
  final Selection? selection;
  final double zoom;
  
  // Paint objects cached
  static final Paint _boundsPaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  
  static final Paint _handleFillPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.fill;
  
  static final Paint _handleStrokePaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  
  static final Paint _lassoPaint = Paint()
    ..color = const Color(0x402196F3)
    ..style = PaintingStyle.fill;
  
  static const double _handleSize = 8.0;
  
  SelectionPainter({
    required this.selection,
    required this.zoom,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (selection == null) return;
    
    final bounds = selection!.bounds;
    
    // Lasso path varsa çiz
    if (selection!.lassoPath != null && selection!.lassoPath!.isNotEmpty) {
      _drawLassoPath(canvas, selection!.lassoPath!);
    }
    
    // Selection bounds
    final rect = Rect.fromLTRB(
      bounds.left,
      bounds.top,
      bounds.right,
      bounds.bottom,
    );
    canvas.drawRect(rect, _boundsPaint);
    
    // Handles
    _drawHandles(canvas, bounds);
  }
  
  void _drawLassoPath(Canvas canvas, List<DrawingPoint> path) {
    if (path.length < 3) return;
    
    final lassoPath = Path();
    lassoPath.moveTo(path.first.x, path.first.y);
    
    for (int i = 1; i < path.length; i++) {
      lassoPath.lineTo(path[i].x, path[i].y);
    }
    lassoPath.close();
    
    canvas.drawPath(lassoPath, _lassoPaint);
  }
  
  void _drawHandles(Canvas canvas, BoundingBox bounds) {
    final handles = [
      SelectionHandle.topLeft,
      SelectionHandle.topCenter,
      SelectionHandle.topRight,
      SelectionHandle.middleLeft,
      SelectionHandle.middleRight,
      SelectionHandle.bottomLeft,
      SelectionHandle.bottomCenter,
      SelectionHandle.bottomRight,
    ];
    
    for (final handle in handles) {
      final pos = handle.getPosition(bounds);
      _drawHandle(canvas, pos);
    }
  }
  
  void _drawHandle(Canvas canvas, Offset position) {
    final rect = Rect.fromCenter(
      center: position,
      width: _handleSize,
      height: _handleSize,
    );
    
    canvas.drawRect(rect, _handleFillPaint);
    canvas.drawRect(rect, _handleStrokePaint);
  }
  
  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection ||
           oldDelegate.zoom != zoom;
  }
}
```

### 3. Selection Gesture Handler

```dart
// lib/src/widgets/selection_handles.dart

class SelectionHandles extends ConsumerStatefulWidget {
  final Selection selection;
  final VoidCallback onSelectionChanged;
  
  const SelectionHandles({
    super.key,
    required this.selection,
    required this.onSelectionChanged,
  });
  
  @override
  ConsumerState<SelectionHandles> createState() => _SelectionHandlesState();
}

class _SelectionHandlesState extends ConsumerState<SelectionHandles> {
  SelectionHandle? _activeHandle;
  Offset? _dragStartPoint;
  BoundingBox? _originalBounds;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        painter: SelectionPainter(
          selection: widget.selection,
          zoom: ref.watch(zoomLevelProvider),
        ),
      ),
    );
  }
  
  void _handlePanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    _activeHandle = _hitTestHandle(localPos);
    _dragStartPoint = localPos;
    _originalBounds = widget.selection.bounds;
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activeHandle == null || _originalBounds == null) return;
    
    final delta = details.localPosition - _dragStartPoint!;
    
    if (_activeHandle == SelectionHandle.center) {
      // Taşıma
      _moveSelection(delta);
    } else {
      // Resize (Phase 5+ için)
    }
  }
  
  void _handlePanEnd(DragEndDetails details) {
    if (_activeHandle == SelectionHandle.center && _dragStartPoint != null) {
      final delta = details.localPosition - _dragStartPoint!;
      _commitMove(delta);
    }
    
    _activeHandle = null;
    _dragStartPoint = null;
    _originalBounds = null;
  }
  
  void _moveSelection(Offset delta) {
    // Preview taşıma (UI güncelleme)
    final newBounds = BoundingBox(
      left: _originalBounds!.left + delta.dx,
      top: _originalBounds!.top + delta.dy,
      right: _originalBounds!.right + delta.dx,
      bottom: _originalBounds!.bottom + delta.dy,
    );
    
    ref.read(selectionProvider.notifier).updateBounds(newBounds);
  }
  
  void _commitMove(Offset delta) {
    // Gerçek taşıma (command ile)
    final command = MoveSelectionCommand(
      layerIndex: ref.read(documentProvider).activeLayerIndex,
      strokeIds: widget.selection.selectedStrokeIds,
      deltaX: delta.dx,
      deltaY: delta.dy,
    );
    
    ref.read(historyManagerProvider.notifier).execute(command);
    widget.onSelectionChanged();
  }
  
  SelectionHandle? _hitTestHandle(Offset point) {
    const hitRadius = 12.0;
    
    final handles = SelectionHandle.values;
    for (final handle in handles) {
      final handlePos = handle.getPosition(widget.selection.bounds);
      if ((point - handlePos).distance <= hitRadius) {
        return handle;
      }
    }
    
    // İç alanda mı? (taşıma için)
    final bounds = widget.selection.bounds;
    if (point.dx >= bounds.left &&
        point.dx <= bounds.right &&
        point.dy >= bounds.top &&
        point.dy <= bounds.bottom) {
      return SelectionHandle.center;
    }
    
    return null;
  }
}
```

---

## 🧪 Test Senaryoları

### Selection Tools
```dart
group('LassoSelectionTool', () {
  test('creates selection from closed path');
  test('point-in-polygon correctly identifies inside points');
  test('returns null for empty selection');
  test('calculates correct bounds');
});

group('RectSelectionTool', () {
  test('creates selection from rectangle');
  test('finds strokes intersecting rectangle');
  test('handles inverted rectangle (right-to-left drag)');
});
```

### Selection Commands
```dart
group('MoveSelectionCommand', () {
  test('moves all selected strokes');
  test('undo moves back to original position');
});

group('DeleteSelectionCommand', () {
  test('deletes all selected strokes');
  test('undo restores deleted strokes');
});
```

---

## 📋 Checklist

```
□ Selection model oluşturuldu
□ SelectionTool abstract class
□ LassoSelectionTool implementasyonu
□ RectSelectionTool implementasyonu
□ MoveSelectionCommand
□ DeleteSelectionCommand
□ SelectionProvider
□ SelectionPainter
□ SelectionHandles widget
□ DrawingCanvas entegrasyonu
□ Tüm testler geçiyor
```

---

*Specification Version: 1.0*

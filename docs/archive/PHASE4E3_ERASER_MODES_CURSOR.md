# Phase 4E-3: Eraser Modes - Cursor Talimatları

> **Modül:** Eraser Modes Completion  
> **Öncelik:** 🔴 Yüksek  
> **Tahmini Süre:** 4-5 saat  
> **Branch:** feature/phase4e-enhancements

---

## ⚠️ KRİTİK KURALLAR (HER ADIMDA UYGULA)

```
1. TEST FIRST: Her adımda test dosyası oluştur
2. CURRENT_STATUS.md: Her adım sonrası güncelle
3. CHECKLIST_TODO.md: Tamamlanan maddeleri işaretle
4. TABLET TESTİ: Commit öncesi MUTLAKA tablet/emülatörde test et
5. MEVCUT YAPIYI BOZMA: Stroke eraser çalışmaya devam etmeli
```

---

## 📋 Modül Özeti

**Amaç:** Eksik silgi modlarını tamamla ve kullanıcı dostu silgi cursor'u ekle

**Mevcut Durum:**
- ✅ Stroke Eraser (çizgi silme) - ÇALIŞIYOR
- ❌ Pixel Eraser (nokta silme) - EKSİK
- ❌ Lasso Eraser (seçerek silme) - EKSİK
- ❌ Eraser Cursor (görsel feedback) - EKSİK

**Hedef:**
- 3 silgi modu tam çalışır
- Canvas üzerinde silgi ikonu görünür
- Undo/redo ile entegre
- %90+ test coverage

---

## 📁 Dosya Yapısı

```
packages/drawing_core/lib/src/
├── tools/
│   ├── eraser_tool.dart (MEVCUT - güncelle)
│   ├── pixel_eraser_tool.dart (YENİ)
│   └── lasso_eraser_tool.dart (YENİ)
├── history/
│   └── erase_points_command.dart (YENİ - pixel eraser için)
└── hit_testing/
    └── stroke_hit_tester.dart (MEVCUT - güncelle)

packages/drawing_ui/lib/src/
├── canvas/
│   ├── eraser_cursor_painter.dart (YENİ)
│   └── drawing_canvas.dart (GÜNCELLE)
├── providers/
│   └── eraser_provider.dart (MEVCUT - güncelle)
└── widgets/
    └── eraser_cursor_widget.dart (YENİ)

test/
├── drawing_core/
│   ├── tools/pixel_eraser_tool_test.dart (YENİ)
│   └── tools/lasso_eraser_tool_test.dart (YENİ)
└── drawing_ui/
    └── canvas/eraser_cursor_test.dart (YENİ)
```

---

## ADIM 1: Pixel Eraser Tool (drawing_core)

### Görev
Nokta bazlı silme - dokunulan yerdeki çizgi segmentlerini siler (tüm çizgiyi değil)

### Dosya: `packages/drawing_core/lib/src/tools/pixel_eraser_tool.dart`

```dart
import 'package:drawing_core/drawing_core.dart';

/// Pixel-based eraser that removes individual stroke segments.
/// Unlike stroke eraser, this only removes the touched portion.
class PixelEraserTool {
  PixelEraserTool({
    this.size = 20.0,
    this.pressureSensitive = true,
  });

  final double size;
  final bool pressureSensitive;
  
  /// Points collected during erase gesture
  final List<DrawingPoint> _erasePoints = [];
  
  /// Strokes affected during this gesture (for undo batching)
  final Map<String, List<int>> _affectedSegments = {};
  
  void onPointerDown(double x, double y, double pressure) {
    _erasePoints.clear();
    _affectedSegments.clear();
    _addErasePoint(x, y, pressure);
  }
  
  void onPointerMove(double x, double y, double pressure) {
    _addErasePoint(x, y, pressure);
  }
  
  /// Returns modified strokes and segments to remove
  EraseResult onPointerUp() {
    final result = EraseResult(
      affectedSegments: Map.from(_affectedSegments),
      erasePoints: List.from(_erasePoints),
    );
    _erasePoints.clear();
    _affectedSegments.clear();
    return result;
  }
  
  void _addErasePoint(double x, double y, double pressure) {
    final effectiveSize = pressureSensitive 
        ? size * (0.5 + pressure * 0.5)
        : size;
    
    _erasePoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: pressure,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  /// Find stroke segments that intersect with eraser at given point
  List<SegmentHit> findSegmentsAt(
    List<Stroke> strokes,
    double x,
    double y,
    double eraserSize,
  ) {
    final hits = <SegmentHit>[];
    final tolerance = eraserSize / 2;
    
    for (final stroke in strokes) {
      // Bounding box pre-filter (ZORUNLU)
      if (!_boundsCheck(stroke.bounds, x, y, tolerance)) {
        continue;
      }
      
      // Check each segment
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        
        final distance = _pointToSegmentDistance(x, y, p1.x, p1.y, p2.x, p2.y);
        final effectiveTolerance = tolerance + (stroke.style.thickness / 2);
        
        if (distance <= effectiveTolerance) {
          hits.add(SegmentHit(
            strokeId: stroke.id,
            segmentIndex: i,
            distance: distance,
          ));
        }
      }
    }
    
    return hits;
  }
  
  bool _boundsCheck(BoundingBox? bounds, double x, double y, double tolerance) {
    if (bounds == null) return false;
    return x >= bounds.left - tolerance &&
           x <= bounds.right + tolerance &&
           y >= bounds.top - tolerance &&
           y <= bounds.bottom + tolerance;
  }
  
  double _pointToSegmentDistance(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    
    if (dx == 0 && dy == 0) {
      return _distance(px, py, x1, y1);
    }
    
    final t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);
    
    return _distance(px, py, x1 + clampedT * dx, y1 + clampedT * dy);
  }
  
  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return (dx * dx + dy * dy).sqrt();
  }
}

/// Result of pixel erase operation
class EraseResult {
  const EraseResult({
    required this.affectedSegments,
    required this.erasePoints,
  });
  
  /// Map of strokeId -> list of segment indices to remove
  final Map<String, List<int>> affectedSegments;
  
  /// Points where eraser touched
  final List<DrawingPoint> erasePoints;
  
  bool get isEmpty => affectedSegments.isEmpty;
}

/// A hit on a specific stroke segment
class SegmentHit {
  const SegmentHit({
    required this.strokeId,
    required this.segmentIndex,
    required this.distance,
  });
  
  final String strokeId;
  final int segmentIndex;
  final double distance;
}
```

### Test Dosyası: `test/tools/pixel_eraser_tool_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PixelEraserTool', () {
    late PixelEraserTool eraser;
    
    setUp(() {
      eraser = PixelEraserTool(size: 20.0);
    });
    
    test('finds segments within tolerance', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 100, y: 0, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final hits = eraser.findSegmentsAt([stroke], 50, 5, 20.0);
      
      expect(hits, isNotEmpty);
      expect(hits.first.strokeId, equals('test-1'));
      expect(hits.first.segmentIndex, equals(0));
    });
    
    test('ignores segments outside tolerance', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 100, y: 0, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final hits = eraser.findSegmentsAt([stroke], 50, 50, 20.0);
      
      expect(hits, isEmpty);
    });
    
    test('bounding box pre-filter works', () {
      final stroke = Stroke(
        id: 'test-1',
        points: [
          DrawingPoint(x: 0, y: 0, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 10, y: 10, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      // Far outside bounds
      final hits = eraser.findSegmentsAt([stroke], 1000, 1000, 20.0);
      
      expect(hits, isEmpty);
    });
    
    test('collects erase points during gesture', () {
      eraser.onPointerDown(10, 10, 1.0);
      eraser.onPointerMove(20, 20, 1.0);
      eraser.onPointerMove(30, 30, 1.0);
      
      final result = eraser.onPointerUp();
      
      expect(result.erasePoints.length, equals(3));
    });
    
    test('pressure sensitivity affects size', () {
      final pressureEraser = PixelEraserTool(
        size: 20.0,
        pressureSensitive: true,
      );
      
      // Low pressure should result in smaller effective size
      // This is tested indirectly through the erase behavior
      expect(pressureEraser.pressureSensitive, isTrue);
    });
  });
}
```

### Checklist
```
□ pixel_eraser_tool.dart oluşturuldu
□ EraseResult ve SegmentHit modelleri eklendi
□ Bounding box pre-filter uygulandı
□ pixel_eraser_tool_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-3: [█_____] 1/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(core): add PixelEraserTool with segment detection
```

---

## ADIM 2: Erase Points Command (drawing_core)

### Görev
Pixel eraser için undo/redo desteği - silinen segmentleri geri getirebilme

### Dosya: `packages/drawing_core/lib/src/history/erase_points_command.dart`

```dart
import 'package:drawing_core/drawing_core.dart';

/// Command for pixel-based erasing (segment removal).
/// Splits strokes at erased segments for undo support.
class ErasePointsCommand implements DrawingCommand {
  ErasePointsCommand({
    required this.layerIndex,
    required this.originalStrokes,
    required this.resultingStrokes,
  });
  
  final int layerIndex;
  
  /// Original strokes before erasing
  final List<Stroke> originalStrokes;
  
  /// Resulting strokes after erasing (split strokes)
  final List<Stroke> resultingStrokes;
  
  @override
  DrawingDocument execute(DrawingDocument document) {
    final layers = List<Layer>.from(document.layers);
    final layer = layers[layerIndex];
    
    // Remove original strokes
    var newStrokes = List<Stroke>.from(layer.strokes);
    for (final original in originalStrokes) {
      newStrokes.removeWhere((s) => s.id == original.id);
    }
    
    // Add resulting strokes (split pieces)
    newStrokes.addAll(resultingStrokes);
    
    layers[layerIndex] = layer.copyWith(strokes: newStrokes);
    
    return document.copyWith(
      layers: layers,
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  DrawingDocument undo(DrawingDocument document) {
    final layers = List<Layer>.from(document.layers);
    final layer = layers[layerIndex];
    
    // Remove resulting strokes
    var newStrokes = List<Stroke>.from(layer.strokes);
    for (final result in resultingStrokes) {
      newStrokes.removeWhere((s) => s.id == result.id);
    }
    
    // Restore original strokes
    newStrokes.addAll(originalStrokes);
    
    layers[layerIndex] = layer.copyWith(strokes: newStrokes);
    
    return document.copyWith(
      layers: layers,
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  String get description => 'Erase points (${originalStrokes.length} strokes affected)';
}

/// Utility to split stroke at erased segments
class StrokeSplitter {
  /// Split a stroke by removing specified segments
  /// Returns list of new strokes (pieces that remain)
  static List<Stroke> splitStroke(
    Stroke stroke,
    List<int> segmentIndicesToRemove,
  ) {
    if (segmentIndicesToRemove.isEmpty) {
      return [stroke];
    }
    
    final points = stroke.points;
    if (points.length < 2) {
      return [];
    }
    
    // Sort indices in descending order for easier processing
    final sortedIndices = segmentIndicesToRemove.toSet().toList()..sort();
    
    final pieces = <List<DrawingPoint>>[];
    var currentPiece = <DrawingPoint>[];
    
    for (int i = 0; i < points.length; i++) {
      final segmentIndex = i > 0 ? i - 1 : 0;
      
      if (i == 0 || !sortedIndices.contains(segmentIndex)) {
        currentPiece.add(points[i]);
      } else {
        // Segment is removed, start new piece
        if (currentPiece.length >= 2) {
          pieces.add(currentPiece);
        }
        currentPiece = [points[i]];
      }
    }
    
    // Add last piece
    if (currentPiece.length >= 2) {
      pieces.add(currentPiece);
    }
    
    // Convert pieces to strokes
    return pieces.asMap().entries.map((entry) {
      return Stroke(
        id: '${stroke.id}_split_${entry.key}',
        points: entry.value,
        style: stroke.style,
        createdAt: stroke.createdAt,
      );
    }).toList();
  }
}
```

### Test Dosyası: `test/history/erase_points_command_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('ErasePointsCommand', () {
    test('execute replaces original with split strokes', () {
      final original = Stroke(
        id: 'original',
        points: _createPoints(5),
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final split1 = Stroke(
        id: 'original_split_0',
        points: _createPoints(2),
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final document = DrawingDocument.empty().copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [original])],
      );
      
      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [original],
        resultingStrokes: [split1],
      );
      
      final result = command.execute(document);
      
      expect(result.layers[0].strokes.length, equals(1));
      expect(result.layers[0].strokes.first.id, equals('original_split_0'));
    });
    
    test('undo restores original strokes', () {
      final original = Stroke(
        id: 'original',
        points: _createPoints(5),
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final split1 = Stroke(
        id: 'original_split_0',
        points: _createPoints(2),
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final documentAfterErase = DrawingDocument.empty().copyWith(
        layers: [Layer.empty('Layer 1').copyWith(strokes: [split1])],
      );
      
      final command = ErasePointsCommand(
        layerIndex: 0,
        originalStrokes: [original],
        resultingStrokes: [split1],
      );
      
      final result = command.undo(documentAfterErase);
      
      expect(result.layers[0].strokes.length, equals(1));
      expect(result.layers[0].strokes.first.id, equals('original'));
    });
  });
  
  group('StrokeSplitter', () {
    test('splits stroke at removed segments', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(5), // 4 segments: 0-1, 1-2, 2-3, 3-4
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      // Remove middle segment (index 2)
      final pieces = StrokeSplitter.splitStroke(stroke, [2]);
      
      expect(pieces.length, equals(2));
    });
    
    test('returns empty list when all segments removed', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(2), // 1 segment
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final pieces = StrokeSplitter.splitStroke(stroke, [0]);
      
      // Single point pieces are discarded
      expect(pieces.length, equals(0));
    });
    
    test('returns original when no segments removed', () {
      final stroke = Stroke(
        id: 'test',
        points: _createPoints(5),
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final pieces = StrokeSplitter.splitStroke(stroke, []);
      
      expect(pieces.length, equals(1));
      expect(pieces.first.id, equals('test'));
    });
  });
}

List<DrawingPoint> _createPoints(int count) {
  return List.generate(count, (i) => DrawingPoint(
    x: i * 10.0,
    y: i * 10.0,
    pressure: 1.0,
    timestamp: i,
  ));
}
```

### Checklist
```
□ erase_points_command.dart oluşturuldu
□ StrokeSplitter utility eklendi
□ erase_points_command_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-3: [██____] 2/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(core): add ErasePointsCommand with StrokeSplitter
```

---

## ADIM 3: Lasso Eraser Tool (drawing_core)

### Görev
Seçim yaparak silme - çizilen alan içindeki tüm çizgileri siler

### Dosya: `packages/drawing_core/lib/src/tools/lasso_eraser_tool.dart`

```dart
import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';

/// Lasso-based eraser that removes all strokes within drawn selection.
class LassoEraserTool {
  LassoEraserTool();
  
  /// Points forming the lasso path
  final List<DrawingPoint> _lassoPoints = [];
  
  bool get isActive => _lassoPoints.isNotEmpty;
  
  List<DrawingPoint> get lassoPoints => List.unmodifiable(_lassoPoints);
  
  void onPointerDown(double x, double y) {
    _lassoPoints.clear();
    _lassoPoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  void onPointerMove(double x, double y) {
    _lassoPoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  /// Returns IDs of strokes to erase
  List<String> onPointerUp(List<Stroke> strokes) {
    if (_lassoPoints.length < 3) {
      _lassoPoints.clear();
      return [];
    }
    
    final strokeIds = findStrokesInLasso(strokes);
    _lassoPoints.clear();
    return strokeIds;
  }
  
  void cancel() {
    _lassoPoints.clear();
  }
  
  /// Find all strokes that have any point inside the lasso
  List<String> findStrokesInLasso(List<Stroke> strokes) {
    if (_lassoPoints.length < 3) return [];
    
    final result = <String>[];
    final polygon = _lassoPoints.map((p) => math.Point(p.x, p.y)).toList();
    
    for (final stroke in strokes) {
      // Quick bounds check
      if (!_boundsIntersect(stroke.bounds, _getLassoBounds())) {
        continue;
      }
      
      // Check if any point is inside lasso
      for (final point in stroke.points) {
        if (_isPointInPolygon(math.Point(point.x, point.y), polygon)) {
          result.add(stroke.id);
          break; // One point inside is enough
        }
      }
    }
    
    return result;
  }
  
  BoundingBox _getLassoBounds() {
    if (_lassoPoints.isEmpty) {
      return const BoundingBox(left: 0, top: 0, right: 0, bottom: 0);
    }
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final point in _lassoPoints) {
      minX = math.min(minX, point.x);
      minY = math.min(minY, point.y);
      maxX = math.max(maxX, point.x);
      maxY = math.max(maxY, point.y);
    }
    
    return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
  }
  
  bool _boundsIntersect(BoundingBox? strokeBounds, BoundingBox lassoBounds) {
    if (strokeBounds == null) return false;
    
    return !(strokeBounds.right < lassoBounds.left ||
             strokeBounds.left > lassoBounds.right ||
             strokeBounds.bottom < lassoBounds.top ||
             strokeBounds.top > lassoBounds.bottom);
  }
  
  /// Ray casting algorithm for point-in-polygon
  bool _isPointInPolygon(math.Point<double> point, List<math.Point<double>> polygon) {
    if (polygon.length < 3) return false;
    
    int intersections = 0;
    final n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];
      
      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }
    
    return intersections.isOdd;
  }
  
  bool _rayIntersectsSegment(
    math.Point<double> point,
    math.Point<double> p1,
    math.Point<double> p2,
  ) {
    // Ray goes from point to the right (positive x direction)
    if (p1.y > p2.y) {
      final temp = p1;
      p1 = p2;
      p2 = temp;
    }
    
    if (point.y == p1.y || point.y == p2.y) {
      // Avoid edge cases by slightly adjusting
      point = math.Point(point.x, point.y + 0.0001);
    }
    
    if (point.y < p1.y || point.y > p2.y) {
      return false;
    }
    
    if (point.x >= math.max(p1.x, p2.x)) {
      return false;
    }
    
    if (point.x < math.min(p1.x, p2.x)) {
      return true;
    }
    
    final slope = (p2.y - p1.y) / (p2.x - p1.x);
    final xIntersect = p1.x + (point.y - p1.y) / slope;
    
    return point.x < xIntersect;
  }
}
```

### Test Dosyası: `test/tools/lasso_eraser_tool_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('LassoEraserTool', () {
    late LassoEraserTool lasso;
    
    setUp(() {
      lasso = LassoEraserTool();
    });
    
    test('collects lasso points', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      expect(lasso.lassoPoints.length, equals(4));
      expect(lasso.isActive, isTrue);
    });
    
    test('finds strokes inside lasso', () {
      // Create a square lasso
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 0);
      lasso.onPointerMove(100, 100);
      lasso.onPointerMove(0, 100);
      
      // Stroke inside
      final insideStroke = Stroke(
        id: 'inside',
        points: [
          DrawingPoint(x: 50, y: 50, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 60, y: 60, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      // Stroke outside
      final outsideStroke = Stroke(
        id: 'outside',
        points: [
          DrawingPoint(x: 200, y: 200, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 210, y: 210, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final result = lasso.onPointerUp([insideStroke, outsideStroke]);
      
      expect(result, contains('inside'));
      expect(result, isNot(contains('outside')));
    });
    
    test('returns empty for small lasso', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(1, 1);
      
      final result = lasso.onPointerUp([]);
      
      expect(result, isEmpty);
    });
    
    test('clears on cancel', () {
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(100, 100);
      
      lasso.cancel();
      
      expect(lasso.isActive, isFalse);
      expect(lasso.lassoPoints, isEmpty);
    });
    
    test('bounding box pre-filter works', () {
      // Small lasso in corner
      lasso.onPointerDown(0, 0);
      lasso.onPointerMove(10, 0);
      lasso.onPointerMove(10, 10);
      lasso.onPointerMove(0, 10);
      
      // Stroke far away
      final farStroke = Stroke(
        id: 'far',
        points: [
          DrawingPoint(x: 1000, y: 1000, pressure: 1.0, timestamp: 0),
          DrawingPoint(x: 1010, y: 1010, pressure: 1.0, timestamp: 1),
        ],
        style: const StrokeStyle(thickness: 2.0, color: 0xFF000000),
      );
      
      final result = lasso.onPointerUp([farStroke]);
      
      expect(result, isEmpty);
    });
  });
}
```

### Checklist
```
□ lasso_eraser_tool.dart oluşturuldu
□ Point-in-polygon algoritması uygulandı
□ Bounding box pre-filter eklendi
□ lasso_eraser_tool_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-3: [███___] 3/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(core): add LassoEraserTool with point-in-polygon
```

---

## ADIM 4: Eraser Cursor Painter (drawing_ui)

### Görev
Canvas üzerinde silgi cursor'u gösterme - kullanıcı dostu görsel feedback

### Dosya: `packages/drawing_ui/lib/src/canvas/eraser_cursor_painter.dart`

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Paints the eraser cursor indicator on canvas.
/// Shows a circle for pixel/stroke eraser, path for lasso eraser.
class EraserCursorPainter extends CustomPainter {
  EraserCursorPainter({
    required this.position,
    required this.size,
    required this.mode,
    this.lassoPoints = const [],
    this.isActive = false,
  });
  
  final Offset position;
  final double size;
  final EraserCursorMode mode;
  final List<Offset> lassoPoints;
  final bool isActive;
  
  // Cached paint objects
  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  
  static final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill;
  
  static final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.black26;
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    switch (mode) {
      case EraserCursorMode.pixel:
      case EraserCursorMode.stroke:
        _drawCircleCursor(canvas);
        break;
      case EraserCursorMode.lasso:
        _drawLassoCursor(canvas);
        break;
    }
  }
  
  void _drawCircleCursor(Canvas canvas) {
    final radius = size / 2;
    
    // Shadow
    canvas.drawCircle(
      position + const Offset(1, 1),
      radius,
      _shadowPaint,
    );
    
    // Fill (semi-transparent)
    _fillPaint.color = isActive 
        ? Colors.red.withOpacity(0.2)
        : Colors.grey.withOpacity(0.1);
    canvas.drawCircle(position, radius, _fillPaint);
    
    // Stroke
    _strokePaint.color = isActive ? Colors.red : Colors.grey.shade600;
    canvas.drawCircle(position, radius, _strokePaint);
    
    // Eraser icon inside (small)
    if (size > 30) {
      _drawEraserIcon(canvas, position, size * 0.4);
    }
  }
  
  void _drawLassoCursor(Canvas canvas) {
    if (lassoPoints.isEmpty) {
      // Just show crosshair when not drawing
      _drawCrosshair(canvas, position);
      return;
    }
    
    // Draw lasso path
    final path = Path();
    path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
    
    for (int i = 1; i < lassoPoints.length; i++) {
      path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
    }
    
    // Fill
    _fillPaint.color = Colors.red.withOpacity(0.1);
    canvas.drawPath(path, _fillPaint);
    
    // Stroke (dashed effect via dashPath)
    _strokePaint.color = Colors.red.shade400;
    _strokePaint.strokeWidth = 2.0;
    canvas.drawPath(path, _strokePaint);
    
    // Marching ants effect (animated dots along path)
    _drawMarchingAnts(canvas, path);
  }
  
  void _drawCrosshair(Canvas canvas, Offset center) {
    _strokePaint.color = Colors.grey.shade600;
    _strokePaint.strokeWidth = 1.0;
    
    const size = 10.0;
    canvas.drawLine(
      center - const Offset(size, 0),
      center + const Offset(size, 0),
      _strokePaint,
    );
    canvas.drawLine(
      center - const Offset(0, size),
      center + const Offset(0, size),
      _strokePaint,
    );
  }
  
  void _drawEraserIcon(Canvas canvas, Offset center, double iconSize) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    // Simple eraser shape (rectangle with angled top)
    final rect = Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize * 0.6,
    );
    
    final path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.top + rect.height * 0.3);
    path.lineTo(rect.left + rect.width * 0.3, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawMarchingAnts(Canvas canvas, Path path) {
    // Simple dotted line effect
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw white dots along the path for contrast
    final metrics = path.computeMetrics().first;
    final length = metrics.length;
    
    for (double d = 0; d < length; d += 8) {
      final tangent = metrics.getTangentForOffset(d);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 1.5, paint..style = PaintingStyle.fill);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.size != size ||
           oldDelegate.mode != mode ||
           oldDelegate.isActive != isActive ||
           oldDelegate.lassoPoints.length != lassoPoints.length;
  }
}

enum EraserCursorMode {
  pixel,
  stroke,
  lasso,
}
```

### Dosya: `packages/drawing_ui/lib/src/widgets/eraser_cursor_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/canvas/eraser_cursor_painter.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Widget that displays eraser cursor overlay.
/// Positioned absolutely over the canvas.
class EraserCursorWidget extends ConsumerWidget {
  const EraserCursorWidget({
    super.key,
    required this.cursorPosition,
    required this.isVisible,
    this.lassoPoints = const [],
  });
  
  final Offset cursorPosition;
  final bool isVisible;
  final List<Offset> lassoPoints;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();
    
    final eraserSettings = ref.watch(eraserSettingsProvider);
    
    final mode = switch (eraserSettings.mode) {
      EraserMode.pixel => EraserCursorMode.pixel,
      EraserMode.stroke => EraserCursorMode.stroke,
      EraserMode.lasso => EraserCursorMode.lasso,
    };
    
    return IgnorePointer(
      child: CustomPaint(
        painter: EraserCursorPainter(
          position: cursorPosition,
          size: eraserSettings.size,
          mode: mode,
          lassoPoints: lassoPoints,
          isActive: lassoPoints.isNotEmpty,
        ),
        size: Size.infinite,
      ),
    );
  }
}
```

### Test Dosyası: `test/canvas/eraser_cursor_painter_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/canvas/eraser_cursor_painter.dart';

void main() {
  group('EraserCursorPainter', () {
    test('shouldRepaint returns true when position changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(10, 10),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    test('shouldRepaint returns false when same', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      expect(painter1.shouldRepaint(painter2), isFalse);
    });
    
    test('shouldRepaint returns true when mode changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
```

### Checklist
```
□ eraser_cursor_painter.dart oluşturuldu
□ eraser_cursor_widget.dart oluşturuldu
□ 3 mod için cursor çizimi (pixel, stroke, lasso)
□ Silgi ikonu cursor içinde görünüyor
□ Lasso için marching ants efekti
□ eraser_cursor_painter_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-3: [████__] 4/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(ui): add EraserCursorPainter with visual feedback
```

---

## ADIM 5: Canvas Integration & Polish

### Görev
Tüm eraser modlarını DrawingCanvas'a entegre et ve test et

### Dosya Güncellemeleri

#### `packages/drawing_ui/lib/src/providers/eraser_provider.dart` (GÜNCELLE)

```dart
// Mevcut EraserMode enum'a pixel modu ekle (zaten var, aktif et)
// Provider'da pixel ve lasso tool instance'ları tut

final pixelEraserToolProvider = Provider<PixelEraserTool>((ref) {
  final settings = ref.watch(eraserSettingsProvider);
  return PixelEraserTool(
    size: settings.size,
    pressureSensitive: settings.pressureSensitive,
  );
});

final lassoEraserToolProvider = Provider<LassoEraserTool>((ref) {
  return LassoEraserTool();
});

/// Current eraser cursor position
final eraserCursorPositionProvider = StateProvider<Offset?>((ref) => null);

/// Lasso eraser path points
final lassoEraserPointsProvider = StateProvider<List<Offset>>((ref) => []);
```

#### `packages/drawing_ui/lib/src/canvas/drawing_canvas.dart` (GÜNCELLE)

Eraser handling bölümüne ekle:

```dart
// In _handlePointerDown
void _handleEraserDown(Offset position, double pressure) {
  final mode = ref.read(eraserSettingsProvider).mode;
  
  switch (mode) {
    case EraserMode.pixel:
      ref.read(pixelEraserToolProvider).onPointerDown(
        position.dx, position.dy, pressure,
      );
      break;
    case EraserMode.stroke:
      // Mevcut stroke eraser logic
      break;
    case EraserMode.lasso:
      ref.read(lassoEraserToolProvider).onPointerDown(
        position.dx, position.dy,
      );
      ref.read(lassoEraserPointsProvider.notifier).state = [position];
      break;
  }
  
  ref.read(eraserCursorPositionProvider.notifier).state = position;
}

// In _handlePointerMove
void _handleEraserMove(Offset position, double pressure) {
  final mode = ref.read(eraserSettingsProvider).mode;
  
  switch (mode) {
    case EraserMode.pixel:
      final tool = ref.read(pixelEraserToolProvider);
      tool.onPointerMove(position.dx, position.dy, pressure);
      
      // Find and mark segments for removal
      final layer = ref.read(documentProvider).activeLayer;
      if (layer != null) {
        final hits = tool.findSegmentsAt(
          layer.strokes,
          position.dx,
          position.dy,
          ref.read(eraserSettingsProvider).size,
        );
        // Collect hits for batch processing
        _collectPixelEraseHits(hits);
      }
      break;
      
    case EraserMode.stroke:
      // Mevcut stroke eraser logic
      break;
      
    case EraserMode.lasso:
      ref.read(lassoEraserToolProvider).onPointerMove(
        position.dx, position.dy,
      );
      ref.read(lassoEraserPointsProvider.notifier).update(
        (points) => [...points, position],
      );
      break;
  }
  
  ref.read(eraserCursorPositionProvider.notifier).state = position;
}

// In _handlePointerUp
void _handleEraserUp(Offset position) {
  final mode = ref.read(eraserSettingsProvider).mode;
  
  switch (mode) {
    case EraserMode.pixel:
      _commitPixelErase();
      break;
      
    case EraserMode.stroke:
      // Mevcut stroke eraser logic
      break;
      
    case EraserMode.lasso:
      final layer = ref.read(documentProvider).activeLayer;
      if (layer != null) {
        final strokeIds = ref.read(lassoEraserToolProvider).onPointerUp(
          layer.strokes,
        );
        if (strokeIds.isNotEmpty) {
          _eraseStrokes(strokeIds);
        }
      }
      ref.read(lassoEraserPointsProvider.notifier).state = [];
      break;
  }
  
  ref.read(eraserCursorPositionProvider.notifier).state = null;
}
```

#### Canvas Widget Build (GÜNCELLE)

```dart
// In build method, add eraser cursor overlay
Stack(
  children: [
    // ... existing canvas layers
    
    // Eraser cursor overlay
    Consumer(
      builder: (context, ref, child) {
        final currentTool = ref.watch(currentToolProvider);
        final cursorPosition = ref.watch(eraserCursorPositionProvider);
        final lassoPoints = ref.watch(lassoEraserPointsProvider);
        
        final isEraser = currentTool == ToolType.eraser;
        
        return EraserCursorWidget(
          cursorPosition: cursorPosition ?? Offset.zero,
          isVisible: isEraser && cursorPosition != null,
          lassoPoints: lassoPoints,
        );
      },
    ),
  ],
),
```

### Final Test Checklist
```
□ Pixel eraser segmentleri siliyor
□ Pixel eraser undo/redo çalışıyor
□ Lasso eraser seçim yapıp siliyor
□ Lasso eraser undo/redo çalışıyor
□ Stroke eraser hala çalışıyor (regression yok)
□ Eraser cursor tüm modlarda görünüyor
□ Cursor size ayarı çalışıyor
□ Pressure sensitivity çalışıyor
□ Performans: 60 FPS
□ Hit test: <5ms
```

### Checklist
```
□ eraser_provider.dart güncellendi
□ drawing_canvas.dart güncellendi
□ Pixel eraser entegre edildi
□ Lasso eraser entegre edildi
□ Eraser cursor overlay eklendi
□ Barrel exports güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-3: [██████] 5/5 ✅)
□ CHECKLIST_TODO.md güncellendi
□ TABLET TESTİ yapıldı - TÜM MODLAR TEST EDİLDİ
□ Commit: feat(ui): integrate all eraser modes with cursor
□ Final commit: feat: complete Phase 4E-3 Eraser Modes
```

---

## 📋 CURRENT_STATUS.md Güncelleme Şablonu

Her adım sonrası bu formatı kullan:

```markdown
## Quick Status

| Key | Value |
|-----|-------|
| **Current Phase** | 4E - Enhancement & Cleanup |
| **Current Module** | 4E-3 Eraser Modes |
| **Current Step** | X/5 |
| **Last Commit** | [commit message] |
| **Branch** | feature/phase4e-enhancements |

---

## Phase 4E Progress

```
4E-1: Pen Types    [██████] 6/6 ✅
4E-2: Pen Icons    [██████] 6/6 ✅
4E-3: Eraser Modes [██____] X/5
4E-4: Color Picker [██████] 6/6 ✅
4E-5: Toolbar UX   [______] 0/5
4E-6: Performance  [______] 0/5
4E-7: Code Quality [______] 0/4
```
```

---

## 📋 CHECKLIST_TODO.md Güncelleme

Phase 4E bölümüne ekle:

```markdown
### Phase 4E-3: Eraser Modes

- [ ] PixelEraserTool with segment detection
- [ ] ErasePointsCommand with StrokeSplitter
- [ ] LassoEraserTool with point-in-polygon
- [ ] EraserCursorPainter with visual feedback
- [ ] DrawingCanvas integration all modes
- [ ] All eraser tests passing
- [ ] Tablet testing complete
```

---

## 🚨 HATIRLATMALAR

1. **Her adım sonrası:** `flutter analyze` ve `flutter test` çalıştır
2. **Commit öncesi:** Tablet/emülatörde manuel test yap
3. **Regression kontrolü:** Stroke eraser hala çalışıyor mu?
4. **Performance:** Hit test <5ms, render 60 FPS
5. **CURRENT_STATUS.md:** Her adım sonrası güncelle
6. **CHECKLIST:** Tamamlanan maddeleri [x] işaretle

---

*Phase 4E-3 başarıyla tamamlanacak! 🧹*

# Phase 5: Cursor Instructions - Step by Step

> **ÖNEMLİ:** Bu dosyayı baştan sona oku, sonra ADIM ADIM ilerle.  
> **KURAL:** Her adımda İlyas'tan onay al, kendi başına commit YAPMA!

---

## 🚨 BAŞLAMADAN ÖNCE

### 1. Yeni Branch Oluştur

```bash
# Main branch'in güncel olduğundan emin ol
git checkout main
git pull origin main

# Yeni branch oluştur
git checkout -b feature/phase5-multipage-pdf

# Branch'i kontrol et
git branch
# * feature/phase5-multipage-pdf
```

### 2. Mevcut Testleri Çalıştır

```bash
# Tüm testler geçmeli - BAŞLAMADAN ÖNCE
cd packages/drawing_core && flutter test
cd ../drawing_ui && flutter test

# Analyzer temiz olmalı
melos run analyze
```

⚠️ **Testler geçmiyorsa veya analyzer hata veriyorsa DURUR, İlyas'a bildir!**

---

## 📦 PHASE 5A: Page Model (6 Adım)

### Adım 5A-1: PageSize ve PagePreset

**Dosya:** `packages/drawing_core/lib/src/models/page_size.dart`

```dart
/// Sayfa boyutu preset'leri
enum PagePreset {
  a4Portrait,
  a4Landscape,
  letterPortrait,
  letterLandscape,
  custom,
}

/// Sayfa boyutu modeli
class PageSize {
  final double width;
  final double height;
  final PagePreset? preset;

  const PageSize({
    required this.width,
    required this.height,
    this.preset,
  });

  /// A4 Portrait (595 x 842 points @ 72 DPI)
  static const a4Portrait = PageSize(
    width: 595,
    height: 842,
    preset: PagePreset.a4Portrait,
  );

  /// A4 Landscape
  static const a4Landscape = PageSize(
    width: 842,
    height: 595,
    preset: PagePreset.a4Landscape,
  );

  /// US Letter Portrait (612 x 792 points)
  static const letterPortrait = PageSize(
    width: 612,
    height: 792,
    preset: PagePreset.letterPortrait,
  );

  /// US Letter Landscape
  static const letterLandscape = PageSize(
    width: 792,
    height: 612,
    preset: PagePreset.letterLandscape,
  );

  /// Aspect ratio
  double get aspectRatio => width / height;

  /// Is landscape
  bool get isLandscape => width > height;

  /// Copy with
  PageSize copyWith({double? width, double? height}) {
    return PageSize(
      width: width ?? this.width,
      height: height ?? this.height,
      preset: PagePreset.custom,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'preset': preset?.name,
  };

  factory PageSize.fromJson(Map<String, dynamic> json) {
    final presetName = json['preset'] as String?;
    final preset = presetName != null
        ? PagePreset.values.firstWhere(
            (p) => p.name == presetName,
            orElse: () => PagePreset.custom,
          )
        : null;
    
    return PageSize(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      preset: preset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSize &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}
```

**Test:** `packages/drawing_core/test/models/page_size_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PageSize', () {
    test('should create with custom dimensions', () {
      final size = PageSize(width: 800, height: 600);
      expect(size.width, 800);
      expect(size.height, 600);
      expect(size.isLandscape, true);
    });

    test('should have correct A4 dimensions', () {
      expect(PageSize.a4Portrait.width, 595);
      expect(PageSize.a4Portrait.height, 842);
      expect(PageSize.a4Portrait.preset, PagePreset.a4Portrait);
    });

    test('should calculate aspect ratio', () {
      final size = PageSize(width: 800, height: 400);
      expect(size.aspectRatio, 2.0);
    });

    test('should serialize to JSON', () {
      final json = PageSize.a4Portrait.toJson();
      expect(json['width'], 595);
      expect(json['height'], 842);
      expect(json['preset'], 'a4Portrait');
    });

    test('should deserialize from JSON', () {
      final json = {'width': 595, 'height': 842, 'preset': 'a4Portrait'};
      final size = PageSize.fromJson(json);
      expect(size, PageSize.a4Portrait);
    });

    test('should handle equality', () {
      final size1 = PageSize(width: 100, height: 200);
      final size2 = PageSize(width: 100, height: 200);
      expect(size1, size2);
    });
  });

  group('PagePreset', () {
    test('should have all expected values', () {
      expect(PagePreset.values.length, 5);
      expect(PagePreset.values, contains(PagePreset.a4Portrait));
      expect(PagePreset.values, contains(PagePreset.custom));
    });
  });
}
```

**Checklist:**
```
□ page_size.dart oluşturuldu
□ page_size_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Barrel export'a eklendi (drawing_core.dart)
```

**Rapor formatı:**
```
📁 Files Created:
- packages/drawing_core/lib/src/models/page_size.dart
- packages/drawing_core/test/models/page_size_test.dart

🧪 Tests: 6 passed

📝 Suggested commit: feat(core): add PageSize model with presets

Ready to commit? (y/n) ← İLYAS'TAN ONAY BEKLE
```

---

### Adım 5A-2: PageBackground Model

**Dosya:** `packages/drawing_core/lib/src/models/page_background.dart`

```dart
import 'dart:typed_data';

/// Sayfa arka plan türleri
enum BackgroundType {
  blank,
  grid,
  lined,
  dotted,
  pdf,
}

/// Sayfa arka plan modeli
class PageBackground {
  final BackgroundType type;
  final int color; // ARGB
  final double? gridSpacing;
  final double? lineSpacing;
  final int? lineColor;
  final Uint8List? pdfData;
  final int? pdfPageIndex;

  const PageBackground({
    required this.type,
    this.color = 0xFFFFFFFF, // White default
    this.gridSpacing,
    this.lineSpacing,
    this.lineColor,
    this.pdfData,
    this.pdfPageIndex,
  });

  /// Blank white background
  static const blank = PageBackground(type: BackgroundType.blank);

  /// Grid background (default 20px spacing)
  static const grid = PageBackground(
    type: BackgroundType.grid,
    gridSpacing: 20,
    lineColor: 0xFFE0E0E0,
  );

  /// Lined background (notebook style)
  static const lined = PageBackground(
    type: BackgroundType.lined,
    lineSpacing: 24,
    lineColor: 0xFFE0E0E0,
  );

  /// Dotted background
  static const dotted = PageBackground(
    type: BackgroundType.dotted,
    gridSpacing: 20,
    lineColor: 0xFFCCCCCC,
  );

  /// Create PDF background
  factory PageBackground.pdf({
    required Uint8List pdfData,
    required int pageIndex,
  }) {
    return PageBackground(
      type: BackgroundType.pdf,
      pdfData: pdfData,
      pdfPageIndex: pageIndex,
    );
  }

  /// Copy with
  PageBackground copyWith({
    BackgroundType? type,
    int? color,
    double? gridSpacing,
    double? lineSpacing,
    int? lineColor,
    Uint8List? pdfData,
    int? pdfPageIndex,
  }) {
    return PageBackground(
      type: type ?? this.type,
      color: color ?? this.color,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineColor: lineColor ?? this.lineColor,
      pdfData: pdfData ?? this.pdfData,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
    );
  }

  /// JSON serialization (PDF data excluded for size)
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'color': color,
    if (gridSpacing != null) 'gridSpacing': gridSpacing,
    if (lineSpacing != null) 'lineSpacing': lineSpacing,
    if (lineColor != null) 'lineColor': lineColor,
    if (pdfPageIndex != null) 'pdfPageIndex': pdfPageIndex,
    // pdfData is stored separately
  };

  factory PageBackground.fromJson(Map<String, dynamic> json) {
    return PageBackground(
      type: BackgroundType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BackgroundType.blank,
      ),
      color: json['color'] as int? ?? 0xFFFFFFFF,
      gridSpacing: (json['gridSpacing'] as num?)?.toDouble(),
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble(),
      lineColor: json['lineColor'] as int?,
      pdfPageIndex: json['pdfPageIndex'] as int?,
    );
  }
}
```

**Test:** `packages/drawing_core/test/models/page_background_test.dart`

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PageBackground', () {
    test('should create blank background', () {
      expect(PageBackground.blank.type, BackgroundType.blank);
      expect(PageBackground.blank.color, 0xFFFFFFFF);
    });

    test('should create grid background', () {
      expect(PageBackground.grid.type, BackgroundType.grid);
      expect(PageBackground.grid.gridSpacing, 20);
    });

    test('should create lined background', () {
      expect(PageBackground.lined.type, BackgroundType.lined);
      expect(PageBackground.lined.lineSpacing, 24);
    });

    test('should create PDF background', () {
      final pdfData = Uint8List.fromList([1, 2, 3]);
      final bg = PageBackground.pdf(pdfData: pdfData, pageIndex: 0);
      expect(bg.type, BackgroundType.pdf);
      expect(bg.pdfPageIndex, 0);
      expect(bg.pdfData, pdfData);
    });

    test('should serialize to JSON', () {
      final json = PageBackground.grid.toJson();
      expect(json['type'], 'grid');
      expect(json['gridSpacing'], 20);
    });

    test('should deserialize from JSON', () {
      final json = {'type': 'grid', 'color': 0xFFFFFFFF, 'gridSpacing': 20.0};
      final bg = PageBackground.fromJson(json);
      expect(bg.type, BackgroundType.grid);
      expect(bg.gridSpacing, 20);
    });

    test('should copy with new values', () {
      final bg = PageBackground.grid.copyWith(gridSpacing: 30);
      expect(bg.gridSpacing, 30);
      expect(bg.type, BackgroundType.grid);
    });
  });

  group('BackgroundType', () {
    test('should have all expected values', () {
      expect(BackgroundType.values.length, 5);
    });
  });
}
```

**Checklist:**
```
□ page_background.dart oluşturuldu
□ page_background_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
□ Barrel export'a eklendi
```

---

### Adım 5A-3: Page Model

**Dosya:** `packages/drawing_core/lib/src/models/page.dart`

```dart
import 'dart:typed_data';
import 'package:drawing_core/drawing_core.dart';

/// Tek bir sayfa modeli
class Page {
  final String id;
  final int index;
  final PageSize size;
  final PageBackground background;
  final List<Layer> layers;
  final Uint8List? thumbnail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Page({
    required this.id,
    required this.index,
    required this.size,
    this.background = const PageBackground(type: BackgroundType.blank),
    this.layers = const [],
    this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating new page
  factory Page.create({
    required int index,
    PageSize? size,
    PageBackground? background,
  }) {
    final now = DateTime.now();
    return Page(
      id: 'page_${now.millisecondsSinceEpoch}_$index',
      index: index,
      size: size ?? PageSize.a4Portrait,
      background: background ?? PageBackground.blank,
      layers: [Layer.create()], // Default empty layer
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Total stroke count across all layers
  int get strokeCount => layers.fold(0, (sum, layer) => sum + layer.strokes.length);

  /// Total shape count across all layers
  int get shapeCount => layers.fold(0, (sum, layer) => sum + layer.shapes.length);

  /// Total text count across all layers
  int get textCount => layers.fold(0, (sum, layer) => sum + layer.textElements.length);

  /// Is empty (no content)
  bool get isEmpty => strokeCount == 0 && shapeCount == 0 && textCount == 0;

  /// Active layer (last one)
  Layer get activeLayer => layers.isNotEmpty ? layers.last : Layer.create();

  /// Copy with
  Page copyWith({
    String? id,
    int? index,
    PageSize? size,
    PageBackground? background,
    List<Layer>? layers,
    Uint8List? thumbnail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Page(
      id: id ?? this.id,
      index: index ?? this.index,
      size: size ?? this.size,
      background: background ?? this.background,
      layers: layers ?? this.layers,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add stroke to active layer
  Page addStroke(Stroke stroke) {
    final updatedLayers = List<Layer>.from(layers);
    if (updatedLayers.isEmpty) {
      updatedLayers.add(Layer.create());
    }
    final lastIndex = updatedLayers.length - 1;
    updatedLayers[lastIndex] = updatedLayers[lastIndex].addStroke(stroke);
    return copyWith(layers: updatedLayers);
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'index': index,
    'size': size.toJson(),
    'background': background.toJson(),
    'layers': layers.map((l) => l.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    // thumbnail is stored separately
  };

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      id: json['id'] as String,
      index: json['index'] as int,
      size: PageSize.fromJson(json['size'] as Map<String, dynamic>),
      background: PageBackground.fromJson(json['background'] as Map<String, dynamic>),
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Page && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

**Test:** `packages/drawing_core/test/models/page_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('Page', () {
    test('should create with factory', () {
      final page = Page.create(index: 0);
      expect(page.index, 0);
      expect(page.size, PageSize.a4Portrait);
      expect(page.background.type, BackgroundType.blank);
      expect(page.layers.length, 1);
    });

    test('should create with custom size', () {
      final page = Page.create(
        index: 1,
        size: PageSize.letterLandscape,
        background: PageBackground.grid,
      );
      expect(page.size, PageSize.letterLandscape);
      expect(page.background.type, BackgroundType.grid);
    });

    test('should calculate stroke count', () {
      final stroke = Stroke(
        id: 's1',
        points: [DrawingPoint(x: 0, y: 0)],
        style: StrokeStyle.ballpoint(),
      );
      final page = Page.create(index: 0).addStroke(stroke);
      expect(page.strokeCount, 1);
    });

    test('should detect empty page', () {
      final page = Page.create(index: 0);
      expect(page.isEmpty, true);
    });

    test('should add stroke to active layer', () {
      final stroke = Stroke(
        id: 's1',
        points: [DrawingPoint(x: 0, y: 0)],
        style: StrokeStyle.ballpoint(),
      );
      final page = Page.create(index: 0).addStroke(stroke);
      expect(page.layers.last.strokes.length, 1);
    });

    test('should serialize to JSON', () {
      final page = Page.create(index: 0);
      final json = page.toJson();
      expect(json['index'], 0);
      expect(json['size'], isNotNull);
      expect(json['layers'], isNotEmpty);
    });

    test('should deserialize from JSON', () {
      final page = Page.create(index: 0);
      final json = page.toJson();
      final restored = Page.fromJson(json);
      expect(restored.id, page.id);
      expect(restored.index, page.index);
    });

    test('should copy with new values', () {
      final page = Page.create(index: 0);
      final copied = page.copyWith(index: 5);
      expect(copied.index, 5);
      expect(copied.id, page.id);
    });
  });
}
```

---

### Adım 5A-4 ~ 5A-6: Kalan Adımlar

**Adım 5A-4:** DocumentSettings model  
**Adım 5A-5:** DrawingDocument güncelleme (pages: List<Page>)  
**Adım 5A-6:** Tüm serialization testleri

Her adım için aynı format:
1. Kod yaz
2. Test yaz
3. Analyze çalıştır
4. Test çalıştır
5. İlyas'a rapor ver
6. Onay bekle

---

## ⚠️ BACKWARD COMPATIBILITY KURALI

DrawingDocument güncellenirken ESKİ dokümanlar ÇALIŞMAYA DEVAM ETMELİ:

```dart
// DrawingDocument güncelleme stratejisi
class DrawingDocument {
  // ESKİ field'lar (backward compat için)
  @Deprecated('Use pages instead')
  final List<Layer>? legacyLayers;
  
  // YENİ field
  final List<Page> pages;
  
  factory DrawingDocument.fromJson(Map<String, dynamic> json) {
    // Eski format kontrolü
    if (json.containsKey('layers') && !json.containsKey('pages')) {
      // Legacy format - tek sayfa olarak migrate et
      return _migrateFromLegacy(json);
    }
    // Yeni format
    return _parseNewFormat(json);
  }
}
```

---

## 📋 Commit Mesaj Formatları

```
feat(core): add PageSize model with presets
feat(core): add PageBackground model
feat(core): add Page model with serialization
feat(core): add DocumentSettings model
feat(core): update DrawingDocument for multi-page support
test(core): add comprehensive page model tests

feat(ui): add PageNavigator widget
feat(ui): add PageThumbnail widget
feat(ui): add PageProvider with state management

feat(core): add LRUCache for page management
feat(core): add PageManager with lazy loading

feat(ui): integrate PDF library
feat(core): add PDFLoader service
feat(ui): add PDFImportDialog
feat(ui): add PDFBackgroundPainter

feat(core): add PDFExporter service
feat(ui): add ExportOptionsDialog
```

---

## 🎯 Phase 5A Tamamlandığında

```
□ PageSize model + tests ✅
□ PageBackground model + tests ✅
□ Page model + tests ✅
□ DocumentSettings model + tests ✅
□ DrawingDocument updated (backward compatible) ✅
□ All serialization working ✅
□ Zero analyzer warnings ✅
□ All tests passing ✅
□ İlyas onayı alındı ✅
```

---

*Cursor, bu adımları SIRASI İLE takip et. Acele etme, kalite > hız!*

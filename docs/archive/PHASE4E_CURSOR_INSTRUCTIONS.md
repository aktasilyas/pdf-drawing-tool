# Phase 4E: Cursor Instructions

> **ÖNEMLİ**: Bu dökümanı adım adım takip et. Bir adımı bitirmeden diğerine geçme.
> **KRİTİK**: Mevcut yapıyı BOZMA. Her değişiklik backward compatible olmalı.

---

## 🚨 BAŞLAMADAN ÖNCE

```bash
# 1. Tüm testlerin geçtiğinden emin ol
cd packages/drawing_core && flutter test
cd ../drawing_ui && flutter test

# 2. Analyzer hatası olmadığını kontrol et
melos run analyze

# 3. Branch'te olduğundan emin ol
git branch  # feature/phase4-advanced-features olmalı
```

---

## 📋 MODÜL 4E-1: Pen Types System

### ADIM 4E-1.1: StrokeStyle Genişletme

**GÖREV:** StrokeStyle'a yeni özellikler ekle

**Dosya:** `packages/drawing_core/lib/src/models/stroke_style.dart`

```dart
// YENİ ENUM'LAR EKLE (dosyanın başına)

/// Stroke pattern types for dashed lines.
enum StrokePattern {
  /// Solid continuous line.
  solid,
  
  /// Dashed line pattern.
  dashed,
  
  /// Dotted line pattern.
  dotted,
}

/// Texture types for stroke rendering.
enum StrokeTexture {
  /// No texture, smooth stroke.
  none,
  
  /// Pencil-like grainy texture.
  pencil,
  
  /// Chalk-like rough texture.
  chalk,
  
  /// Watercolor-like soft edges.
  watercolor,
}

// StrokeStyle CLASS'INA YENİ FIELD'LAR EKLE

class StrokeStyle extends Equatable {
  // ... mevcut field'lar ...
  
  /// The pattern of the stroke (solid, dashed, dotted).
  final StrokePattern pattern;
  
  /// The texture of the stroke.
  final StrokeTexture texture;
  
  /// Glow radius for neon effects (0 = no glow).
  final double glowRadius;
  
  /// Glow intensity (0.0 to 1.0).
  final double glowIntensity;
  
  /// Dash pattern [dash length, gap length]. Null for solid.
  final List<double>? dashPattern;
  
  // Constructor'ı güncelle - YENİ parametreleri OPSIYONEL yap (default değerlerle)
  StrokeStyle({
    required this.color,
    required double thickness,
    double opacity = 1.0,
    this.nibShape = NibShape.circle,
    this.blendMode = DrawingBlendMode.normal,
    this.isEraser = false,
    this.pattern = StrokePattern.solid,        // YENİ
    this.texture = StrokeTexture.none,         // YENİ
    double glowRadius = 0.0,                   // YENİ
    double glowIntensity = 0.0,                // YENİ
    this.dashPattern,                          // YENİ
  })  : thickness = thickness.clamp(0.1, 50.0),
        opacity = opacity.clamp(0.0, 1.0),
        glowRadius = glowRadius.clamp(0.0, 20.0),
        glowIntensity = glowIntensity.clamp(0.0, 1.0);

  // props listesine yeni field'ları ekle
  @override
  List<Object?> get props => [
        color,
        thickness,
        opacity,
        nibShape,
        blendMode,
        isEraser,
        pattern,      // YENİ
        texture,      // YENİ
        glowRadius,   // YENİ
        glowIntensity,// YENİ
        dashPattern,  // YENİ
      ];
      
  // copyWith metoduna yeni parametreleri ekle
  // toJson/fromJson metodlarını güncelle
}
```

**TEST:** `packages/drawing_core/test/models/stroke_style_test.dart`

```dart
// Yeni testler ekle:

group('New properties', () {
  test('creates with pattern', () {
    final style = StrokeStyle(
      color: 0xFF000000,
      thickness: 2.0,
      pattern: StrokePattern.dashed,
    );
    expect(style.pattern, StrokePattern.dashed);
  });
  
  test('creates with texture', () {
    final style = StrokeStyle(
      color: 0xFF000000,
      thickness: 2.0,
      texture: StrokeTexture.pencil,
    );
    expect(style.texture, StrokeTexture.pencil);
  });
  
  test('clamps glow values', () {
    final style = StrokeStyle(
      color: 0xFF000000,
      thickness: 2.0,
      glowRadius: 50.0,  // should clamp to 20
      glowIntensity: 2.0, // should clamp to 1.0
    );
    expect(style.glowRadius, 20.0);
    expect(style.glowIntensity, 1.0);
  });
  
  test('dash pattern is nullable', () {
    final solid = StrokeStyle(color: 0xFF000000, thickness: 2.0);
    final dashed = StrokeStyle(
      color: 0xFF000000,
      thickness: 2.0,
      dashPattern: [5.0, 3.0],
    );
    expect(solid.dashPattern, isNull);
    expect(dashed.dashPattern, [5.0, 3.0]);
  });
});

group('JSON with new properties', () {
  test('roundtrip preserves new properties', () {
    final original = StrokeStyle(
      color: 0xFF000000,
      thickness: 2.0,
      pattern: StrokePattern.dashed,
      texture: StrokeTexture.pencil,
      glowRadius: 5.0,
      glowIntensity: 0.5,
      dashPattern: [4.0, 2.0],
    );
    
    final json = original.toJson();
    final restored = StrokeStyle.fromJson(json);
    
    expect(restored, equals(original));
  });
});
```

**CHECKLIST:**
```
□ StrokePattern enum eklendi
□ StrokeTexture enum eklendi
□ StrokeStyle'a 5 yeni field eklendi
□ Constructor güncellendi (backward compatible)
□ props güncellendi
□ copyWith güncellendi
□ toJson güncellendi
□ fromJson güncellendi
□ Testler yazıldı ve geçti
□ flutter analyze: 0 hata
□ Commit: "feat(core): extend StrokeStyle with pattern, texture, glow"
```

---

### ADIM 4E-1.2: PenType Enum Oluştur

**GÖREV:** Kalem tiplerini tanımlayan enum ve konfigürasyon oluştur

**Dosya:** `packages/drawing_core/lib/src/models/pen_type.dart` (YENİ)

```dart
/// Defines all available pen types with their characteristics.
enum PenType {
  /// Matte pencil with slight texture.
  pencil,
  
  /// Hard pencil for sketching, lighter tones.
  hardPencil,
  
  /// Classic ballpoint pen, clean lines.
  ballpointPen,
  
  /// Gel pen, smooth and vibrant colors.
  gelPen,
  
  /// Dashed pen for diagrams and emphasis.
  dashedPen,
  
  /// Semi-transparent highlighter.
  highlighter,
  
  /// Pressure-sensitive brush pen.
  brushPen,
  
  /// Flat marker, opaque and bold.
  marker,
  
  /// Neon highlighter with glow effect.
  neonHighlighter,
}

/// Configuration for each pen type.
class PenTypeConfig {
  final String displayName;
  final String displayNameTr;
  final double defaultThickness;
  final double minThickness;
  final double maxThickness;
  final double defaultOpacity;
  final NibShape nibShape;
  final StrokePattern pattern;
  final StrokeTexture texture;
  final double glowRadius;
  final double glowIntensity;
  final List<double>? dashPattern;
  
  const PenTypeConfig({
    required this.displayName,
    required this.displayNameTr,
    required this.defaultThickness,
    this.minThickness = 0.1,
    this.maxThickness = 20.0,
    this.defaultOpacity = 1.0,
    this.nibShape = NibShape.circle,
    this.pattern = StrokePattern.solid,
    this.texture = StrokeTexture.none,
    this.glowRadius = 0.0,
    this.glowIntensity = 0.0,
    this.dashPattern,
  });
}

/// Extension to get configuration for each pen type.
extension PenTypeExtension on PenType {
  PenTypeConfig get config {
    switch (this) {
      case PenType.pencil:
        return const PenTypeConfig(
          displayName: 'Pencil',
          displayNameTr: 'Kurşun Kalem',
          defaultThickness: 1.5,
          maxThickness: 8.0,
          texture: StrokeTexture.pencil,
          nibShape: NibShape.circle,
        );
        
      case PenType.hardPencil:
        return const PenTypeConfig(
          displayName: 'Hard Pencil',
          displayNameTr: 'Sert Kalem',
          defaultThickness: 1.0,
          maxThickness: 5.0,
          defaultOpacity: 0.7,
          texture: StrokeTexture.pencil,
          nibShape: NibShape.circle,
        );
        
      case PenType.ballpointPen:
        return const PenTypeConfig(
          displayName: 'Ballpoint Pen',
          displayNameTr: 'Tükenmez Kalem',
          defaultThickness: 1.5,
          maxThickness: 5.0,
          nibShape: NibShape.circle,
        );
        
      case PenType.gelPen:
        return const PenTypeConfig(
          displayName: 'Gel Pen',
          displayNameTr: 'Jel Kalem',
          defaultThickness: 2.0,
          maxThickness: 8.0,
          nibShape: NibShape.circle,
        );
        
      case PenType.dashedPen:
        return const PenTypeConfig(
          displayName: 'Dashed Pen',
          displayNameTr: 'Kesik Çizgi',
          defaultThickness: 2.0,
          maxThickness: 8.0,
          pattern: StrokePattern.dashed,
          dashPattern: [8.0, 4.0],
          nibShape: NibShape.circle,
        );
        
      case PenType.highlighter:
        return const PenTypeConfig(
          displayName: 'Highlighter',
          displayNameTr: 'Fosforlu Kalem',
          defaultThickness: 20.0,
          minThickness: 10.0,
          maxThickness: 40.0,
          defaultOpacity: 0.4,
          nibShape: NibShape.rectangle,
        );
        
      case PenType.brushPen:
        return const PenTypeConfig(
          displayName: 'Brush Pen',
          displayNameTr: 'Fırça Kalem',
          defaultThickness: 5.0,
          maxThickness: 30.0,
          nibShape: NibShape.ellipse,
        );
        
      case PenType.marker:
        return const PenTypeConfig(
          displayName: 'Marker',
          displayNameTr: 'Keçeli Kalem',
          defaultThickness: 8.0,
          minThickness: 4.0,
          maxThickness: 20.0,
          nibShape: NibShape.rectangle,
        );
        
      case PenType.neonHighlighter:
        return const PenTypeConfig(
          displayName: 'Neon Highlighter',
          displayNameTr: 'Neon Fosforlu',
          defaultThickness: 15.0,
          minThickness: 8.0,
          maxThickness: 30.0,
          defaultOpacity: 0.8,
          glowRadius: 8.0,
          glowIntensity: 0.6,
          nibShape: NibShape.rectangle,
        );
    }
  }
  
  /// Creates a StrokeStyle from this pen type with given color.
  StrokeStyle toStrokeStyle({
    required int color,
    double? thickness,
  }) {
    final c = config;
    return StrokeStyle(
      color: color,
      thickness: thickness ?? c.defaultThickness,
      opacity: c.defaultOpacity,
      nibShape: c.nibShape,
      pattern: c.pattern,
      texture: c.texture,
      glowRadius: c.glowRadius,
      glowIntensity: c.glowIntensity,
      dashPattern: c.dashPattern,
    );
  }
}
```

**Export ekle:** `packages/drawing_core/lib/drawing_core.dart`

```dart
export 'src/models/pen_type.dart';
```

**CHECKLIST:**
```
□ pen_type.dart oluşturuldu
□ PenType enum (9 tip)
□ PenTypeConfig class
□ PenTypeExtension
□ toStrokeStyle metodu
□ Barrel export eklendi
□ Test dosyası oluşturuldu
□ flutter analyze: 0 hata
□ Commit: "feat(core): add PenType enum with configurations"
```

---

### ADIM 4E-1.3: ToolType Güncelleme

**GÖREV:** UI'daki ToolType enum'unu yeni kalem tipleriyle güncelle

**Dosya:** `packages/drawing_ui/lib/src/models/tool_type.dart`

```dart
// Mevcut pen tiplerini KALDIR ve yenilerini ekle:

enum ToolType {
  // PEN TOOLS (9 tip)
  pencil,
  hardPencil,
  ballpointPen,
  gelPen,
  dashedPen,
  highlighter,
  brushPen,
  marker,
  neonHighlighter,
  
  // ERASER TOOLS
  pixelEraser,
  strokeEraser,
  lassoEraser,
  
  // OTHER TOOLS
  shapes,
  text,
  sticker,
  image,
  selection,
  panZoom,
  laserPointer;
  
  // displayName getter'ı güncelle
  String get displayName {
    switch (this) {
      case ToolType.pencil:
        return 'Kurşun Kalem';
      case ToolType.hardPencil:
        return 'Sert Kalem';
      case ToolType.ballpointPen:
        return 'Tükenmez Kalem';
      case ToolType.gelPen:
        return 'Jel Kalem';
      case ToolType.dashedPen:
        return 'Kesik Çizgi';
      case ToolType.highlighter:
        return 'Fosforlu Kalem';
      case ToolType.brushPen:
        return 'Fırça Kalem';
      case ToolType.marker:
        return 'Keçeli Kalem';
      case ToolType.neonHighlighter:
        return 'Neon Fosforlu';
      // ... diğer case'ler aynı kalır
    }
  }
  
  /// Maps ToolType to PenType for pen tools.
  /// Returns null for non-pen tools.
  PenType? get penType {
    switch (this) {
      case ToolType.pencil:
        return PenType.pencil;
      case ToolType.hardPencil:
        return PenType.hardPencil;
      case ToolType.ballpointPen:
        return PenType.ballpointPen;
      case ToolType.gelPen:
        return PenType.gelPen;
      case ToolType.dashedPen:
        return PenType.dashedPen;
      case ToolType.highlighter:
        return PenType.highlighter;
      case ToolType.brushPen:
        return PenType.brushPen;
      case ToolType.marker:
        return PenType.marker;
      case ToolType.neonHighlighter:
        return PenType.neonHighlighter;
      default:
        return null;
    }
  }
  
  /// Whether this is a pen-type drawing tool.
  bool get isPenTool => penType != null;
}
```

**⚠️ UYARI:** Bu değişiklik BREAKING CHANGE. Aşağıdaki dosyaları da güncelle:
- `tool_style_provider.dart`
- `drawing_providers.dart`
- `pen_settings_panel.dart`
- `drawing_toolbar.dart`

**CHECKLIST:**
```
□ ToolType enum güncellendi
□ displayName güncellendi
□ penType getter eklendi
□ isPenTool getter eklendi
□ Etkilenen dosyalar güncellendi
□ Testler güncellendi
□ flutter analyze: 0 hata
□ Commit: "feat(ui): update ToolType with 9 pen types"
```

---

### ADIM 4E-1.4: Renderer Güncelleme

**GÖREV:** FlutterStrokeRenderer'ı yeni StrokeStyle özelliklerini destekleyecek şekilde güncelle

**Dosya:** `packages/drawing_ui/lib/src/rendering/flutter_stroke_renderer.dart`

```dart
// Yeni metodlar ekle:

/// Builds Paint with pattern support.
Paint _buildPaint(StrokeStyle style) {
  final paint = Paint()
    ..color = Color(style.color).withOpacity(style.opacity)
    ..strokeWidth = style.thickness
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  
  // Glow effect
  if (style.glowRadius > 0) {
    paint.maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      style.glowRadius * style.glowIntensity,
    );
  }
  
  return paint;
}

/// Renders stroke with dash pattern if needed.
void _renderStroke(Canvas canvas, Path path, StrokeStyle style) {
  final paint = _buildPaint(style);
  
  if (style.pattern == StrokePattern.solid || style.dashPattern == null) {
    canvas.drawPath(path, paint);
  } else {
    // Dashed/dotted rendering
    final dashPath = _createDashedPath(path, style.dashPattern!);
    canvas.drawPath(dashPath, paint);
  }
  
  // Texture overlay (pencil effect)
  if (style.texture != StrokeTexture.none) {
    _applyTexture(canvas, path, style);
  }
}

/// Creates a dashed path from continuous path.
Path _createDashedPath(Path source, List<double> pattern) {
  final result = Path();
  final metrics = source.computeMetrics();
  
  for (final metric in metrics) {
    double distance = 0.0;
    bool draw = true;
    int patternIndex = 0;
    
    while (distance < metric.length) {
      final segmentLength = pattern[patternIndex % pattern.length];
      final end = (distance + segmentLength).clamp(0.0, metric.length);
      
      if (draw) {
        final segment = metric.extractPath(distance, end);
        result.addPath(segment, Offset.zero);
      }
      
      distance = end;
      draw = !draw;
      patternIndex++;
    }
  }
  
  return result;
}

/// Applies texture effect to stroke.
void _applyTexture(Canvas canvas, Path path, StrokeStyle style) {
  // Pencil texture: random opacity variations along path
  if (style.texture == StrokeTexture.pencil) {
    // Implementation: draw multiple semi-transparent strokes
    // with slight random offsets
  }
}
```

**CHECKLIST:**
```
□ _buildPaint metodu glow desteği
□ _renderStroke pattern desteği
□ _createDashedPath implementasyonu
□ _applyTexture stub implementasyonu
□ Mevcut render metodları güncellendi
□ Testler eklendi
□ flutter analyze: 0 hata
□ Commit: "feat(ui): add pattern, glow, texture support to renderer"
```

---

## 📋 MODÜL 4E-2: Custom Pen Icons

### ADIM 4E-2.1: PenIconPainter Base Class

**GÖREV:** Kalem ikonları için base CustomPainter oluştur

**Dosya:** `packages/drawing_ui/lib/src/painters/pen_icons/pen_icon_painter.dart` (YENİ)

```dart
import 'package:flutter/material.dart';

/// Base class for all pen icon painters.
///
/// Provides common functionality for rendering pen icons
/// with consistent styling and dimensions.
abstract class PenIconPainter extends CustomPainter {
  /// The color of the pen body.
  final Color bodyColor;
  
  /// The color of the pen tip/nib.
  final Color tipColor;
  
  /// Whether the pen is currently selected.
  final bool isSelected;
  
  /// The size of the icon (width and height).
  final double size;
  
  const PenIconPainter({
    required this.bodyColor,
    required this.tipColor,
    this.isSelected = false,
    this.size = 48.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Selection highlight
    if (isSelected) {
      _paintSelectionHighlight(canvas, rect);
    }
    
    // Pen body
    paintPenBody(canvas, rect);
    
    // Pen tip
    paintPenTip(canvas, rect);
    
    // Details (grip, brand mark, etc.)
    paintDetails(canvas, rect);
  }
  
  /// Override to paint the pen body.
  void paintPenBody(Canvas canvas, Rect rect);
  
  /// Override to paint the pen tip/nib.
  void paintPenTip(Canvas canvas, Rect rect);
  
  /// Override to paint additional details.
  void paintDetails(Canvas canvas, Rect rect) {}
  
  void _paintSelectionHighlight(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final rrect = RRect.fromRectAndRadius(
      rect.inflate(-2),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);
  }
  
  @override
  bool shouldRepaint(covariant PenIconPainter oldDelegate) {
    return oldDelegate.bodyColor != bodyColor ||
           oldDelegate.tipColor != tipColor ||
           oldDelegate.isSelected != isSelected;
  }
}
```

**CHECKLIST:**
```
□ pen_icon_painter.dart oluşturuldu
□ Abstract metodlar tanımlandı
□ Selection highlight implementasyonu
□ shouldRepaint implementasyonu
□ Commit: "feat(ui): add PenIconPainter base class"
```

---

### ADIM 4E-2.2: Concrete Pen Painters

**GÖREV:** Her kalem tipi için CustomPainter oluştur

**Örnek - Pencil:**
**Dosya:** `packages/drawing_ui/lib/src/painters/pen_icons/pencil_icon_painter.dart`

```dart
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

/// Custom painter for pencil icon.
///
/// Draws a classic wooden pencil with hexagonal body,
/// metal ferrule, and sharpened tip.
class PencilIconPainter extends PenIconPainter {
  const PencilIconPainter({
    super.bodyColor = const Color(0xFFF5DEB3), // Wheat/wood color
    super.tipColor = const Color(0xFF2F2F2F),  // Graphite
    super.isSelected = false,
    super.size = 48.0,
  });
  
  @override
  void paintPenBody(Canvas canvas, Rect rect) {
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    
    // Pencil body (slightly angled)
    final path = Path();
    
    // Start from bottom-left
    final startX = rect.left + rect.width * 0.3;
    final startY = rect.bottom - rect.height * 0.15;
    
    // End at top-right
    final endX = rect.right - rect.width * 0.15;
    final endY = rect.top + rect.height * 0.15;
    
    // Body width
    const bodyWidth = 8.0;
    
    // Calculate perpendicular offset for body width
    final dx = endX - startX;
    final dy = endY - startY;
    final length = (dx * dx + dy * dy).sqrt();
    final perpX = -dy / length * bodyWidth / 2;
    final perpY = dx / length * bodyWidth / 2;
    
    path.moveTo(startX + perpX, startY + perpY);
    path.lineTo(endX + perpX, endY + perpY);
    path.lineTo(endX - perpX, endY - perpY);
    path.lineTo(startX - perpX, startY - perpY);
    path.close();
    
    canvas.drawPath(path, bodyPaint);
    
    // Wood grain lines
    final grainPaint = Paint()
      ..color = bodyColor.darken(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw 2-3 grain lines
    for (var i = 0; i < 3; i++) {
      final t = 0.3 + i * 0.2;
      final grainPath = Path();
      final gx = startX + dx * t;
      final gy = startY + dy * t;
      grainPath.moveTo(gx + perpX * 0.8, gy + perpY * 0.8);
      grainPath.lineTo(gx - perpX * 0.8, gy - perpY * 0.8);
      canvas.drawPath(grainPath, grainPaint);
    }
  }
  
  @override
  void paintPenTip(Canvas canvas, Rect rect) {
    final tipPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;
    
    // Sharpened tip (triangle)
    final tipPath = Path();
    
    final startX = rect.left + rect.width * 0.3;
    final startY = rect.bottom - rect.height * 0.15;
    
    // Tip point
    final tipX = rect.left + rect.width * 0.15;
    final tipY = rect.bottom - rect.height * 0.05;
    
    // Body width for tip base
    const bodyWidth = 8.0;
    
    final dx = startX - tipX;
    final dy = startY - tipY;
    final length = (dx * dx + dy * dy).sqrt();
    final perpX = -dy / length * bodyWidth / 2;
    final perpY = dx / length * bodyWidth / 2;
    
    tipPath.moveTo(tipX, tipY);
    tipPath.lineTo(startX + perpX, startY + perpY);
    tipPath.lineTo(startX - perpX, startY - perpY);
    tipPath.close();
    
    canvas.drawPath(tipPath, tipPaint);
    
    // Wood cone around graphite
    final woodPaint = Paint()
      ..color = const Color(0xFFDEB887) // Lighter wood
      ..style = PaintingStyle.fill;
    
    final woodPath = Path();
    final midX = (tipX + startX) / 2;
    final midY = (tipY + startY) / 2;
    
    woodPath.moveTo(midX, midY);
    woodPath.lineTo(startX + perpX, startY + perpY);
    woodPath.lineTo(startX - perpX, startY - perpY);
    woodPath.close();
    
    canvas.drawPath(woodPath, woodPaint);
  }
  
  @override
  void paintDetails(Canvas canvas, Rect rect) {
    // Metal ferrule (eraser holder)
    final ferrulePaint = Paint()
      ..color = const Color(0xFFB8860B) // Gold/brass
      ..style = PaintingStyle.fill;
    
    final endX = rect.right - rect.width * 0.15;
    final endY = rect.top + rect.height * 0.15;
    
    // Small rectangle at the end
    final ferruleRect = Rect.fromCenter(
      center: Offset(endX, endY),
      width: 10,
      height: 6,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(ferruleRect, const Radius.circular(1)),
      ferrulePaint,
    );
    
    // Pink eraser
    final eraserPaint = Paint()
      ..color = const Color(0xFFFFB6C1) // Light pink
      ..style = PaintingStyle.fill;
    
    final eraserRect = Rect.fromLTWH(
      endX + 3,
      endY - 2.5,
      6,
      5,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      eraserPaint,
    );
  }
}

extension _ColorExtension on Color {
  Color darken(double amount) {
    return Color.fromARGB(
      alpha,
      (red * (1 - amount)).round().clamp(0, 255),
      (green * (1 - amount)).round().clamp(0, 255),
      (blue * (1 - amount)).round().clamp(0, 255),
    );
  }
}
```

**Diğer Painterlar için Dosyalar:**
- `ballpoint_icon_painter.dart` - Tükenmez kalem (metal body, tıklama butonu)
- `gel_pen_icon_painter.dart` - Jel kalem (şeffaf body, renkli mürekkep)
- `highlighter_icon_painter.dart` - Fosforlu (geniş, yuvarlak uç)
- `marker_icon_painter.dart` - Keçeli (dikdörtgen body, düz uç)
- `brush_icon_painter.dart` - Fırça (ince body, kıl ucu)
- `dashed_pen_icon_painter.dart` - Kesik çizgi (normal kalem + dash indicator)
- `neon_icon_painter.dart` - Neon (glow efekti)
- `hard_pencil_icon_painter.dart` - Sert kalem (daha açık renk pencil)

**CHECKLIST:**
```
□ pencil_icon_painter.dart
□ ballpoint_icon_painter.dart
□ gel_pen_icon_painter.dart
□ highlighter_icon_painter.dart
□ marker_icon_painter.dart
□ brush_icon_painter.dart
□ dashed_pen_icon_painter.dart
□ neon_icon_painter.dart
□ hard_pencil_icon_painter.dart
□ Barrel export (pen_icons.dart)
□ Testler yazıldı
□ Commit: "feat(ui): add custom pen icon painters"
```

---

### ADIM 4E-2.3: PenIconWidget

**GÖREV:** Painter'ları kullanacak widget oluştur

**Dosya:** `packages/drawing_ui/lib/src/widgets/pen_icon_widget.dart` (YENİ)

```dart
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import '../painters/pen_icons/pen_icons.dart';

/// Widget that displays a pen icon based on pen type.
class PenIconWidget extends StatelessWidget {
  /// The type of pen to display.
  final PenType penType;
  
  /// The color of the pen (for tip and accents).
  final Color color;
  
  /// Whether the pen is currently selected.
  final bool isSelected;
  
  /// The size of the icon.
  final double size;
  
  const PenIconWidget({
    super.key,
    required this.penType,
    this.color = Colors.black,
    this.isSelected = false,
    this.size = 48.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _getPainter(),
    );
  }
  
  PenIconPainter _getPainter() {
    switch (penType) {
      case PenType.pencil:
        return PencilIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.hardPencil:
        return HardPencilIconPainter(
          tipColor: color.withOpacity(0.6),
          isSelected: isSelected,
          size: size,
        );
      case PenType.ballpointPen:
        return BallpointIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.gelPen:
        return GelPenIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.dashedPen:
        return DashedPenIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.highlighter:
        return HighlighterIconPainter(
          bodyColor: color.withOpacity(0.7),
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.brushPen:
        return BrushIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.marker:
        return MarkerIconPainter(
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
      case PenType.neonHighlighter:
        return NeonIconPainter(
          bodyColor: color,
          tipColor: color,
          isSelected: isSelected,
          size: size,
        );
    }
  }
}
```

**CHECKLIST:**
```
□ pen_icon_widget.dart oluşturuldu
□ Tüm pen tipleri destekleniyor
□ Color ve selection desteği
□ Test yazıldı
□ Commit: "feat(ui): add PenIconWidget"
```

---

## 📋 MODÜL 4E-3: Eraser Modes Completion

### ADIM 4E-3.1: PixelEraser Implementation

**GÖREV:** Piksel silme mantığını implemente et

**Dosya:** `packages/drawing_core/lib/src/tools/pixel_eraser_tool.dart` (YENİ)

```dart
import 'package:drawing_core/src/internal.dart';

/// Pixel eraser tool that removes parts of strokes.
///
/// Unlike stroke eraser which removes entire strokes,
/// pixel eraser splits strokes at intersection points.
class PixelEraserTool {
  final double size;
  final List<DrawingPoint> _eraserPath = [];
  
  PixelEraserTool({this.size = 20.0});
  
  void onPointerDown(DrawingPoint point) {
    _eraserPath.clear();
    _eraserPath.add(point);
  }
  
  void onPointerMove(DrawingPoint point) {
    _eraserPath.add(point);
  }
  
  /// Returns list of strokes after erasing.
  /// 
  /// [strokes] - original strokes
  /// Returns modified strokes list (some split, some removed)
  List<Stroke> onPointerUp(List<Stroke> strokes) {
    if (_eraserPath.isEmpty) return strokes;
    
    final eraserBounds = _calculateEraserBounds();
    final result = <Stroke>[];
    
    for (final stroke in strokes) {
      // Quick bounds check
      if (!stroke.boundingBox.intersects(eraserBounds)) {
        result.add(stroke);
        continue;
      }
      
      // Detailed intersection check
      final splitStrokes = _splitStroke(stroke);
      result.addAll(splitStrokes);
    }
    
    _eraserPath.clear();
    return result;
  }
  
  BoundingBox _calculateEraserBounds() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final point in _eraserPath) {
      minX = minX < point.x - size ? minX : point.x - size;
      minY = minY < point.y - size ? minY : point.y - size;
      maxX = maxX > point.x + size ? maxX : point.x + size;
      maxY = maxY > point.y + size ? maxY : point.y + size;
    }
    
    return BoundingBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
  
  List<Stroke> _splitStroke(Stroke stroke) {
    // Find intersection segments
    final keepSegments = <List<DrawingPoint>>[];
    var currentSegment = <DrawingPoint>[];
    
    for (final point in stroke.points) {
      if (_isPointErased(point)) {
        // Point is erased
        if (currentSegment.length >= 2) {
          keepSegments.add(currentSegment);
        }
        currentSegment = [];
      } else {
        // Point is kept
        currentSegment.add(point);
      }
    }
    
    // Don't forget last segment
    if (currentSegment.length >= 2) {
      keepSegments.add(currentSegment);
    }
    
    // Convert segments back to strokes
    return keepSegments.map((points) {
      return Stroke.create(
        style: stroke.style,
        points: points,
      );
    }).toList();
  }
  
  bool _isPointErased(DrawingPoint point) {
    for (final eraserPoint in _eraserPath) {
      final dx = point.x - eraserPoint.x;
      final dy = point.y - eraserPoint.y;
      final distance = (dx * dx + dy * dy).sqrt();
      
      if (distance <= size / 2) {
        return true;
      }
    }
    return false;
  }
}
```

**CHECKLIST:**
```
□ pixel_eraser_tool.dart oluşturuldu
□ Bounds check implementasyonu
□ Stroke splitting implementasyonu
□ Testler yazıldı
□ Commit: "feat(core): implement PixelEraserTool"
```

---

### ADIM 4E-3.2: Eraser Cursor Painter

**GÖREV:** Canvas üzerinde silgi ikonunu gösteren painter

**Dosya:** `packages/drawing_ui/lib/src/painters/eraser_cursor_painter.dart` (YENİ)

```dart
import 'package:flutter/material.dart';

/// Paints an eraser cursor indicator on the canvas.
class EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double size;
  final bool isPixelMode;
  
  EraserCursorPainter({
    required this.position,
    required this.size,
    this.isPixelMode = true,
  });
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (position == Offset.zero) return;
    
    // Outer circle (eraser area)
    final outerPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, size / 2, outerPaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(position, size / 2, borderPaint);
    
    // Center crosshair for precision
    if (isPixelMode) {
      final crossPaint = Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      const crossSize = 6.0;
      canvas.drawLine(
        Offset(position.dx - crossSize, position.dy),
        Offset(position.dx + crossSize, position.dy),
        crossPaint,
      );
      canvas.drawLine(
        Offset(position.dx, position.dy - crossSize),
        Offset(position.dx, position.dy + crossSize),
        crossPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.size != size ||
           oldDelegate.isPixelMode != isPixelMode;
  }
}
```

**CHECKLIST:**
```
□ eraser_cursor_painter.dart oluşturuldu
□ Circle + border rendering
□ Crosshair for pixel mode
□ DrawingCanvas entegrasyonu
□ Commit: "feat(ui): add EraserCursorPainter"
```

---

## 📋 MODÜL 4E-4: Advanced Color Picker

### ADIM 4E-4.1: HSV Color Wheel

**GÖREV:** HSV renk seçici widget'ı oluştur

**Dosya:** `packages/drawing_ui/lib/src/widgets/color_picker/hsv_color_wheel.dart` (YENİ)

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular HSV color picker wheel.
class HSVColorWheel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final double size;
  
  const HSVColorWheel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.size = 200.0,
  });
  
  @override
  State<HSVColorWheel> createState() => _HSVColorWheelState();
}

class _HSVColorWheelState extends State<HSVColorWheel> {
  late HSVColor _currentHSV;
  
  @override
  void initState() {
    super.initState();
    _currentHSV = HSVColor.fromColor(widget.initialColor);
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: _handlePan,
        onPanUpdate: _handlePan,
        child: CustomPaint(
          painter: _HSVWheelPainter(
            currentHSV: _currentHSV,
          ),
          size: Size(widget.size, widget.size),
        ),
      ),
    );
  }
  
  void _handlePan(DragUpdateDetails details) {
    // ... hue selection from angle
  }
}

class _HSVWheelPainter extends CustomPainter {
  final HSVColor currentHSV;
  
  _HSVWheelPainter({required this.currentHSV});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw hue wheel
    for (var i = 0; i < 360; i++) {
      final paint = Paint()
        ..color = HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      
      final startAngle = (i - 90) * math.pi / 180;
      final sweepAngle = math.pi / 180;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
    
    // Draw saturation/brightness triangle or square in center
    // ... implementation
  }
  
  @override
  bool shouldRepaint(covariant _HSVWheelPainter oldDelegate) {
    return oldDelegate.currentHSV != currentHSV;
  }
}
```

---

### ADIM 4E-4.2: Color Picker Panel

**GÖREV:** Tam color picker panel'i

**Dosya:** `packages/drawing_ui/lib/src/panels/advanced_color_picker_panel.dart` (YENİ)

```dart
import 'package:flutter/material.dart';
import '../widgets/color_picker/hsv_color_wheel.dart';

/// Advanced color picker with wheel, palettes, and hex input.
class AdvancedColorPickerPanel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  
  const AdvancedColorPickerPanel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });
  
  @override
  State<AdvancedColorPickerPanel> createState() => _AdvancedColorPickerPanelState();
}

class _AdvancedColorPickerPanelState extends State<AdvancedColorPickerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _currentColor;
  final _hexController = TextEditingController();
  
  // Preset palettes
  static const _basicColors = [
    Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFFFF0000),
    Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFFFFFF00),
    Color(0xFFFF00FF), Color(0xFF00FFFF), Color(0xFFFFA500),
    Color(0xFF800080), Color(0xFF008000), Color(0xFF000080),
  ];
  
  static const _pastelColors = [
    Color(0xFFFFB3BA), Color(0xFFFFDFBA), Color(0xFFFFFFBA),
    Color(0xFFBAFFB3), Color(0xFFBAFFFF), Color(0xFFBAB3FF),
    Color(0xFFFFBAFF), Color(0xFFE8D0A9), Color(0xFFB8E0D2),
    Color(0xFFD6CDEA), Color(0xFFF5E6CC), Color(0xFFCCE5FF),
  ];
  
  static const _neonColors = [
    Color(0xFFFF0080), Color(0xFF00FF80), Color(0xFF80FF00),
    Color(0xFFFF8000), Color(0xFF0080FF), Color(0xFF8000FF),
    Color(0xFFFF00FF), Color(0xFF00FFFF), Color(0xFFFFFF00),
    Color(0xFF00FF00), Color(0xFFFF0000), Color(0xFF0000FF),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentColor = widget.initialColor;
    _updateHexField();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current color preview
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tabs: Wheel, Palettes, Hex
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Tekerlek'),
              Tab(text: 'Paletler'),
              Tab(text: 'Hex'),
            ],
          ),
          
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                // HSV Wheel
                Center(
                  child: HSVColorWheel(
                    initialColor: _currentColor,
                    onColorChanged: _handleColorChanged,
                    size: 180,
                  ),
                ),
                
                // Palettes
                _buildPalettes(),
                
                // Hex Input
                _buildHexInput(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent colors
          _buildRecentColors(),
        ],
      ),
    );
  }
  
  Widget _buildPalettes() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaletteSection('Temel', _basicColors),
          _buildPaletteSection('Pastel', _pastelColors),
          _buildPaletteSection('Neon', _neonColors),
        ],
      ),
    );
  }
  
  Widget _buildPaletteSection(String title, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) => _buildColorChip(color)).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorChip(Color color) {
    final isSelected = color.value == _currentColor.value;
    return GestureDetector(
      onTap: () => _handleColorChanged(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }
  
  Widget _buildHexInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _hexController,
            decoration: const InputDecoration(
              labelText: 'Hex Renk',
              prefixText: '#',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _handleHexSubmit,
          ),
          const SizedBox(height: 16),
          // RGB sliders could go here
        ],
      ),
    );
  }
  
  Widget _buildRecentColors() {
    // TODO: Load from preferences
    return const SizedBox.shrink();
  }
  
  void _handleColorChanged(Color color) {
    setState(() => _currentColor = color);
    _updateHexField();
    widget.onColorChanged(color);
  }
  
  void _updateHexField() {
    _hexController.text = _currentColor.value
        .toRadixString(16)
        .substring(2)
        .toUpperCase();
  }
  
  void _handleHexSubmit(String hex) {
    try {
      final color = Color(int.parse('FF$hex', radix: 16));
      _handleColorChanged(color);
    } catch (_) {
      // Invalid hex
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    super.dispose();
  }
}
```

**CHECKLIST:**
```
□ hsv_color_wheel.dart
□ advanced_color_picker_panel.dart
□ 3 preset palette (basic, pastel, neon)
□ Hex input
□ Recent colors (stub)
□ Entegrasyon (pen settings panel)
□ Testler
□ Commit: "feat(ui): add AdvancedColorPickerPanel"
```

---

## 📋 MODÜL 4E-5, 4E-6, 4E-7

(Detaylı talimatlar ayrı dosyada devam edecek)

---

## ✅ Commit Format

```bash
# Core package
feat(core): description
fix(core): description

# UI package
feat(ui): description
fix(ui): description

# Multiple packages
feat(core,ui): description

# Refactoring
refactor(core): description
refactor(ui): description
```

---

## 🚨 KRİTİK HATIRLATMALAR

1. **MEVCUT YAPIYI BOZMA**: Yeni özellikler backward compatible olmalı
2. **TESTLER ÖNCE**: Değişiklik yapmadan önce mevcut testler geçmeli
3. **INCREMENTAL**: Küçük adımlarla ilerle, her adımda commit
4. **PERFORMANCE**: Yeni özellikler 60 FPS'i etkilememeli
5. **BARREL EXPORTS**: Yeni dosyalar için export eklemeyi unutma

---

*Her adımı tamamladıktan sonra CHECKLIST'i işaretle ve commit yap!*

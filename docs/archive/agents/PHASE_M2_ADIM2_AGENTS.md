# PHASE M2 — ADIM 2/3: Painter'ları CanvasColorScheme ile Güncelle

## ÖZET
Tüm canvas painter'larına opsiyonel CanvasColorScheme parametresi ekle. Scheme varsa renkleri override et, yoksa mevcut davranış korunsun.

## BRANCH
```bash
git checkout feature/canvas-dark-mode
```

---

## MİMARİ KARAR

Her painter'a `CanvasColorScheme? colorScheme` parametresi ekliyoruz. Null olduğunda mevcut hardcoded renkler kullanılır (backward compat). Dolu olduğunda scheme'den gelen renkler kullanılır. Bu sayede mevcut tüm testler ve kullanımlar bozulmaz.

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/canvas/canvas_color_scheme.dart — Adım 1'de oluşturuldu
- packages/drawing_ui/lib/src/canvas/drawing_canvas_painters.dart — DynamicBackgroundPainter
- packages/drawing_ui/lib/src/canvas/infinite_background_painter.dart — InfiniteBackgroundPainter
- packages/drawing_ui/lib/src/canvas/page_background_painter.dart — PageBackgroundPatternPainter
- packages/drawing_ui/lib/src/painters/template_pattern_painter.dart — TemplatePatternPainter
- packages/drawing_ui/lib/src/services/thumbnail_generator.dart — _renderPageBackground

**1) GÜNCELLE: `drawing_canvas_painters.dart` — DynamicBackgroundPainter**

```dart
class DynamicBackgroundPainter extends CustomPainter {
  final PageBackground background;
  final ui.Image? pdfImage;
  final CanvasColorScheme? colorScheme; // YENİ

  const DynamicBackgroundPainter({
    required this.background,
    this.pdfImage,
    this.colorScheme, // YENİ
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background color: scheme varsa effective, yoksa mevcut
    final bgColor = colorScheme?.effectiveBackground(background.color)
        ?? Color(background.color);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Line color: scheme varsa effective, yoksa mevcut
    final lineColor = colorScheme?.effectiveLineColor(background.lineColor)
        ?? Color(background.lineColor ?? 0xFFE0E0E0);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    // ... switch case'ler aynen kalır, sadece linePaint kullanılır ...

    // Dotted case'te:
    // final dotColor = colorScheme?.effectiveDotColor(background.lineColor)
    //     ?? Color(background.lineColor ?? 0xFFCCCCCC);

    // Template case'te TemplatePatternPainter'a da colorScheme geç:
    // TemplatePatternPainter(
    //   ...
    //   lineColor: lineColor, // scheme'den gelen renk
    //   backgroundColor: Colors.transparent,
    //   ...
    // )
  }

  @override
  bool shouldRepaint(covariant DynamicBackgroundPainter oldDelegate) {
    return oldDelegate.background != background
        || oldDelegate.pdfImage != pdfImage
        || oldDelegate.colorScheme != oldDelegate.colorScheme; // YENİ
  }
}
```

**2) GÜNCELLE: `infinite_background_painter.dart` — InfiniteBackgroundPainter**

Aynı pattern: `CanvasColorScheme? colorScheme` parametresi ekle. paint() içinde bgColor ve lineColor hesaplamalarını scheme ile yap. shouldRepaint'e colorScheme ekle.

```dart
class InfiniteBackgroundPainter extends CustomPainter {
  final PageBackground background;
  final double zoom;
  final Offset offset;
  final CanvasColorScheme? colorScheme; // YENİ

  const InfiniteBackgroundPainter({
    required this.background,
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.colorScheme, // YENİ
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = colorScheme?.effectiveBackground(background.color)
        ?? Color(background.color);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final lineColor = colorScheme?.effectiveLineColor(background.lineColor)
        ?? Color(background.lineColor ?? 0xFFE0E0E0);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    // ... mevcut switch case'ler lineColor/linePaint kullanır ...
  }
}
```

**3) GÜNCELLE: `page_background_painter.dart` — PageBackgroundPatternPainter**

Aynı pattern. colorScheme parametresi ekle, paint() içinde kullan.

**4) GÜNCELLE: `template_pattern_painter.dart`**

TemplatePatternPainter'ın lineColor ve backgroundColor parametreleri zaten var, dışarıdan geçiliyor. Bu dosyaya dokunmaya gerek yok — çağıran painter'lar scheme'den gelen rengi lineColor olarak geçiyor.

**5) GÜNCELLE: DrawingCanvas — painter'lara colorScheme geç**

`packages/drawing_ui/lib/src/canvas/drawing_canvas.dart` veya canvas'ı oluşturan widget'ta:

```dart
// DynamicBackgroundPainter veya InfiniteBackgroundPainter oluştururken:
final colorScheme = ref.watch(canvasColorSchemeProvider);

DynamicBackgroundPainter(
  background: page.background,
  pdfImage: pdfImage,
  colorScheme: colorScheme, // YENİ
)

// veya
InfiniteBackgroundPainter(
  background: page.background,
  zoom: zoom,
  offset: offset,
  colorScheme: colorScheme, // YENİ
)
```

Canvas widget'ı ConsumerWidget veya ConsumerStatefulWidget ise direkt `ref.watch(canvasColorSchemeProvider)` kullan. Değilse, DrawingScreen'den parametre olarak geç.

**6) GÜNCELLE: `drawing_screen_layout.dart` — buildDrawingCanvasArea**

buildDrawingCanvasArea fonksiyonuna colorScheme parametresi ekle ve canvas widget'ına geçir. DrawingScreen'de `ref.watch(canvasColorSchemeProvider)` ile al.

**7) thumbnail_generator.dart — DOKUNMA**

Thumbnail'lar her zaman light scheme ile render edilsin (doküman renkleri korunsun). Bu dosyaya colorScheme ekleme.

**8) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- Tüm mevcut painter constructor'ları backward compatible kalmalı (colorScheme opsiyonel)
- CanvasColorScheme import'u: `import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';`
- Mevcut testler bozulmamalı (colorScheme null = eski davranış)
- drawing_core'a DOKUNMA
- shouldRepaint'e colorScheme karşılaştırması ekle
- thumbnail_generator.dart'a DOKUNMA

---

### 🧪 @qa-engineer — Test

**Yeni test: `packages/drawing_ui/test/canvas_dark_mode_painters_test.dart`**

```dart
void main() {
  group('DynamicBackgroundPainter with colorScheme', () {
    test('uses scheme background for default white page', () {
      final scheme = CanvasColorScheme.dark();
      final painter = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF),
        colorScheme: scheme,
      );
      // painter.colorScheme'in background'u dark olmalı
      expect(painter.colorScheme?.background, scheme.background);
    });

    test('null colorScheme preserves original behavior', () {
      final painter = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF),
      );
      expect(painter.colorScheme, isNull);
    });

    test('shouldRepaint returns true when colorScheme changes', () {
      final old = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF),
        colorScheme: CanvasColorScheme.light(),
      );
      final current = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF),
        colorScheme: CanvasColorScheme.dark(),
      );
      expect(current.shouldRepaint(old), isTrue);
    });
  });

  group('InfiniteBackgroundPainter with colorScheme', () {
    // Aynı pattern testler
  });
}
```

---

### 🔍 @code-reviewer — Review

1. Tüm painter'larda colorScheme opsiyonel ve backward compatible
2. effectiveBackground/effectiveLineColor/effectiveDotColor doğru kullanılıyor
3. shouldRepaint colorScheme karşılaştırması var
4. DrawingCanvas → painter'lara ref.watch(canvasColorSchemeProvider) geçiliyor
5. thumbnail_generator.dart dokunulmamış
6. drawing_core dokunulmamış
7. Mevcut testler pass

---

## COMMIT
```
feat(canvas): integrate CanvasColorScheme into all background painters

- Add colorScheme parameter to DynamicBackgroundPainter
- Add colorScheme parameter to InfiniteBackgroundPainter
- Add colorScheme parameter to PageBackgroundPatternPainter
- Wire canvasColorSchemeProvider through DrawingCanvas
- Backward compatible: null colorScheme = original behavior
- Thumbnails always use document colors (no dark mode)
```

## SONRAKİ ADIM
Adım 3: Settings UI + DrawingScreen platformBrightness entegrasyonu + test

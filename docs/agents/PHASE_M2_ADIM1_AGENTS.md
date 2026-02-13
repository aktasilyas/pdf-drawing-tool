# PHASE M2 — ADIM 1/3: CanvasColorScheme Model + Provider + Settings

## ÖZET
Canvas dark mode altyapısını kur. CanvasColorScheme modeli, CanvasDarkMode provider, ve Settings ekranında "Canvas Teması" seçeneği.

## BRANCH
```bash
git checkout -b feature/canvas-dark-mode
```

---

## MİMARİ KARAR

Canvas dark mode'u iki seviyede çalışır:

**Seviye 1 — Semantic Renk Eşleme:** Canvas arka plan rengi, grid/çizgi/nokta renkleri tema ile değişir. Beyaz kağıt → koyu gri, açık gri çizgiler → koyu gri çizgiler. Bu yaklaşım her bileşeni kontrol altında tutar.

**Seviye 2 — Stroke Renkleri:** Kullanıcının çizdiği stroke'lar DEĞİŞMEZ. Siyah kalemle yazılan yazı dark canvas'ta siyah kalır — bu bilinçli bir karar. Kullanıcı isterse beyaz kalem seçebilir. Notability de böyle yapıyor ama opsiyonel "ink inversion" sunuyor — bunu M2+ olarak ileride ekleriz.

**Yaklaşım:** PageBackground'daki `color` ve `lineColor` alanlarını değiştirmiyoruz (model katmanına dokunmuyoruz). Bunun yerine painter seviyesinde CanvasColorScheme'den gelen renkleri override olarak kullanıyoruz. Bu şekilde kayıtlı dokümanlar etkilenmez, sadece görüntüleme değişir.

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/canvas/drawing_canvas_painters.dart — DynamicBackgroundPainter
- packages/drawing_ui/lib/src/canvas/infinite_background_painter.dart — InfiniteBackgroundPainter
- packages/drawing_ui/lib/src/painters/template_pattern_painter.dart — TemplatePatternPainter
- packages/drawing_core/lib/src/models/page_background.dart — PageBackground model
- docs/agents/GOODNOTES_UI_REFERENCE.md — dark mode referansı

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/canvas/canvas_color_scheme.dart`**

Canvas renklerini tema bazlı tanımlayan immutable model.

```dart
import 'package:flutter/material.dart';

/// Color scheme for canvas rendering in different theme modes.
///
/// Controls background, pattern lines, dots, and other canvas visual elements.
/// Does NOT affect user-drawn stroke colors — those are preserved as-is.
class CanvasColorScheme {
  const CanvasColorScheme({
    required this.background,
    required this.patternLine,
    required this.patternDot,
    required this.rulerMark,
    required this.selectionHighlight,
    required this.marginLine,
  });

  /// Canvas background color (replaces PageBackground.color at render time).
  final Color background;

  /// Grid and line pattern color.
  final Color patternLine;

  /// Dot pattern color.
  final Color patternDot;

  /// Ruler marks and margin lines.
  final Color rulerMark;

  /// Selection/lasso highlight overlay.
  final Color selectionHighlight;

  /// Special margin lines (Cornell notes, legal pad etc.)
  final Color marginLine;

  /// Light theme — default white paper.
  factory CanvasColorScheme.light() => const CanvasColorScheme(
    background: Color(0xFFFFFFFF),
    patternLine: Color(0xFFE0E0E0),
    patternDot: Color(0xFFD0D0D0),
    rulerMark: Color(0xFFBDBDBD),
    selectionHighlight: Color(0x332196F3),
    marginLine: Color(0xFFE57373),
  );

  /// Dark theme — dark gray paper.
  factory CanvasColorScheme.dark() => const CanvasColorScheme(
    background: Color(0xFF2C2C2C),
    patternLine: Color(0xFF4A4A4A),
    patternDot: Color(0xFF505050),
    rulerMark: Color(0xFF5A5A5A),
    selectionHighlight: Color(0x3364B5F6),
    marginLine: Color(0xFFEF9A9A),
  );

  /// Sepia/warm theme — opsiyonel gelecek eklenti.
  factory CanvasColorScheme.sepia() => const CanvasColorScheme(
    background: Color(0xFFF5F0E8),
    patternLine: Color(0xFFD5C9B5),
    patternDot: Color(0xFFCBC0AC),
    rulerMark: Color(0xFFC0B49E),
    selectionHighlight: Color(0x338D6E63),
    marginLine: Color(0xFFBF7B5E),
  );

  /// Returns the effective background color for a given PageBackground.
  /// If PageBackground has a custom color (not default white), respect it.
  /// Otherwise use the scheme's background.
  Color effectiveBackground(int pageBackgroundColor) {
    // Default white = 0xFFFFFFFF
    if (pageBackgroundColor == 0xFFFFFFFF) {
      return background;
    }
    // User set a custom color — respect it (don't override)
    return Color(pageBackgroundColor);
  }

  /// Returns the effective line color for a given PageBackground.
  Color effectiveLineColor(int? pageLineColor) {
    // Default line color = 0xFFE0E0E0
    if (pageLineColor == null || pageLineColor == 0xFFE0E0E0) {
      return patternLine;
    }
    // User set a custom line color — respect it
    return Color(pageLineColor);
  }
}
```

**2) YENİ DOSYA: `packages/drawing_ui/lib/src/providers/canvas_dark_mode_provider.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';

/// Canvas dark mode setting.
enum CanvasDarkMode {
  /// Always light canvas (default — current behavior).
  off,

  /// Always dark canvas.
  on,

  /// Follow system theme.
  followSystem,
}

/// Persisted canvas dark mode setting.
/// Saved to SharedPreferences as 'canvas_dark_mode'.
final canvasDarkModeProvider = StateProvider<CanvasDarkMode>((ref) {
  return CanvasDarkMode.off;
});

/// Resolved canvas color scheme based on dark mode setting + system brightness.
final canvasColorSchemeProvider = Provider<CanvasColorScheme>((ref) {
  final mode = ref.watch(canvasDarkModeProvider);

  switch (mode) {
    case CanvasDarkMode.off:
      return CanvasColorScheme.light();
    case CanvasDarkMode.on:
      return CanvasColorScheme.dark();
    case CanvasDarkMode.followSystem:
      // Bu provider'ı DrawingScreen build() içinde
      // platformBrightness'a göre override etmemiz lazım.
      // Şimdilik light döndür, Adım 3'te entegre edilecek.
      return CanvasColorScheme.light();
  }
});
```

**ÖNEMLİ:** `followSystem` modu için system brightness'ı okumak lazım. Bu DrawingScreen tarafında yapılacak (Adım 3). Provider'da `WidgetsBinding.instance.platformDispatcher.platformBrightness` kullanılabilir ama en temiz çözüm DrawingScreen'de `MediaQuery.platformBrightnessOf(context)` ile override etmek.

Daha temiz yaklaşım — brightness'ı da provider yapın:

```dart
/// System brightness provider — DrawingScreen'de override edilir.
final platformBrightnessProvider = StateProvider<Brightness>((ref) {
  return Brightness.light;
});

/// Resolved canvas color scheme.
final canvasColorSchemeProvider = Provider<CanvasColorScheme>((ref) {
  final mode = ref.watch(canvasDarkModeProvider);
  final brightness = ref.watch(platformBrightnessProvider);

  switch (mode) {
    case CanvasDarkMode.off:
      return CanvasColorScheme.light();
    case CanvasDarkMode.on:
      return CanvasColorScheme.dark();
    case CanvasDarkMode.followSystem:
      return brightness == Brightness.dark
          ? CanvasColorScheme.dark()
          : CanvasColorScheme.light();
  }
});
```

**3) GÜNCELLE: SharedPreferences entegrasyonu**

Mevcut settings provider pattern'ını takip et. `canvasDarkModeProvider`'ı SharedPreferences ile persist et. Mevcut `toolbarConfigProvider` nasıl yapıyorsa aynı pattern:

```dart
// Settings load sırasında:
final savedMode = prefs.getString('canvas_dark_mode') ?? 'off';
ref.read(canvasDarkModeProvider.notifier).state = CanvasDarkMode.values.byName(savedMode);

// Değişiklik sırasında:
await prefs.setString('canvas_dark_mode', mode.name);
```

Bu entegrasyonu mevcut settings provider dosyasına ekle veya ayrı bir initializer oluştur.

**4) GÜNCELLE: `packages/drawing_ui/lib/src/providers/providers.dart`** (barrel)

```dart
export 'canvas_dark_mode_provider.dart';
```

**5) GÜNCELLE: `packages/drawing_ui/lib/drawing_ui.dart`** (barrel)

```dart
export 'src/canvas/canvas_color_scheme.dart';
```

**6) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- canvas_color_scheme.dart max 150 satır
- canvas_dark_mode_provider.dart max 100 satır
- PageBackground modeline DOKUNMA (drawing_core)
- Stroke renkleri DEĞİŞMEZ
- SharedPreferences persist zorunlu
- Mevcut davranış korunmalı (default: CanvasDarkMode.off = light)

---

### 🧪 @qa-engineer — Test

**Yeni test: `packages/drawing_ui/test/canvas_color_scheme_test.dart`**

```dart
void main() {
  group('CanvasColorScheme', () {
    test('light scheme has white background', () {
      final scheme = CanvasColorScheme.light();
      expect(scheme.background, const Color(0xFFFFFFFF));
    });

    test('dark scheme has dark background', () {
      final scheme = CanvasColorScheme.dark();
      expect(scheme.background, const Color(0xFF2C2C2C));
    });

    test('effectiveBackground returns scheme color for default white', () {
      final scheme = CanvasColorScheme.dark();
      expect(scheme.effectiveBackground(0xFFFFFFFF), scheme.background);
    });

    test('effectiveBackground respects custom page color', () {
      final scheme = CanvasColorScheme.dark();
      const customColor = 0xFFFF0000;
      expect(scheme.effectiveBackground(customColor), const Color(customColor));
    });

    test('effectiveLineColor returns scheme color for default', () {
      final scheme = CanvasColorScheme.dark();
      expect(scheme.effectiveLineColor(0xFFE0E0E0), scheme.patternLine);
      expect(scheme.effectiveLineColor(null), scheme.patternLine);
    });

    test('effectiveLineColor respects custom line color', () {
      final scheme = CanvasColorScheme.dark();
      const customColor = 0xFF00FF00;
      expect(scheme.effectiveLineColor(customColor), const Color(customColor));
    });
  });

  group('CanvasDarkMode', () {
    test('has three values', () {
      expect(CanvasDarkMode.values.length, 3);
    });

    test('default is off', () {
      final container = ProviderContainer();
      expect(container.read(canvasDarkModeProvider), CanvasDarkMode.off);
      container.dispose();
    });

    test('canvasColorSchemeProvider returns light for off', () {
      final container = ProviderContainer();
      final scheme = container.read(canvasColorSchemeProvider);
      expect(scheme.background, CanvasColorScheme.light().background);
      container.dispose();
    });

    test('canvasColorSchemeProvider returns dark for on', () {
      final container = ProviderContainer(
        overrides: [canvasDarkModeProvider.overrideWith((ref) => CanvasDarkMode.on)],
      );
      final scheme = container.read(canvasColorSchemeProvider);
      expect(scheme.background, CanvasColorScheme.dark().background);
      container.dispose();
    });

    test('followSystem uses brightness provider', () {
      final container = ProviderContainer(
        overrides: [
          canvasDarkModeProvider.overrideWith((ref) => CanvasDarkMode.followSystem),
          platformBrightnessProvider.overrideWith((ref) => Brightness.dark),
        ],
      );
      final scheme = container.read(canvasColorSchemeProvider);
      expect(scheme.background, CanvasColorScheme.dark().background);
      container.dispose();
    });
  });
}
```

---

### 🔍 @code-reviewer — Review

**Kontrol listesi:**
1. CanvasColorScheme immutable, const constructor
2. effectiveBackground/effectiveLineColor custom renkleri koruyor
3. Provider chain doğru: canvasDarkMode → canvasColorScheme
4. SharedPreferences persist çalışıyor
5. Default off = mevcut davranış korunmuş
6. drawing_core'a dokunulmamış
7. Barrel exports güncel
8. Testler kapsamlı

---

## COMMIT
```
feat(canvas): add CanvasColorScheme model and dark mode providers

- Add CanvasColorScheme with light/dark/sepia factory constructors
- Add CanvasDarkMode enum (off/on/followSystem)
- Add canvasColorSchemeProvider with brightness awareness
- Add SharedPreferences persistence
- Custom page colors respected (not overridden)
- Default: off (current behavior preserved)
```

## SONRAKİ ADIM
Adım 2: Painter'ları güncelle — DynamicBackgroundPainter, InfiniteBackgroundPainter, TemplatePatternPainter'a CanvasColorScheme parametresi ekle

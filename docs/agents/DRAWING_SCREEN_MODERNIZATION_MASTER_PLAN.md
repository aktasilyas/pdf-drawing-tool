# 🎨 DRAWING SCREEN MODERNIZATION — MASTER PLAN

> **Oluşturulma:** 2025-02-12
> **Yazar:** Senior Architect (Opus 4.6)
> **Kaynak:** GoodNotes + Notability + Flexcil + Samsung Notes karşılaştırmalı analiz
> **Amaç:** StarNote çizim ekranını production-ready, responsive, modern hale getirmek
> **Kural:** Her phase branch'te geliştirilir, test edilir, main'e merge edilir

---

## 📊 MEVCUT DURUM ANALİZİ

### Sahip Olduklarımız (Güçlü Yönler)

**Altyapı:** drawing_core (pure Dart) + drawing_ui (Flutter) iki paket yapısı, clean architecture, barrel exports, 738+ test, ~92% coverage.

**Toolbar:** Two-row layout (TopNavigationBar + ToolBar), ToolType enum (17 araç), toolbar customization (reorder + visibility toggle), quick access row (renk + kalınlık), undo/redo, settings panel. SharedPreferences ile persist edilen ToolbarConfig.

**Panel Sistemi:** AnchoredPanel ile araç panelleri, pen/highlighter/eraser/shapes/sticker/image/text/lasso/laser panelleri mevcut. Anchored alignment (left/center/right) + ok işareti.

**Theme:** DrawingTheme + DrawingColors sistemi, dark mode desteği (UI chrome), theme-aware widget'lar.

**Responsive:** AppBreakpoints (compact <600, medium 600-839, expanded 840+), DeviceType, ScreenSize enum'ları, ResponsiveBuilder widget, page sidebar tablet/phone ayrımı (yan panel vs drawer).

**Canvas:** Two-layer rendering (committed + active), infinite background painter, template pattern painter, multi-page + PDF desteği, grid/ruler marks.

### Eksiklerimiz (Modernizasyon Hedefleri)

**Responsive Toolbar:** Toolbar sabit üstte, telefon layoutu yok. Tablet'te full-width bar, telefonda compact floating box olmalı. Toolbar repositionable değil.

**Canvas Dark Mode:** UI chrome dark mode destekliyor ama canvas beyaz kalıyor. Notability tarzı "Content Matches Theme" otomatik inversiyon yok.

**Gelişmiş Renk Paleti:** Basit grid picker var. HSV color wheel, hex input, eyedropper, opacity slider eksik. Per-tool bağımsız paletler yok.

**Preset Sistemi:** Toolbar'da 5 renk + 3 kalınlık quick access var ama Flexcil tarzı 20+ inline pen preset yok. Favorite tool preset kaydetme yok.

**Shape Araçları:** Temel şekiller var ama connectors (elbow, curved), text-in-shapes, snap-to-grid, shape fill yok.

**Gesture Sistemi:** Temel zoom/pan var ama configurable undo gesture, finger-tap selection, draw-and-hold shape snap yok.

**Sayfa Yönetimi:** Sidebar thumbnail var ama zoom-out-to-grid, bulk operations, drag-to-reorder eksik.

---

## 🎯 MODERNİZASYON PHASE'LERİ

```
Phase M1: Responsive Toolbar System         [Yüksek Öncelik] [~3-4 gün]
Phase M2: Canvas Dark Mode                   [Yüksek Öncelik] [~2 gün]
Phase M3: Advanced Color Picker              [Orta Öncelik]   [~3 gün]
Phase M4: Pen Preset System                  [Orta Öncelik]   [~2-3 gün]
Phase M5: Enhanced Shape Tools               [Düşük Öncelik]  [~3-4 gün]
Phase M6: Gesture System Improvements        [Düşük Öncelik]  [~2 gün]
Phase M7: Page Management Modernization      [Düşük Öncelik]  [~2-3 gün]
```

Toplam: ~17-23 gün (multi-agent workflow ile daha hızlı)

---

## PHASE M1: RESPONSIVE TOOLBAR SYSTEM

**Branch:** `feature/responsive-toolbar`
**Kaynak Insight:** GoodNotes three-zone tablet bar + Notability compact floating box + Samsung Notes repositionable bar
**Mevcut Etki Alanı:** `packages/drawing_ui/lib/src/toolbar/`, `drawing_screen.dart`

### Mimari Karar: 3-Tier Adaptive Toolbar

Mevcut ToolBar widget'ını AdaptiveToolbar'a dönüştürüyoruz. Breakpoint'ler example_app'teki AppBreakpoints ile tutarlı.

```
Tier 1 — Expanded (≥840px, tablet landscape):
┌────────────────────────────────────────────────────────────────────┐
│ [↶↷] │ [🖊 ✏️ 🖌 💫 ◇ 📝 😀 🖼 ⭕ 📍] │ [⚙] │ [●●●●●][•••] │ [📖🏠📑📤] │
│ undo  │         tools (scrollable)       │ cfg │  quick access  │  actions   │
└────────────────────────────────────────────────────────────────────┘

Tier 2 — Medium (600-839px, tablet portrait / large phone):
┌───────────────────────────────────────┐
│ [↶↷] │ [🖊 ✏️ 🖌 ◇ 📝 ⭕] │ [⚙] │ [⋯] │  ← Tek satır, overflow menu
└───────────────────────────────────────┘
  Quick access: toolbar altında collapsible row
  Actions: overflow menüde

Tier 3 — Compact (<600px, phone):
┌─────────────────────┐
│ [↶↷] [🖊][✏️][🖌][⋯] │  ← Bottom bar, minimal
└─────────────────────┘
  Tüm paneller: bottom sheet olarak açılır
  Quick access: bottom sheet içinde
  Actions: AppBar'da veya drawer'da
```

### Adım M1.1: ToolbarLayoutMode Enum & Provider

```dart
// packages/drawing_ui/lib/src/toolbar/toolbar_layout_mode.dart
enum ToolbarLayoutMode {
  expanded,  // ≥840px — full horizontal, all sections visible
  medium,    // 600-839px — compact horizontal, overflow menu
  compact,   // <600px — bottom bar, bottom sheets for panels
}

// Provider
final toolbarLayoutProvider = Provider<ToolbarLayoutMode>((ref) {
  // Override edilecek, DrawingScreen'de LayoutBuilder ile set edilir
  return ToolbarLayoutMode.expanded;
});
```

### Adım M1.2: AdaptiveToolbar Widget

Mevcut `ToolBar` widget'ını refactor et. LayoutBuilder kullanarak mode belirle:

```dart
class AdaptiveToolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 840) return _ExpandedToolbar(...);
        if (width >= 600) return _MediumToolbar(...);
        return const SizedBox.shrink(); // Compact: bottom bar ayrı widget
      },
    );
  }
}
```

**_ExpandedToolbar:** Mevcut ToolBar ile neredeyse aynı — undo/redo | tools (scrollable) | config | quick access | actions. Değişiklik: responsive spacing, overflow handling.

**_MediumToolbar:** Daha az araç göster (visible tools'un ilk 6-8'i), kalanları overflow menüde. Quick access collapsible. Actions overflow'da.

### Adım M1.3: CompactBottomBar Widget (Phone)

```dart
class CompactBottomBar extends ConsumerWidget {
  // Phone'da ekranın altında sabit bar
  // Undo/redo + aktif tool grubu (max 5) + more button
  // Panel'ler bottom sheet olarak açılır (AnchoredPanel yerine)
}
```

### Adım M1.4: DrawingScreen Responsive Entegrasyonu

```dart
// drawing_screen.dart — build() içinde
final mode = Responsive.value<ToolbarLayoutMode>(
  context,
  compact: ToolbarLayoutMode.compact,
  medium: ToolbarLayoutMode.medium,
  expanded: ToolbarLayoutMode.expanded,
);

// Scaffold body:
// expanded/medium → Column [TopNav, AdaptiveToolbar, Canvas]
// compact → Stack [Canvas, Positioned.bottom(CompactBottomBar)]
```

### Adım M1.5: Panel Delivery Adaptation

```dart
// Expanded/Medium: AnchoredPanel (mevcut sistem, yukarıdan dropdown)
// Compact: showModalBottomSheet (Material bottom sheet)
void openToolPanel(ToolType tool, ToolbarLayoutMode mode) {
  if (mode == ToolbarLayoutMode.compact) {
    showModalBottomSheet(
      context: context,
      builder: (_) => buildActivePanel(panel: tool, onClose: () => Navigator.pop(context)),
    );
  } else {
    // Mevcut AnchoredPanel sistemi
    ref.read(activePanelProvider.notifier).state = tool;
  }
}
```

### Adım M1.6: Overflow Menu Widget

```dart
class ToolbarOverflowMenu extends StatelessWidget {
  // PopupMenuButton veya custom overlay
  // Gösterilmeyen tool'ları + action'ları listeler
  // Medium mode'da kullanılır
}
```

### Dosya Değişiklikleri

| Dosya | İşlem | Detay |
|-------|-------|-------|
| `toolbar_layout_mode.dart` | YENİ | Enum + provider |
| `adaptive_toolbar.dart` | YENİ | Ana responsive toolbar |
| `compact_bottom_bar.dart` | YENİ | Phone bottom bar |
| `toolbar_overflow_menu.dart` | YENİ | Overflow menü |
| `tool_bar.dart` | REFACTOR | → _ExpandedToolbar'a basis |
| `drawing_screen.dart` | GÜNCELLE | Mode-based layout switch |
| `drawing_screen_panels.dart` | GÜNCELLE | Bottom sheet delivery ekleme |
| Tests: 15-20 yeni test | YENİ | Widget + integration tests |

### Kabul Kriterleri
- Tablet landscape (≥840px): Mevcut full toolbar çalışıyor
- Tablet portrait (600-839px): Compact toolbar, overflow menu
- Phone (<600px): Bottom bar, bottom sheet paneller
- Toolbar customization (reorder/visibility) tüm mode'larda çalışıyor
- Quick access tüm mode'larda erişilebilir
- Undo/redo her zaman görünür
- flutter analyze: 0 error
- Minimum 15 yeni test

---

## PHASE M2: CANVAS DARK MODE

**Branch:** `feature/canvas-dark-mode`
**Kaynak Insight:** Notability "Content Matches Theme" — en iyi uygulama. GoodNotes/Flexcil bunu yapamıyor.
**Mevcut Etki Alanı:** `drawing_canvas.dart`, `infinite_background_painter.dart`, `template_pattern_painter.dart`, `stroke_painter.dart`

### Mimari Karar: ColorFilter Overlay + Template Inversion

Canvas dark mode'u iki seviyede uyguluyoruz:

**Seviye 1 — Görüntü Katmanı (ColorFilter):** Canvas widget'ının üzerine ColorFilter.matrix ile renk inversiyonu. Bu yaklaşım mevcut stroke'ları, template pattern'larını ve PDF arka planlarını otomatik invert eder. Render performansını etkilemez çünkü GPU-level filter.

**Seviye 2 — Semantic Renk Eşleme:** Template pattern çizgileri ve canvas arka planı için semantic renkler. Beyaz→koyu gri, açık gri çizgi→koyu gri çizgi. Daha kontrollü ama her bileşeni ayrı ayrı güncellemeyi gerektirir.

Önerimiz: **Seviye 2 (Semantic)** — daha temiz, daha kontrollü, theme sistemiyle uyumlu.

### Adım M2.1: CanvasColorScheme Model

```dart
class CanvasColorScheme {
  final Color background;       // Canvas arka plan
  final Color patternLine;      // Grid/çizgi rengi
  final Color patternDot;       // Nokta rengi
  final Color rulerMark;        // Cetvel işaretleri
  final Color selectionHighlight;

  // Factory'ler
  factory CanvasColorScheme.light() => CanvasColorScheme(
    background: Colors.white,
    patternLine: Color(0xFFE0E0E0),
    patternDot: Color(0xFFD0D0D0),
    rulerMark: Color(0xFFBDBDBD),
    selectionHighlight: Color(0x332196F3),
  );

  factory CanvasColorScheme.dark() => CanvasColorScheme(
    background: Color(0xFF1E1E1E),
    patternLine: Color(0xFF3A3A3A),
    patternDot: Color(0xFF404040),
    rulerMark: Color(0xFF4A4A4A),
    selectionHighlight: Color(0x3364B5F6),
  );
}
```

### Adım M2.2: Canvas Dark Mode Provider

```dart
enum CanvasDarkMode {
  off,          // Her zaman açık tema (mevcut davranış)
  on,           // Her zaman koyu tema
  followSystem, // Sistem temasını takip et
}

final canvasDarkModeProvider = StateProvider<CanvasDarkMode>((ref) {
  return CanvasDarkMode.off; // Default: mevcut davranış korunur
});

final canvasColorSchemeProvider = Provider<CanvasColorScheme>((ref) {
  final mode = ref.watch(canvasDarkModeProvider);
  final brightness = ref.watch(platformBrightnessProvider);
  switch (mode) {
    case CanvasDarkMode.off: return CanvasColorScheme.light();
    case CanvasDarkMode.on: return CanvasColorScheme.dark();
    case CanvasDarkMode.followSystem:
      return brightness == Brightness.dark
        ? CanvasColorScheme.dark()
        : CanvasColorScheme.light();
  }
});
```

### Adım M2.3: InfiniteBackgroundPainter Güncelleme

Mevcut hardcoded `Colors.white` → `canvasColorScheme.background`. Grid/dot/line renkleri → `canvasColorScheme.patternLine` / `patternDot`.

### Adım M2.4: TemplatePatternPainter Güncelleme

Her template pattern painter'ı CanvasColorScheme kullanacak şekilde güncelle. Cornell notes, isometric, hex grid vb. hepsi semantic renk kullanmalı.

### Adım M2.5: Settings Entegrasyonu

Settings ekranında "Canvas Teması" seçeneği: Açık / Koyu / Sistem. SharedPreferences ile persist.

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `canvas_color_scheme.dart` | YENİ |
| `canvas_dark_mode_provider.dart` | YENİ |
| `infinite_background_painter.dart` | GÜNCELLE |
| `template_pattern_painter.dart` | GÜNCELLE |
| `drawing_canvas.dart` | GÜNCELLE |
| Settings ekranı | GÜNCELLE |
| Tests: 10-15 yeni test | YENİ |

### Kabul Kriterleri
- Dark mode'da canvas arka planı koyu gri
- Template çizgileri/noktaları koyu temada görünür
- Stroke renkleri korunur (kullanıcı siyah ile yazdıysa, dark canvas'ta beyaza dönüşMEZ — bilinçli karar)
- PDF arka planı dark mode'da overlay filter ile koyulaşır (opsiyonel, Phase M2+)
- Üç mod çalışıyor: Off, On, Follow System
- Ayar persist ediliyor
- 60 FPS korunuyor

---

## PHASE M3: ADVANCED COLOR PICKER

**Branch:** `feature/advanced-color-picker`
**Kaynak Insight:** GoodNotes 3-yöntemli picker (grid + wheel + hex) + eyedropper. Tüm uygulamalarda opacity slider eksik — fırsat.
**Mevcut Etki Alanı:** `unified_color_picker.dart`, `color_presets.dart`, `color_picker_sections.dart`

### Mimari Karar: Tab-Based Advanced Picker

Mevcut UnifiedColorPicker'ı genişletiyoruz. Üç tab:

```
[Presets] [Wheel] [Custom]

Presets tab: Mevcut grid (12-15 renk) + son kullanılanlar (8 slot, otomatik)
Wheel tab: HSV color wheel + brightness slider + preview
Custom tab: Hex input + RGB sliders + opacity slider
```

### Adım M3.1: HSV Color Wheel Widget

```dart
class HsvColorWheel extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  // CustomPainter ile HSV wheel çizimi
  // Touch/drag ile hue + saturation seçimi
  // Ayrı brightness slider
}
```

### Adım M3.2: Hex Input & RGB Sliders

```dart
class HexColorInput extends StatelessWidget {
  // TextField: #RRGGBB formatında
  // Yapıştırma desteği
  // Validation (6 hex karakter)
}

class RgbSliders extends StatelessWidget {
  // R, G, B ayrı slider'lar (0-255)
  // Her slider yanında değer gösterimi
}
```

### Adım M3.3: Opacity Slider (DİFERANSİYASYON)

```dart
class OpacitySlider extends StatelessWidget {
  // 0% - 100% opacity
  // Checkerboard background ile preview
  // Tüm araçlarda çalışır (pen, highlighter, shapes)
  // drawingStateProvider'a opacity eklenmeli
}
```

### Adım M3.4: Recent Colors Tracking

```dart
final recentColorsProvider = StateNotifierProvider<RecentColorsNotifier, List<Color>>((ref) {
  // Max 8 renk, FIFO, SharedPreferences ile persist
  // Her renk seçiminde otomatik güncelleme
});
```

### Adım M3.5: Per-Tool Independent Palettes

Her araç tipi (pen, highlighter, shapes) kendi renk preset'lerini tutar. Mevcut `penColors` ve `highlighterColors` DrawingTheme'den zaten ayrı — bunu provider seviyesinde genişletiyoruz.

### Adım M3.6: Eyedropper Tool

```dart
class EyedropperTool {
  // Canvas'tan renk seçme
  // Magnifier overlay ile precise picking
  // ToolType.eyedropper? veya color picker içi toggle
  // Seçilen renk aktif araca uygulanır
}
```

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `hsv_color_wheel.dart` | YENİ |
| `hex_color_input.dart` | YENİ |
| `rgb_sliders.dart` | YENİ |
| `opacity_slider.dart` | YENİ |
| `recent_colors_provider.dart` | YENİ |
| `eyedropper_overlay.dart` | YENİ |
| `unified_color_picker.dart` | REFACTOR — tab sistemi |
| `pen_settings_panel.dart` | GÜNCELLE — opacity entegrasyonu |
| `highlighter_settings_panel.dart` | GÜNCELLE |
| `shapes_settings_panel.dart` | GÜNCELLE |
| Tests: 20+ yeni test | YENİ |

### Kabul Kriterleri
- 3-tab picker çalışıyor (Presets, Wheel, Custom)
- HSV wheel dokunma + sürükleme ile çalışıyor
- Hex input geçerli (#RRGGBB)
- Opacity slider 0-100% (tüm araçlarda)
- Son 8 kullanılan renk otomatik kaydediliyor
- Eyedropper canvas'tan renk seçebiliyor
- Per-tool bağımsız paletler
- Mevcut compact color picker (quick access'teki) korunuyor

---

## PHASE M4: PEN PRESET SYSTEM

**Branch:** `feature/pen-presets`
**Kaynak Insight:** Flexcil 50 preset inline + Notability 8 favorites + GoodNotes per-tool slots
**Mevcut Etki Alanı:** `toolbar_config_provider.dart`, `quick_access_row.dart`, `pen_settings_panel.dart`

### Mimari Karar: Inline Preset Strip + Favorites

Mevcut quick access row'u genişletiyoruz. Toolbar'ın altında (veya yanında) horizontal scroll edilen preset strip:

```
[Preset Strip — Expanded toolbar altında]
[🔵0.3] [🔴0.5] [🟢1.0] [💛H0.8] [⬛E] [+] ← max 20 preset, scroll
  pen1    pen2    pen3   highlight  eraser  add
```

Her preset: araç tipi + renk + kalınlık + opacity + line style bilgisi taşır.

### Adım M4.1: PenPreset Model

```dart
@freezed
class PenPreset with _$PenPreset {
  factory PenPreset({
    required String id,
    required ToolType toolType,
    required Color color,
    required double thickness,
    @Default(1.0) double opacity,
    @Default(LineStyle.solid) LineStyle lineStyle,
    String? name,
  }) = _PenPreset;

  factory PenPreset.fromJson(Map<String, dynamic> json) => _$PenPresetFromJson(json);
}
```

### Adım M4.2: PenPresetProvider

```dart
final penPresetsProvider = StateNotifierProvider<PenPresetsNotifier, List<PenPreset>>((ref) {
  // Max 20 preset
  // SharedPreferences ile persist (JSON array)
  // CRUD operations
  // Default: 5 preset (siyah pen, kırmızı pen, mavi pen, sarı highlighter, eraser)
});
```

### Adım M4.3: PresetStrip Widget

```dart
class PresetStrip extends ConsumerWidget {
  // Horizontal ListView.builder
  // Her preset: CircleAvatar (renk) + kalınlık indicator
  // Active preset highlighted
  // Tap: preset'i aktif yap
  // Long press: preset'i düzenle/sil
  // Son eleman: [+] yeni preset ekle
  // Responsive: expanded → toolbar altı, compact → bottom sheet içi
}
```

### Adım M4.4: Panel "Preset Olarak Kaydet" Butonu

Pen/highlighter/eraser panel'lerine "Preset Olarak Kaydet" butonu ekle. Mevcut ayarları yeni preset olarak kaydeder.

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `pen_preset.dart` | YENİ (model) |
| `pen_presets_provider.dart` | YENİ |
| `preset_strip.dart` | YENİ (widget) |
| `preset_editor_dialog.dart` | YENİ |
| `pen_settings_panel.dart` | GÜNCELLE — kaydet butonu |
| `highlighter_settings_panel.dart` | GÜNCELLE |
| `eraser_settings_panel.dart` | GÜNCELLE |
| `adaptive_toolbar.dart` | GÜNCELLE — strip entegrasyonu |
| Tests: 12-15 yeni test | YENİ |

---

## PHASE M5: ENHANCED SHAPE TOOLS

**Branch:** `feature/enhanced-shapes`
**Kaynak Insight:** GoodNotes connectors + text-in-shapes + snap-to-shape. Flexcil shape correction.
**Mevcut Etki Alanı:** `shapes_settings_panel.dart`, drawing_core shape tool

### Yeni Özellikler

**Connectors:** Elbow connector (90° dönüşler, flowchart) + curved connector (mind map). İki shape'in endpoint'lerini birleştirir, shape hareket ettirildiğinde connector otomatik güncellenir.

**Text-in-Shapes:** Shape'e tıkla → inline TextEditingController ile text gir → text otomatik shape bounds'a fit olur.

**Shape Fill:** Kapalı şekiller için fill color + stroke color ayrımı. Fill opacity ayrı kontrol.

**Draw-and-Hold Snap:** Herhangi bir pen aracıyla çizerken 500ms hold → en yakın shape'e snap. Daire, kare, üçgen, çizgi, ok tanıma.

**Snap-to-Grid:** Shape'leri grid noktalarına snap etme (opsiyonel toggle).

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `connector_tool.dart` | YENİ (drawing_core) |
| `shape_recognition.dart` | YENİ (drawing_core) |
| `text_in_shape.dart` | YENİ (drawing_core) |
| `shape_fill_provider.dart` | YENİ |
| `shapes_settings_panel.dart` | BÜYÜK GÜNCELLEME |
| Tests: 20+ yeni test | YENİ |

---

## PHASE M6: GESTURE SYSTEM IMPROVEMENTS

**Branch:** `feature/gesture-improvements`
**Kaynak Insight:** Notability configurable undo gesture + GoodNotes finger-tap selection + Flexcil gesture mode

### Yeni Özellikler

**Configurable Undo Gesture:** Settings'te seçim: iki parmak çift tap (GoodNotes) / üç parmak kaydırma (Notability) / kapalı. Mevcut toolbar undo/redo korunur.

**Finger-Tap Selection:** Pen aracı aktifken parmakla (stylus değil) objeye tap → seçim aracına geçmeden objeyi seç. GestureDetector'da device kind kontrolü.

**Auto-Minimize Toolbar:** Canvas'a yazı yazılmaya başlandığında toolbar opacity azalt veya gizle. Yazı bitince geri getir. Notability pattern.

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `gesture_config_provider.dart` | YENİ |
| `undo_gesture_handler.dart` | YENİ |
| `drawing_canvas_gesture_handlers.dart` | GÜNCELLE |
| `adaptive_toolbar.dart` | GÜNCELLE — auto-minimize |
| Settings ekranı | GÜNCELLE — gesture ayarları |
| Tests: 10+ yeni test | YENİ |

---

## PHASE M7: PAGE MANAGEMENT MODERNIZATION

**Branch:** `feature/page-management`
**Kaynak Insight:** GoodNotes sidebar + Flexcil zoom-out-to-grid + Notability Content Manager

### Yeni Özellikler

**Zoom-Out-to-Grid:** Canvas'ta iki parmakla küçültme devam ettirildiğinde (threshold: 0.3x zoom), sayfa grid görünümüne geçiş. Flexcil pattern — keşif mekanizması.

**Drag-to-Reorder:** Page sidebar'da thumbnail'ları sürükle-bırak ile yeniden sırala. ReorderableListView kullanımı.

**Bulk Operations:** Multi-select mode (uzun basma → seçim modu). Seçili sayfaları sil, kopyala, taşı, template değiştir.

**Page Context Menu:** Her thumbnail'da long press → context menu: Duplicate, Delete, Change Template, Insert Before/After, Move to...

### Dosya Değişiklikleri

| Dosya | İşlem |
|-------|-------|
| `page_grid_view.dart` | YENİ |
| `page_thumbnail_reorderable.dart` | YENİ |
| `page_context_menu.dart` | YENİ |
| `page_bulk_actions.dart` | YENİ |
| Sidebar widget | BÜYÜK GÜNCELLEME |
| Tests: 15+ yeni test | YENİ |

---

## 📋 ÖNCELİK SIRASI & BAĞIMLILIKLAR

```
M1 (Responsive Toolbar) ──→ M4 (Presets) ──→ M6 (Gestures)
         │
         ↓
M2 (Canvas Dark Mode) ──→ standalone
         │
         ↓
M3 (Color Picker) ──→ M4 (Presets, renk sistemi gerekli)
         │
         ↓
M5 (Shapes) ──→ standalone (ama M3 color picker'ı kullanır)
         │
         ↓
M7 (Page Management) ──→ standalone
```

**Önerilen geliştirme sırası:** M1 → M2 → M3 → M4 → M5 → M6 → M7

M1 en yüksek etkili çünkü telefon kullanıcıları şu an drawing screen'i verimli kullanamıyor. M2 dark mode kullanıcılar için en çok istenen özellik. M3+M4 birlikte implement edilebilir (paralel agent'larla).

---

## 🏗️ CURSOR TALİMAT FORMATI

Her phase için Cursor'a şu formatta talimat verilecek:

```markdown
## GÖREV: [Phase adı]
## BRANCH: [branch adı]
## BAĞLAM: [Hangi dosyalar etkileniyor, mevcut yapı]
## ADIMLAR:
1. [Dosya oluştur / güncelle]
2. [Test yaz]
3. [flutter analyze + test çalıştır]
## KURALLAR:
- Max 300 satır/dosya
- Barrel exports zorunlu
- Hardcoded renk yasak (DrawingTheme / ColorScheme kullan)
- Hardcoded spacing yasak (AppSpacing kullan)
- Her widget min 48x48dp touch target
- flutter analyze: 0 error
## KABUL KRİTERLERİ:
[Phase'e özel kriterler]
```

---

## 📊 KARŞILAŞTIRMA MATRİSİ: HEDEF vs RAKİPLER

| Özellik | GoodNotes | Notability | Flexcil | Samsung | StarNote Hedef |
|---------|-----------|------------|---------|---------|----------------|
| Responsive toolbar | ❌ Overflow | ✅ Float | ⚠️ Toggle | ⚠️ Scroll | ✅ 3-tier adaptive |
| Canvas dark mode | ❌ | ✅ | ❌ | ⚠️ | ✅ 3-mod |
| Color wheel + hex | ✅ | ✅ | ❌ | ⚠️ | ✅ |
| Opacity slider | ❌ | ❌ | ⚠️ HL only | ⚠️ Draw only | ✅ Tüm araçlar |
| Pen presets | ~12 slot | 8 fav | 50 inline | Sınırsız | 20 inline |
| Connectors | ✅ | ❌ | ❌ | ❌ | ✅ |
| Text-in-shapes | ✅ | ❌ | ❌ | ❌ | ✅ |
| Config undo gesture | ❌ | ✅ | ⚠️ | ❌ | ✅ |
| Zoom-out-to-grid | ❌ | ❌ | ✅ | ❌ | ✅ |
| Cross-platform | iOS+Android+Mac+Win | iOS+Mac | iOS+Android | Android+Win | ✅ Flutter (tümü) |

**StarNote Farklılaşma:** Opacity slider (tüm araçlarda), 3-tier responsive toolbar, canvas dark mode + responsive + cross-platform kombinasyonu. Hiçbir rakip bu üçünü birlikte sunmuyor.

---

## 📝 NOTLAR

1. Her phase sonrası tablet + phone test zorunlu
2. Performance: Her phase sonrası 60 FPS doğrulama (DevTools timeline)
3. Accessibility: Touch target minimum 48dp, yeterli kontrast oranı
4. Localization: Tüm string'ler Türkçe, ileride i18n altyapısı eklenecek
5. Premium: Bazı özellikler Premium'a bağlanabilir (eyedropper, advanced presets, connectors)

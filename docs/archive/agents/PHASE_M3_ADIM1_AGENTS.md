# PHASE M3 — ADIM 1/6: İkon Sistemi Modernizasyonu

## ÖZET
Phosphor Icons paketini ekle. ElyanotesIcons sınıfı oluştur. Tüm Material Icons referanslarını değiştir. GoodNotes kalitesinde ince outline ikonlar.

## BRANCH
```bash
git checkout -b feature/toolbar-professional
```

---

## MİMARİ KARAR

Phosphor Icons `light` stilini kullanıyoruz — en ince, en elegant, GoodNotes estetiğine en yakın stil. `regular` değil `light` — bu önemli. Aktif/seçili durumda `regular` veya `bold` kullanabiliriz.

Tüm ikonları ElyanotesIcons sınıfında merkezi olarak tanımlıyoruz. Widget'lar doğrudan PhosphorIcons kullanmaz — her zaman ElyanotesIcons üzerinden erişir. Bu sayede ikon değişikliği tek dosyadan yapılır.

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/pubspec.yaml — dependency ekleme
- packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart — mevcut Material Icons
- packages/drawing_ui/lib/src/toolbar/tool_button.dart — mevcut tool ikonları
- packages/drawing_ui/lib/src/toolbar/tool_bar.dart — mevcut ikon kullanımları
- packages/drawing_ui/lib/src/models/tool_type.dart — ToolType.icon getter
- docs/agents/goodnotes_01_toolbar_context_menu.jpeg — GoodNotes ikon stili referansı

**1) DEPENDENCY EKLE:**

```bash
cd packages/drawing_ui
flutter pub add phosphor_flutter
```

pubspec.yaml'a eklenmeli:
```yaml
dependencies:
  phosphor_flutter: ^2.1.0
```

Ayrıca example_app'te de dependency'ye ihtiyaç olabilir — kontrol et.

**2) YENİ DOSYA: `packages/drawing_ui/lib/src/theme/elyanotes_icons.dart`**

Tüm ikonları merkezi olarak tanımlayan sınıf. Max 250 satır.

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

/// Centralized icon definitions for Elyanotes.
///
/// All icons use Phosphor Light style for thin, elegant appearance.
/// Active/selected states use Phosphor Regular for slightly bolder look.
/// 
/// Never use PhosphorIcons directly in widgets — always use ElyanotesIcons.
abstract final class ElyanotesIcons {
  // ═══════════════════════════════════════════
  // Navigation Bar Icons (Row 1)
  // ═══════════════════════════════════════════
  
  static PhosphorIconData get home => PhosphorIconsLight.house;
  static PhosphorIconData get sidebar => PhosphorIconsLight.sidebar;
  static PhosphorIconData get sidebarActive => PhosphorIconsRegular.sidebar;
  static PhosphorIconData get search => PhosphorIconsLight.magnifyingGlass;
  static PhosphorIconData get readerMode => PhosphorIconsLight.bookOpen;
  static PhosphorIconData get readerModeActive => PhosphorIconsRegular.bookOpen;
  static PhosphorIconData get layers => PhosphorIconsLight.stack;
  static PhosphorIconData get gridOn => PhosphorIconsLight.gridFour;
  static PhosphorIconData get gridOff => PhosphorIconsLight.squareSplitHorizontal;
  static PhosphorIconData get share => PhosphorIconsLight.shareFat;
  static PhosphorIconData get export => PhosphorIconsLight.export;
  static PhosphorIconData get more => PhosphorIconsLight.dotsThree;
  static PhosphorIconData get caretDown => PhosphorIconsLight.caretDown;
  static PhosphorIconData get settings => PhosphorIconsLight.gearSix;
  
  // ═══════════════════════════════════════════
  // Tool Bar Icons (Row 2) — Drawing Tools
  // ═══════════════════════════════════════════
  
  // Pen tools
  static PhosphorIconData get penNib => PhosphorIconsLight.penNib;           // Dolma kalem
  static PhosphorIconData get penNibActive => PhosphorIconsRegular.penNib;
  static PhosphorIconData get pencil => PhosphorIconsLight.pencilSimple;     // Kurşun kalem
  static PhosphorIconData get pencilActive => PhosphorIconsRegular.pencilSimple;
  static PhosphorIconData get pen => PhosphorIconsLight.pen;                 // Tükenmez kalem
  static PhosphorIconData get penActive => PhosphorIconsRegular.pen;
  static PhosphorIconData get marker => PhosphorIconsLight.marker;           // Keçeli kalem / gel pen
  static PhosphorIconData get markerActive => PhosphorIconsRegular.marker;
  static PhosphorIconData get paintBrush => PhosphorIconsLight.paintBrush;   // Fırça
  static PhosphorIconData get paintBrushActive => PhosphorIconsRegular.paintBrush;
  static PhosphorIconData get ruler => PhosphorIconsLight.ruler;             // Cetvel kalemi
  static PhosphorIconData get rulerActive => PhosphorIconsRegular.ruler;
  
  // Highlighter
  static PhosphorIconData get highlighter => PhosphorIconsLight.highlighterCircle;
  static PhosphorIconData get highlighterActive => PhosphorIconsRegular.highlighterCircle;
  
  // Eraser
  static PhosphorIconData get eraser => PhosphorIconsLight.eraser;
  static PhosphorIconData get eraserActive => PhosphorIconsRegular.eraser;
  
  // Shape tools
  static PhosphorIconData get shapes => PhosphorIconsLight.shapes;
  static PhosphorIconData get shapesActive => PhosphorIconsRegular.shapes;
  
  // Text
  static PhosphorIconData get textT => PhosphorIconsLight.textT;
  static PhosphorIconData get textTActive => PhosphorIconsRegular.textT;
  
  // Image
  static PhosphorIconData get image => PhosphorIconsLight.imageSquare;
  static PhosphorIconData get imageActive => PhosphorIconsRegular.imageSquare;
  
  // Sticker
  static PhosphorIconData get sticker => PhosphorIconsLight.smiley;
  static PhosphorIconData get stickerActive => PhosphorIconsRegular.smiley;
  
  // Laser pointer
  static PhosphorIconData get laser => PhosphorIconsLight.cursorClick;
  static PhosphorIconData get laserActive => PhosphorIconsRegular.cursorClick;
  
  // Selection / Lasso
  static PhosphorIconData get selection => PhosphorIconsLight.selection;
  static PhosphorIconData get selectionActive => PhosphorIconsRegular.selection;
  
  // Pan/Zoom
  static PhosphorIconData get hand => PhosphorIconsLight.hand;
  static PhosphorIconData get handActive => PhosphorIconsRegular.hand;
  
  // ═══════════════════════════════════════════
  // Action Icons
  // ═══════════════════════════════════════════
  
  static PhosphorIconData get undo => PhosphorIconsLight.arrowCounterClockwise;
  static PhosphorIconData get redo => PhosphorIconsLight.arrowClockwise;
  static PhosphorIconData get close => PhosphorIconsLight.x;
  static PhosphorIconData get check => PhosphorIconsLight.check;
  static PhosphorIconData get plus => PhosphorIconsLight.plus;
  static PhosphorIconData get minus => PhosphorIconsLight.minus;
  static PhosphorIconData get trash => PhosphorIconsLight.trash;
  static PhosphorIconData get copy => PhosphorIconsLight.copy;
  static PhosphorIconData get duplicate => PhosphorIconsLight.copySimple;
  static PhosphorIconData get bookmark => PhosphorIconsLight.bookmarkSimple;
  static PhosphorIconData get bookmarkFilled => PhosphorIconsFill.bookmarkSimple;
  static PhosphorIconData get rotate => PhosphorIconsLight.arrowsClockwise;
  static PhosphorIconData get template => PhosphorIconsLight.layout;
  static PhosphorIconData get goToPage => PhosphorIconsLight.arrowSquareRight;
  static PhosphorIconData get sliders => PhosphorIconsLight.slidersHorizontal;
  static PhosphorIconData get palette => PhosphorIconsLight.palette;
  static PhosphorIconData get eyedropper => PhosphorIconsLight.eyedropper;
  
  // ═══════════════════════════════════════════
  // Page & Document Icons
  // ═══════════════════════════════════════════
  
  static PhosphorIconData get page => PhosphorIconsLight.file;
  static PhosphorIconData get pageAdd => PhosphorIconsLight.filePlus;
  static PhosphorIconData get pageClear => PhosphorIconsLight.fileX;
  static PhosphorIconData get pdfFile => PhosphorIconsLight.filePdf;
  static PhosphorIconData get folder => PhosphorIconsLight.folder;
  static PhosphorIconData get folderOpen => PhosphorIconsLight.folderOpen;
  
  // ═══════════════════════════════════════════
  // Navigation Icons
  // ═══════════════════════════════════════════
  
  static PhosphorIconData get chevronLeft => PhosphorIconsLight.caretLeft;
  static PhosphorIconData get chevronRight => PhosphorIconsLight.caretRight;
  static PhosphorIconData get arrowLeft => PhosphorIconsLight.arrowLeft;
  
  // ═══════════════════════════════════════════
  // Size Constants
  // ═══════════════════════════════════════════
  
  /// Navigation bar icon size
  static const double navSize = 20.0;
  
  /// Tool bar icon size
  static const double toolSize = 22.0;
  
  /// Panel icon size
  static const double panelSize = 18.0;
  
  /// Action button icon size
  static const double actionSize = 20.0;

  // ═══════════════════════════════════════════
  // Helper: ToolType → Icon mapping
  // ═══════════════════════════════════════════
  
  /// Returns the appropriate icon for a given ToolType.
  static PhosphorIconData iconForTool(ToolType tool, {bool active = false}) {
    return switch (tool) {
      // Pen family — tüm kalem tipleri dolma kalem ikonu gösterir (grup ikonu)
      ToolType.pen || ToolType.pencil => active ? pencilActive : pencil,
      ToolType.hardPencil => active ? pencilActive : pencil,
      ToolType.ballpointPen => active ? penActive : pen,
      ToolType.gelPen => active ? markerActive : marker,
      ToolType.dashedPen => active ? penActive : pen,
      ToolType.brushPen => active ? paintBrushActive : paintBrush,
      ToolType.rulerPen => active ? rulerActive : ruler,
      
      // Highlighter family
      ToolType.highlighter || ToolType.neonHighlighter => active ? highlighterActive : highlighter,
      
      // Eraser family
      ToolType.eraser || ToolType.pixelEraser || ToolType.strokeEraser || ToolType.lassoEraser 
          => active ? eraserActive : eraser,
      
      // Individual tools
      ToolType.shapes => active ? shapesActive : shapes,
      ToolType.text => active ? textTActive : textT,
      ToolType.image => active ? imageActive : image,
      ToolType.sticker => active ? stickerActive : sticker,
      ToolType.laserPointer => active ? laserActive : laser,
      ToolType.selection || ToolType.lasso => active ? selectionActive : selection,
      ToolType.panZoom => active ? handActive : hand,
      
      // Fallback
      _ => active ? penNibActive : penNib,
    };
  }
}
```

**ÖNEMLİ:** `ToolType` import'u gerekli. ToolType models dosyasından import et. Eğer circular dependency olursa iconForTool'u ayrı bir extension'a taşı.

**3) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/tool_button.dart`**

Material Icons → ElyanotesIcons ile değiştir:

```dart
// Eski:
Icon(Icons.edit, size: 20)

// Yeni:
PhosphorIcon(
  ElyanotesIcons.iconForTool(toolType, active: isSelected),
  size: ElyanotesIcons.toolSize,
  color: isSelected ? selectedColor : defaultColor,
)
```

ToolButton widget'ında mevcut `_getIconForTool` veya benzer mapping fonksiyonunu kaldır, `ElyanotesIcons.iconForTool()` kullan.

**4) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart`**

Tüm _NavButton ikonlarını değiştir:

```dart
// Eski:
Icons.home_rounded        → ElyanotesIcons.home
Icons.menu_book_outlined  → ElyanotesIcons.readerMode
Icons.layers_outlined     → ElyanotesIcons.layers
Icons.grid_on/grid_off    → ElyanotesIcons.gridOn / ElyanotesIcons.gridOff
Icons.share_outlined      → ElyanotesIcons.share
Icons.settings_outlined   → ElyanotesIcons.settings
Icons.more_horiz          → ElyanotesIcons.more
Icons.keyboard_arrow_down → ElyanotesIcons.caretDown
Icons.search              → ElyanotesIcons.search
```

_NavButton'daki `Icon` widget'ını `PhosphorIcon` ile değiştir:
```dart
// Eski:
Icon(icon, size: 18, color: color)

// Yeni:
PhosphorIcon(icon, size: ElyanotesIcons.navSize, color: color)
```

**5) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/tool_bar.dart`**

Mevcut ikon referanslarını ElyanotesIcons ile değiştir. Undo/redo butonlarındaki ikonlar:
```dart
// Eski:
Icons.undo → ElyanotesIcons.undo
Icons.redo → ElyanotesIcons.redo
```

**6) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/toolbar_widgets.dart`**

ToolbarUndoRedoButtons, ToolbarVerticalDivider gibi widget'lardaki ikonlar:
```dart
Icons.undo → ElyanotesIcons.undo
Icons.redo → ElyanotesIcons.redo
```

**7) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/medium_toolbar.dart`**

MediumToolbar'daki ikon referansları ElyanotesIcons ile değiştir. Özellikle undo/redo ve settings ikonları.

**8) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/compact_bottom_bar.dart`**

CompactBottomBar'daki ikon referansları değiştir.

**9) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/toolbar_overflow_menu.dart`**

Overflow menüdeki `Icons.more_horiz` → `ElyanotesIcons.more`.

**10) GÜNCELLE: Paneller (varsa ikon referansı)**

Panel dosyalarında Material Icons varsa ElyanotesIcons ile değiştir:
- pen_settings_panel.dart
- highlighter_settings_panel.dart
- eraser_settings_panel.dart
- shapes_settings_panel.dart
- toolbar_settings_panel.dart (toolbar_editor_panel.dart)

**11) GÜNCELLE: Barrel exports**

`packages/drawing_ui/lib/src/theme/theme.dart` (barrel):
```dart
export 'elyanotes_icons.dart';
```

`packages/drawing_ui/lib/drawing_ui.dart`:
- `phosphor_flutter` re-export gerekli mi kontrol et. Eğer example_app'te PhosphorIcon widget'ı kullanılıyorsa, drawing_ui'dan re-export et.

**12) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
cd example_app && flutter analyze
```

**KURALLAR:**
- Widget'larda doğrudan `PhosphorIcons*` kullanMA — her zaman `ElyanotesIcons` üzerinden
- PhosphorIcon widget'ı kullan (Icon değil) — duotone desteği için
- İkon boyutları: ElyanotesIcons.navSize (20), toolSize (22), panelSize (18)
- Light stil default, active/selected durumda Regular stil
- Mevcut testlerde `find.byIcon(Icons.undo)` gibi aramalar kırılabilir — güncelle
- `phosphor_flutter` sadece drawing_ui'da dependency, example_app'te drawing_ui üzerinden erişilir

---

### 🧪 @qa-engineer — Test

**1) Mevcut testleri güncelle:**
`Icons.undo`, `Icons.redo`, `Icons.more_horiz` gibi finder'lar artık çalışmayacak. Bunları güncelle:

```dart
// Eski:
expect(find.byIcon(Icons.undo), findsOneWidget);

// Yeni: PhosphorIcon kullanıldığı için:
expect(find.byWidgetPredicate(
  (widget) => widget is PhosphorIcon && widget.data == ElyanotesIcons.undo,
), findsOneWidget);

// VEYA daha basit: find.byType(PhosphorIcon) kullan
```

**2) Yeni test: `packages/drawing_ui/test/elyanotes_icons_test.dart`**

```dart
void main() {
  group('ElyanotesIcons', () {
    test('iconForTool returns correct icon for each tool type', () {
      expect(ElyanotesIcons.iconForTool(ToolType.pencil), ElyanotesIcons.pencil);
      expect(ElyanotesIcons.iconForTool(ToolType.highlighter), ElyanotesIcons.highlighter);
      expect(ElyanotesIcons.iconForTool(ToolType.eraser), ElyanotesIcons.eraser);
    });

    test('active icons differ from default', () {
      expect(
        ElyanotesIcons.iconForTool(ToolType.pencil, active: true),
        isNot(ElyanotesIcons.iconForTool(ToolType.pencil, active: false)),
      );
    });

    test('size constants are defined', () {
      expect(ElyanotesIcons.navSize, 20.0);
      expect(ElyanotesIcons.toolSize, 22.0);
      expect(ElyanotesIcons.panelSize, 18.0);
    });
  });
}
```

---

### 🔍 @code-reviewer — Review

1. phosphor_flutter dependency doğru eklendi
2. ElyanotesIcons abstract final class, instance oluşturulamaz
3. Tüm Material Icons referansları kaldırıldı (grep -r "Icons\." packages/drawing_ui/lib/src/toolbar/)
4. PhosphorIcon widget'ı kullanılıyor (Icon değil)
5. Light stil default, Regular aktif durumda
6. İkon boyutları const'lardan geliyor
7. Barrel exports güncel
8. Testler güncellendi
9. flutter analyze clean

**Özellikle kontrol et:**
```bash
# Kalan Material Icons var mı?
grep -rn "Icons\." packages/drawing_ui/lib/src/toolbar/ --include="*.dart"
grep -rn "Icons\." packages/drawing_ui/lib/src/panels/ --include="*.dart"
```

---

## COMMIT
```
feat(ui): add Phosphor Icons system with ElyanotesIcons

- Add phosphor_flutter dependency
- Create ElyanotesIcons: centralized icon definitions (light/regular)
- Replace all Material Icons in toolbar, nav bar, and panels
- Use PhosphorIcon widget with consistent sizing
- Light style default, Regular for active/selected states
- Update test finders for PhosphorIcon
```

## SONRAKİ ADIM
Adım 2: TopNavigationBar profesyonelleştirme — placeholder'ları temizle, çalışan butonlar

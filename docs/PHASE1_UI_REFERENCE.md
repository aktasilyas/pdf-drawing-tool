# Phase 1 UI Reference Specification

> **Source**: Elyanotes/Fenci app screenshots (10 reference images)
> **Purpose**: Exact UI specification for Cursor implementation
> **Status**: BINDING DOCUMENT - All Phase 1 work must match this spec

---

## Table of Contents

1. [Overall Layout](#1-overall-layout)
2. [Top Toolbar](#2-top-toolbar)
3. [Pen Box (Left Sidebar)](#3-pen-box-left-sidebar)
4. [Pen Settings Panel](#4-pen-settings-panel)
5. [Highlighter Panel](#5-highlighter-panel)
6. [Eraser Panel](#6-eraser-panel)
7. [Shapes Panel](#7-shapes-panel)
8. [Sticker Panel](#8-sticker-panel)
9. [Image Panel](#9-image-panel)
10. [Lazer Pointer Panel](#10-lazer-pointer-panel)
11. [Kement (Lasso) Panel](#11-kement-lasso-panel)
12. [Toolbar Editor](#12-toolbar-editor)
13. [State Management](#13-state-management)
14. [Interactions](#14-interactions)

---

## 1. Overall Layout

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ ← [📷][📋][🎤]     İsimsiz not    ×  │  DOCUMENT_NAME                    × │ 2∨ │
├─────────────────────────────────────────────────────────────────────────────────┤
│ [↶][↷] │ [🖊][✏️][🖌][💫][◇][📝][😀][🖼][⭕][📍][✨][🖌] │ [⚙️] │ [●●●●●][•••] │ [📖][🏠][📑][📤][📐][⚙️][⋯] │
├────┬────────────────────────────────────────────────────────────────────────────┤
│ 📑 │                                                                            │
│────│                                                                            │
│ ▶  │                                                                            │
│ 0.3│                                                                            │
│────│                                                                            │
│ ▬▬ │                              CANVAS AREA                                   │
│ 0.5│                                                                            │
│────│                         (with ruler marks)                                 │
│ ▬  │                                                                            │
│ 0.5│                                                                            │
│────│                                                                            │
│ ∧  │                                                           [0°]             │
└────┴────────────────────────────────────────────────────────────────────────────┘
```

### Key Measurements
- Toolbar height: ~48-56px
- Pen box width: ~56-64px
- Panel width: ~280-320px
- Panel max height: ~600px (scrollable)

---

## 2. Top Toolbar

### 2.1 Layout Structure

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ [UNDO][REDO] │ [TOOLS...scrollable...] │ [CONFIG] │ [QUICK_ACCESS] │ [ACTIONS]  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Undo/Redo Section
| Button | Icon | State |
|--------|------|-------|
| Undo | ↶ (curved arrow left) | Disabled when no history |
| Redo | ↷ (curved arrow right) | Disabled when no future |

### 2.3 Tool Buttons (Scrollable)

Order from left to right:
| # | Tool | Icon | Long Press |
|---|------|------|------------|
| 1 | Yazı kalemi (Pen) | 🖊 | Opens Pen Panel |
| 2 | Vurgulayıcı (Highlighter) | Highlighter marker icon | Opens Highlighter Panel |
| 3 | Silgi (Eraser) | Eraser icon | Opens Eraser Panel |
| 4 | Kement (Lasso) | Lasso/loop icon | Opens Kement Panel |
| 5 | Alıntı (Quote) | Quote/citation icon | - |
| 6 | Resim (Image) | Image/picture icon | Opens Image Panel |
| 7 | Metin kutusu (Text) | T in box icon | - |
| 8 | Şekil (Shapes) | Shapes grid icon | Opens Shapes Panel |
| 9 | Çıkartma (Sticker) | Emoji/sticker icon | Opens Sticker Panel |
| 10 | Lazer (Laser) | Laser pointer icon | Opens Laser Panel |
| 11 | El yazısı (Handwriting) | Pen writing icon | - |
| 12 | Bant (Tape) | Tape/washi icon | - |

### 2.4 Config Button
- Icon: ⚙️ (gear)
- Action: Opens Toolbar Editor Panel

### 2.5 Quick Access Row (NEW)

Appears in toolbar when a drawing tool is selected:

```
┌─────────────────────────────────────────┐
│ [🔵][🔴][🟢][🔵][⚫] │ [•][●][⬤]      │
│     colors           │  thickness       │
└─────────────────────────────────────────┘
```

**Quick Colors**: 5 color chips matching current tool's palette
**Quick Thickness**: 3 dots (small, medium, large)

### 2.6 Right Action Buttons (NEW)

```
┌─────────────────────────────────────────┐
│ [📖] [🏠] [📑] [📤] [📐] [⚙️] [⋯]      │
└─────────────────────────────────────────┘
```

| Button | Icon | Action |
|--------|------|--------|
| Book | 📖 | Reader mode (placeholder) |
| Home | 🏠 | Home screen (placeholder) |
| Layers | 📑 | Layer panel (placeholder) |
| Export | 📤 | Export options (placeholder) |
| Grid | 📐 | Toggle grid visibility |
| Settings | ⚙️ | App settings (placeholder) |
| More | ⋯ | More options (placeholder) |

---

## 3. Pen Box (Left Sidebar)

### 3.1 Structure

```
┌────┐
│ 📑 │ ← Collapse/expand button
├────┤
│ ▶  │ ← Preset 1 (selected)
│ 0.3│
├────┤
│ ▬▬ │ ← Preset 2
│ 0.5│
├────┤
│ ▬  │ ← Preset 3
│ 0.5│
├────┤
│    │ ← Empty slots...
│ +  │
├────┤
│ ∧  │ ← Scroll up indicator
└────┘
```

### 3.2 Preset Slot Components

Each preset slot shows:
1. **Nib preview** (top): Shape visualization
2. **Color indicator**: Small colored dot or the nib itself is colored
3. **Thickness label** (bottom): e.g., "0.3", "0.5"

### 3.3 Slot States
- **Empty**: Shows "+" icon, lighter background
- **Filled**: Shows nib preview + thickness
- **Selected**: Blue border/highlight

### 3.4 Interactions
- **Tap**: Select preset, apply settings to current tool
- **Long press**: Show options (Edit, Delete)
- **Tap on +**: Add current tool settings as new preset

---

## 4. Pen Settings Panel

### 4.1 Layout (Tükenmez Kalem / Ballpoint Pen)

```
┌─────────────────────────────────────────┐
│         Tükenmez kalem            [×]   │
├─────────────────────────────────────────┤
│              〰️                          │  ← Live stroke preview
│  [🖊️] [🖋️] [✏️] [🖌️]                    │  ← 4 pen type icons
│   ●    ○    ○    ○                      │  ← Selection indicators
├─────────────────────────────────────────┤
│  Kalınlık                     0,30mm    │
│  [━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Vuruş sabitleme                  20%   │
│  [━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Renk                                   │
│  [✓🔵] [🔴] [🔵] [🟢] [🟡]              │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │      Kalem kutusuna ekle        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 4.2 Components

| Component | Type | Range/Options |
|-----------|------|---------------|
| Stroke preview | Custom painter | Shows current settings |
| Pen type selector | 4 icon buttons | Ballpoint, Fountain, Pencil, Brush |
| Kalınlık (Thickness) | Slider | 0.10mm - 5.00mm |
| Vuruş sabitleme (Stabilization) | Slider | 0% - 100% |
| Renk (Color) | Color chips | 5 default colors |
| Add to Pen Box | Button | Full width |

### 4.3 Pen Type Variations

| Type | Turkish | Icon Style |
|------|---------|------------|
| Ballpoint | Tükenmez kalem | Simple pen |
| Fountain | Dolma kalem | Fancy pen with nib |
| Pencil | Kurşun kalem | Pencil shape |
| Brush | Fırça | Brush shape |

---

## 5. Highlighter Panel

### 5.1 Layout (Vurgulayıcı)

```
┌─────────────────────────────────────────┐
│           Vurgulayıcı             [×]   │
├─────────────────────────────────────────┤
│                                         │
│  [🖍️💛] [🖍️🧡] [🖍️💚]                  │  ← 3 marker previews
│     ●                                   │  ← Selected indicator
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │  ← Thickness preview bar
├─────────────────────────────────────────┤
│  Kalınlık                     5,00mm    │
│  [━━━━━━━━━━━━━━━●━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Düz çizgi çiz                    [○]   │  ← Toggle switch
├─────────────────────────────────────────┤
│  Renk                                   │
│  [✓💛] [🧡] [💚] [💙] [💜]              │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │      Kalem kutusuna ekle        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 5.2 Components

| Component | Type | Range/Options |
|-----------|------|---------------|
| Marker preview | 3 marker icons | Shows 3 color variants |
| Thickness bar | Visual preview | Shows current thickness |
| Kalınlık | Slider | 1.00mm - 20.00mm |
| Düz çizgi çiz | Toggle | Straight line mode |
| Renk | Color chips | Semi-transparent colors |

---

## 6. Eraser Panel

### 6.1 Layout (Silgi)

```
┌─────────────────────────────────────────┐
│              Silgi                [×]   │
├─────────────────────────────────────────┤
│  [⬜]      [⬜✓]      [⬜]              │
│  Piksel    Çizgi     Dairesel           │
│  silme     silme     seçimle            │
│                      silme              │
├─────────────────────────────────────────┤
│  Boyut                        3,00mm    │
│  [━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Basınca duyarlı silgi            [○]   │
├─────────────────────────────────────────┤
│  Sadece vurgulayıcıyı sil         [○]   │
├─────────────────────────────────────────┤
│  Sadece bantı sil                 [○]   │
├─────────────────────────────────────────┤
│  Oto kaldır                   [?] [○]   │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │      Mevcut sayfayı temizle     │   │  ← Red/warning color
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 6.2 Eraser Modes

| Mode | Turkish | Icon | Premium |
|------|---------|------|---------|
| Pixel | Piksel silme | Dotted square | Free |
| Stroke | Çizgi silme | Line through | Free |
| Lasso | Dairesel seçimle silme | Circle selection | **PREMIUM** 🔒 |

### 6.3 Options

| Option | Turkish | Default |
|--------|---------|---------|
| Pressure sensitive | Basınca duyarlı silgi | OFF |
| Erase only highlighter | Sadece vurgulayıcıyı sil | OFF |
| Erase only tape | Sadece bantı sil | OFF |
| Auto lift | Oto kaldır | OFF |

---

## 7. Shapes Panel

### 7.1 Layout (Şekil)

```
┌─────────────────────────────────────────┐
│              Şekil                [×]   │
├─────────────────────────────────────────┤
│  Favorilere eklemek için şekli          │
│  sürükleyin                             │
│  ┌─────────────────────────────────┐   │
│  │  [saved favorites here]         │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  [─] [〰] [⌒] [┅] [→] [↔]              │  ← Row 1: Lines
│  [↗] [∠] [+] [⊥] [{] [△]              │  ← Row 2: Lines/Symbols
│  [△] [◺] [▷] [□] [▭] [◿]              │  ← Row 3: Basic shapes
│  [☐] [▯] [◇] [⬠] [⬡] [☆]              │  ← Row 4: More shapes
├─────────────────────────────────────────┤
│  Kontur kalınlığı              0,30mm   │
│  [━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Kontur rengi                           │
│  [✓⚫] [🔴] [🔵] [🟢] [🟡]              │
├─────────────────────────────────────────┤
│  Şekil dolgusu                    [○]   │
│  (Fill color picker appears when ON)    │
└─────────────────────────────────────────┘
```

### 7.2 Shape Grid (24 shapes)

**Row 1 - Lines:**
| Shape | Name | Code |
|-------|------|------|
| ─ | Straight line | `line` |
| 〰 | Wavy line | `wavyLine` |
| ⌒ | Curved line | `curvedLine` |
| ┅ | Dashed line | `dashedLine` |
| → | Arrow right | `arrowRight` |
| ↔ | Double arrow | `doubleArrow` |

**Row 2 - Lines/Symbols:**
| Shape | Name | Code |
|-------|------|------|
| ↗ | Curved arrow | `curvedArrow` |
| ∠ | Angle | `angle` |
| + | Plus | `plus` |
| ⊥ | T-shape | `tShape` |
| { | Bracket | `bracket` |
| △ | Triangle arrow | `triangleArrow` |

**Row 3 - Basic Shapes:**
| Shape | Name | Code |
|-------|------|------|
| △ | Triangle up | `triangleUp` |
| ◺ | Triangle corner | `triangleCorner` |
| ▷ | Triangle right | `triangleRight` |
| □ | Square filled | `squareFilled` |
| ▭ | Rectangle | `rectangle` |
| ◿ | Right triangle | `rightTriangle` |

**Row 4 - More Shapes:**
| Shape | Name | Code |
|-------|------|------|
| ☐ | Square outline | `squareOutline` |
| ▯ | Rectangle outline | `rectangleOutline` |
| ◇ | Diamond | `diamond` |
| ⬠ | Pentagon | `pentagon` |
| ⬡ | Hexagon | `hexagon` |
| ☆ | Star | `star` |

---

## 8. Sticker Panel

### 8.1 Layout

```
┌─────────────────────────────────────────┐
│  Text  Sign  Daily  Natural  EM...      │  ← Scrollable tabs
│              ━━━━━                      │  ← Active indicator
├─────────────────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │ OK │ │ToDo│ │YES │ │ NO │           │  ← Row 1
│  └────┘ └────┘ └────┘ └────┘           │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │TODO│ │Dead│ │TODO│ │ ☐  │           │  ← Row 2
│  └────┘ └────┘ └────┘ └────┘           │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │ZZZ │ │ ⭐ │ │ 👍 │ │ ❤️ │           │  ← Row 3
│  └────┘ └────┘ └────┘ └────┘           │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │ ✓  │ │ 🌵 │ │ ✏️ │ │ 🍦 │           │  ← Row 4
│  └────┘ └────┘ └────┘ └────┘           │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │     ✓ Seç                       │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 8.2 Categories

| Tab | Turkish | Content Type |
|-----|---------|--------------|
| Text | Text | Text-based stickers |
| Sign | Sign | Signature/stamp stickers |
| Daily | Daily | Daily planning stickers |
| Natural | Natural | Nature-themed stickers |
| EMOJI | EMOJI | Emoji stickers |

### 8.3 Daily Category Stickers

Row 1: Speech bubbles (OK, To Do:, YES, NO)
Row 2: Planning (TO DO:, Deadline, TO DO, Checklist)
Row 3: Symbols (ZZZ, Star, Thumbs up, Heart)
Row 4: Misc (Checkmark, Cactus, Pencil, Ice cream)

---

## 9. Image Panel

### 9.1 Layout (Resim)

```
┌─────────────────────────────────────────┐
│           Resim              Seç   [×]  │
├─────────────────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │    │ │    │ │    │ │    │           │  ← Recent images
│  └────┘ └────┘ └────┘ └────┘           │    (from document)
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │    │ │    │ │    │ │    │           │
│  └────┘ └────┘ └────┘ └────┘           │
├─────────────────────────────────────────┤
│  [🖼] Albümden ekle                     │
├─────────────────────────────────────────┤
│  [📷] Fotoğraf çek                      │
└─────────────────────────────────────────┘
```

---

## 10. Lazer Pointer Panel

### 10.1 Layout (Lazer işaretleyici)

```
┌─────────────────────────────────────────┐
│       Lazer işaretleyici          [×]   │
├─────────────────────────────────────────┤
│       [〰️]           [●]               │
│       Çizgi          Nokta              │  ← Mode selector
│         ●                               │
├─────────────────────────────────────────┤
│  Kalınlık                     0,50mm    │
│  [━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Süre                            2s     │  ← NEW: Duration
│  [●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │
├─────────────────────────────────────────┤
│  Renk                                   │
│  [🔵] [🟢] [✓🔵] [🟣] [🟡]              │
└─────────────────────────────────────────┘
```

### 10.2 Components

| Component | Type | Range |
|-----------|------|-------|
| Mode | Segment (2 options) | Çizgi (Line), Nokta (Dot) |
| Kalınlık | Slider | 0.10mm - 5.00mm |
| Süre (Duration) | Slider | 0.5s - 5.0s |
| Renk | Color chips | 5 colors |

---

## 11. Kement (Lasso) Panel

### 11.1 Layout

```
┌─────────────────────────────────────────┐
│            Kement                 [×]   │
├─────────────────────────────────────────┤
│    [○ ⭕]         [□]                   │
│    Serbest       Dikdörtgen             │
│    kement        kement                 │
│       ●                                 │
├─────────────────────────────────────────┤
│  Seçilebilir                            │
├─────────────────────────────────────────┤
│  Şekil                           [●━]   │
├─────────────────────────────────────────┤
│  Resim/Çıkartma                  [●━]   │
├─────────────────────────────────────────┤
│  Bant                            [●━]   │
├─────────────────────────────────────────┤
│  Metin kutusu                    [●━]   │
├─────────────────────────────────────────┤
│  El yazısı                       [●━]   │
├─────────────────────────────────────────┤
│  Vurgulayıcı                     [━○]   │  ← Default OFF
├─────────────────────────────────────────┤
│  Bağlantı                        [●━]   │
├─────────────────────────────────────────┤
│  Etiket                          [●━]   │
└─────────────────────────────────────────┘
```

### 11.2 Lasso Modes

| Mode | Turkish | Icon |
|------|---------|------|
| Freeform | Serbest kement | Freeform lasso shape |
| Rectangle | Dikdörtgen kement | Rectangle selection |

### 11.3 Selectable Types

| Type | Turkish | Default |
|------|---------|---------|
| Shape | Şekil | ON |
| Image/Sticker | Resim/Çıkartma | ON |
| Tape | Bant | ON |
| Text box | Metin kutusu | ON |
| Handwriting | El yazısı | ON |
| Highlighter | Vurgulayıcı | **OFF** |
| Link | Bağlantı | ON |
| Label | Etiket | ON |

---

## 12. Toolbar Editor

### 12.1 Layout (Özel araç çubuğu)

```
┌─────────────────────────────────────────┐
│  Kapat    Özel araç çubuğu   Tamamlandı │
├─────────────────────────────────────────┤
│  Araç çubuğunu kişisel tercihlere       │
│  göre özelleştirin                      │
├─────────────────────────────────────────┤
│  Gösterilen araçlar                     │
├─────────────────────────────────────────┤
│  [👁] [🖊️] Yazı kalemi            [≡]   │
│  [👁] [✏️] Vurgulayıcı            [≡]   │
│  [👁] [🗑] Silgi                  [≡]   │
│  [👁] [⭕] Kement                 [≡]   │
│  [👁] [📝] Alıntı                 [≡]   │
│  [👁] [🖼] Resim                  [≡]   │
│  [👁] [T] Metin kutusu            [≡]   │
├─────────────────────────────────────────┤
│  Gizli araçlar                          │
├─────────────────────────────────────────┤
│          Varsayılan ayarlara geri yükle │
└─────────────────────────────────────────┘
```

### 12.2 Components

| Component | Function |
|-----------|----------|
| Eye icon | Toggle visibility |
| Tool icon | Visual identifier |
| Tool name | Turkish localized |
| Drag handle | Reorder tools |
| Hidden section | Tools toggled off |
| Reset button | Restore defaults |

---

## 13. State Management

### 13.1 Required Providers

```dart
// Existing (keep as-is)
currentToolProvider
activePanelProvider
penSettingsProvider (family)
highlighterSettingsProvider
eraserSettingsProvider
shapesSettingsProvider
penBoxPresetsProvider
selectedPresetIndexProvider
toolbarConfigProvider
canUndoProvider
canRedoProvider

// NEW - Add these
lassoSettingsProvider       // LassoSettings
laserSettingsProvider       // UPDATE: add mode, duration
gridVisibilityProvider      // bool
quickColorsProvider         // List<Color>
quickThicknessProvider      // List<double>
```

### 13.2 New Data Models

```dart
// Lasso Settings
class LassoSettings {
  final LassoMode mode;
  final Map<SelectableType, bool> selectableTypes;
}

enum LassoMode { freeform, rectangle }

enum SelectableType {
  shape,
  imageSticker,
  tape,
  textBox,
  handwriting,
  highlighter,
  link,
  label,
}

// Laser Settings (updated)
class LaserSettings {
  final LaserMode mode;      // NEW
  final double thickness;
  final double duration;     // NEW
  final Color color;
}

enum LaserMode { line, dot }

// Shape Type (expanded)
enum ShapeType {
  // Lines
  line, wavyLine, curvedLine, dashedLine, arrowRight, doubleArrow,
  curvedArrow, angle, plus, tShape, bracket, triangleArrow,
  // Shapes
  triangleUp, triangleCorner, triangleRight, squareFilled, 
  rectangle, rightTriangle, squareOutline, rectangleOutline,
  diamond, pentagon, hexagon, star,
}
```

---

## 14. Interactions

### 14.1 Tool Selection
- **Tap**: Select tool, close any open panel
- **Long press**: Select tool AND open its settings panel

### 14.2 Panel Behavior
- Only ONE panel open at a time
- Tap outside panel → close panel
- Panel anchors near the triggering button

### 14.3 Pen Box Interactions
- **Tap preset**: Select and apply settings
- **Long press preset**: Show options menu (Edit, Delete)
- **Tap empty slot (+)**: Add current settings as preset

### 14.4 Quick Access (Toolbar)
- **Tap color chip**: Change tool color immediately
- **Tap thickness dot**: Change tool thickness immediately
- Changes apply to current tool without opening panel

---

## Implementation Priority

### Critical (Must complete first)
1. ❌ Kement Panel (completely new)
2. ❌ Lazer Panel update (mode + duration)
3. ❌ Toolbar right action buttons
4. ❌ Toolbar quick access row

### High Priority
5. ❌ Shapes panel expansion (24 shapes)
6. ❌ New providers (lasso, laser update, grid, quick access)

### Medium Priority
7. ⚠️ Pen panel preview update
8. ⚠️ Highlighter panel preview update
9. ⚠️ Sticker category update

### Testing
10. ❌ Widget tests for all new components
11. ❌ Golden tests for new panels
12. ❌ Provider tests for new state

---

*Document created: 2025-01-13*
*Reference: Elyanotes/Fenci app screenshots (10 images)*

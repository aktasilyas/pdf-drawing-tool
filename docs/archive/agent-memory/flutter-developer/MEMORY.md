# Flutter Developer Memory

## Phase M1: Responsive Toolbar Implementation

### Step 2: MediumToolbar (600-839px)
- **Tool grouping pattern**: Pen tools (pencil, hardPencil, ballpointPen, gelPen, dashedPen, brushPen, rulerPen) and highlighter tools (highlighter, neonHighlighter) are grouped as single buttons
- **_toolsWithPanel set**: Defines which tools have settings panels
- **_getGroupedVisibleTools()**: Collapses tool groups, shows current tool icon for active group
- **_isToolSelected()**: Handles group selection logic
- **ToolbarOverflowMenu**: Shows hidden tools as PopupMenuButton with icon + display name

### Step 3: CompactBottomBar (Phone <600px)
- **Architecture**: Bottom bar placed in Scaffold.bottomNavigationBar, not in Column with AdaptiveToolbar
- **Panel strategy**: Panels open as modal bottom sheets (showToolPanelSheet), not AnchoredPanel overlays
- **CompactBottomBar**: Reuses same tool grouping pattern as MediumToolbar, max 5 visible tools
- **showToolPanelSheet**: DraggableScrollableSheet wrapping buildActivePanel from drawing_screen_panels.dart
- **DrawingScreen changes**:
  - Added isCompactMode check (screenWidth < 600)
  - bottomNavigationBar: isCompactMode ? CompactBottomBar : null
  - _handlePanelChange: Early return in compact mode (panels handled via bottom sheets, not overlays)
- **Import optimization**: Use barrel exports (toolbar.dart) instead of direct file imports

## Key Patterns

### Responsive Breakpoints
- <600px: Compact (phone) - bottom bar + bottom sheet panels
- 600-839px: Medium (tablet portrait) - horizontal toolbar + overflow menu
- >=840px: Expanded (tablet landscape/desktop) - full horizontal toolbar

### Tool Grouping Logic
```dart
// Pen tools share one button, show current tool's icon when in pen group
final isPenGroup = _penTools.contains(tool);
customIcon: isPenGroup && _penTools.contains(currentTool)
    ? ToolButton.getIconForTool(currentTool)
    : null
```

### Panel Opening Pattern
- **Tablet/Desktop**: AnchoredPanel overlay anchored to tool button
- **Phone**: Modal bottom sheet with DraggableScrollableSheet
- **Trigger**: Second tap on selected tool OR chevron tap (if hasPanel)

## Import Rules (drawing_ui package)
- Always use barrel exports: `toolbar/toolbar.dart` not direct file paths
- Avoid unused imports - analyzer will warn
- DrawingTheme imported from `theme/theme.dart` barrel
- `elyanotes_icons.dart` is re-exported by `theme/theme.dart` -- do NOT add both imports
- `flutter/material.dart` re-exports `debugPrint` -- do NOT add separate `foundation.dart` import
- `flutter/foundation.dart` re-exports `dart:typed_data` -- adding foundation makes typed_data redundant

## Icon System
- All icons use `PhosphorIcon` widget + `ElyanotesIcons.*` constants
- Never use Material `Icons.*` (exception: `Icons.format_bold/italic/underlined`)
- Use `ElyanotesIcons.iconForTool(ToolType)` for tool-to-icon mapping
- `PhosphorIcon` is NOT const-compatible; remove `const` when replacing `const Icon(Icons.*)`

## Reader Mode (Phase M3 Adim 4)
- `readerModeProvider`: Simple `StateProvider<bool>`, not persisted
- Drawing disabled via `isReadOnly` flag on `DrawingCanvas` -> sets `enablePointerEvents = false`
- Pan/zoom always active: `GestureDetector.onScale*` handlers are not gated by `enablePointerEvents`
- Toolbar hidden with `AnimatedSize(duration: 200ms, curve: easeInOut)` wrapping `AdaptiveToolbar`
- "Salt okunur" badge: `secondaryContainer` color, `onSecondaryContainer` text, 12px border radius
- Grid toggle hidden in reader mode, sidebar still accessible

## Page Indicator Bar (Phase M3 Adim 5)
- `page_indicator_bar.dart`: 131 lines (max 150 enforced)
- Auto-hide: `AnimationController` + `Timer` + `FadeTransition`
- `ref.listen` inside `build()` to show bar on page changes
- Swipe in reader mode: GestureDetector wrapping canvasStack in `buildDrawingCanvasArea`
- Velocity threshold: 300 (left swipe = next, right swipe = previous)
- Single-page: returns `SizedBox.shrink()`

## Key File Line Counts (watch 300 limit)
- `drawing_screen.dart`: ~305 lines (slightly over limit)
- `top_navigation_bar.dart`: ~262 lines
- `drawing_screen_layout.dart`: ~285 lines (after sidebar grid redesign)

## Page Sidebar (GoodNotes-style 2-column grid)
- `kPageSidebarWidth = 240` constant in `drawing_screen_layout.dart` (line 20)
- `buildPageSidebar`: GridView.builder with crossAxisCount: 2, childAspectRatio: 0.58
- `_buildGridThumbnailItem`: Expanded thumbnail + Row(Spacer, page number, "..." more icon)
- `_buildAddPageButton`: Column with "+" icon + "Sayfa ekle" text, full-width bordered container
- Thumbnail dimensions: width 102, height 140
- Selected: primary border (2px), shadow alpha 0.12; Normal: outlineVariant (0.5px), alpha 0.05
- `drawing_screen.dart` uses `kPageSidebarWidth` for all sidebar width references (no hardcoded 140)

## Settings Panel Design Pattern (pen/highlighter/eraser)
All tool settings panels follow this consistent layout:
1. `Padding(EdgeInsets.all(16))` outer padding
2. Title: `fontSize: 16, fontWeight: w600, color: cs.onSurface`
3. `SizedBox(height: 16)` then Preview: `SizedBox(height: 100)` + `CustomPaint`
4. `SizedBox(height: 16)` then Type Selector: 40x40 pill cards, `BorderRadius.circular(10)`
   - Selected: `cs.primary` bg, `cs.onPrimary` icon; Deselected: transparent bg, `cs.onSurfaceVariant` icon
5. `SizedBox(height: 20)` then `GoodNotesSlider` (shared widget)
6. `SizedBox(height: 8)` between sliders/toggles, `CompactToggle` (shared widget)
- CustomPainter logic can be extracted to separate `*_painter.dart` files to stay under 300 lines
- `PhosphorIconsLight` for deselected, `PhosphorIconsRegular` for selected icon states

## Ruler Overlay Architecture
- See [ruler-overlay.md](ruler-overlay.md) for coordinate system details.
- Key lesson: GestureDetector must be OUTSIDE Transform.rotate to get screen-space deltas.
- Ruler dimensions are public constants in `ruler_overlay.dart`, imported by gesture handlers.
- Rotation pivot = `rulerPos + Offset(0, rulerContentHeight / 2)` (NOT `rulerBodyHeight / 2`).

## Flutter Transform Patterns
- `Transform.rotate` with `transformHitTests: true` (default) correctly transforms hit tests even when GestureDetector wraps it from outside.
- `details.globalPosition` in drag callbacks is always in screen coordinates regardless of widget tree transforms.
- Use `RenderBox.localToGlobal()` via a `GlobalKey` to resolve widget-local coordinates to global screen coordinates.

## Selection Capture with Background
- `SelectionCaptureService.captureSelection` supports optional `PageBackground`, `pdfImageBytes`, `pageSize`
- PDF image bytes must be decoded to `ui.Image` before canvas recording (async `ui.instantiateImageCodec`)
- Background pattern rendered with `canvas.save()/clipRect()/restore()` to prevent bleeding outside selection
- `Uint8List` requires explicit `import 'dart:typed_data'` -- `flutter/material.dart` alone does NOT export it
- PDF cache key format: `"filePath|pageNumber"` (1-based page number)

## DrawingShadows Token System
- File: `packages/drawing_ui/lib/src/theme/drawing_shadows.dart`
- Methods: `.panel(brightness)`, `.floating(brightness)`, `.selection(brightness, [tintColor])`, `.toolbar(brightness)`, `.page(brightness)`, `.none`
- Import: `import 'package:drawing_ui/src/theme/drawing_shadows.dart';`
- See [design-system-patterns.md](design-system-patterns.md) for color/shadow migration rules
- Color migration: `Colors.black` shadow -> `colorScheme.shadow`; overlay/scrim -> `colorScheme.scrim.withValues(alpha:X)`; `Colors.grey.shade200` bg -> `colorScheme.surfaceContainerHighest`; `Colors.grey.shade300` border -> `colorScheme.outlineVariant`
- KEEP: checkerboard Paint colors, contrast icons on colored chips, semantic colors

## Design System Migration (GoogleFonts -> textTheme)
- Completed migration of `GoogleFonts.sourceSerif4(...)` -> `Theme.of(context).textTheme.*` in all 14 panel files + page_options_panel.dart call site
- Panels dir is now 100% GoogleFonts-free: `packages/drawing_ui/lib/src/panels/`
- Remaining GoogleFonts refs exist in `widgets/` dir (not yet migrated)
- Mapping: fontSize 11->labelSmall, 12/w400->bodySmall, 12/w500+->labelMedium, 13/w600->titleSmall, 14->bodyMedium, 15->bodyMedium(fontSize:15), 16/w600->titleMedium(fontSize:16,fontWeight:w600), 18+->titleMedium(fontSize:18), 24->headlineSmall, 28->headlineMedium
- Drop fontSize when it matches the textTheme style's default; drop fontWeight when it matches base (labelSmall=w500, bodySmall=w400, titleSmall=w500)
- Use `?.copyWith(...)` since textTheme properties are nullable
- For helper functions without BuildContext (e.g. `pageOptionsChevronTrailing`), pass `TextTheme?` as optional param
- Pre-existing errors in widgets/ dir (GoogleFonts refs, SelectionPainter missing selectionColor) unrelated to migration

## Selection Color Migration (Material Blue -> colorScheme.primary)
- Completed: All hardcoded `Color(0xFF2196F3)` / `Color(0xFF448AFF)` replaced in drawing_ui/lib/src/
- Pattern for CustomPainters: Add `Color selectionColor` constructor param, pass `Theme.of(context).colorScheme.primary` from widget
- For static Paint objects using selection color: convert from `static final` to `late final` instance fields
- Alpha variants: `selectionColor.withValues(alpha: 0.08)` for 0x15, `withValues(alpha: 0.06)` for 0x10
- Excluded files: `drawing_colors.dart`, `toolbar_config.dart` (drawing palette), `laser_painter.dart` (rainbow)
- Default fallback for non-widget contexts: `Color(0xFF10B981)` (Emerald Green primary)

## Testing Notes
- Pre-existing failures: ~45 tests (PDF, canvas, toolbar icon matching) - expected
- Pre-existing warnings: 3 unnecessary_non_null_assertion in pdf_render_provider.dart
- New tests should verify responsive behavior at different breakpoints
- When adding required painter params, update test files too (selection_painter_test, text_painter_test)
- Analyze before commit: `cmd.exe /c "cd /d C:\Users\aktas\source\repos\starnote_drawing_workspace && dart analyze packages/drawing_ui"`

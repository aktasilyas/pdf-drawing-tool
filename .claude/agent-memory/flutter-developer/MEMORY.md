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
- `starnote_icons.dart` is re-exported by `theme/theme.dart` -- do NOT add both imports

## Icon System
- All icons use `PhosphorIcon` widget + `StarNoteIcons.*` constants
- Never use Material `Icons.*` (exception: `Icons.format_bold/italic/underlined`)
- Use `StarNoteIcons.iconForTool(ToolType)` for tool-to-icon mapping
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

## Testing Notes
- Pre-existing failures: ~45 tests (PDF, canvas, toolbar icon matching) - expected
- Pre-existing warnings: 3 unnecessary_non_null_assertion in pdf_render_provider.dart
- New tests should verify responsive behavior at different breakpoints
- Analyze before commit: `cmd.exe /c "cd /d C:\Users\aktas\source\repos\starnote_drawing_workspace && dart analyze packages/drawing_ui"`

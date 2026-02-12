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

## Testing Notes
- Pre-existing failures: ~45 tests (PDF, canvas, toolbar icon matching) - expected
- New tests should verify responsive behavior at different breakpoints
- Analyze before commit: `dart analyze packages/drawing_ui/lib/src/...`

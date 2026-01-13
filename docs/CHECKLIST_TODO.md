# StarNote Drawing Library - Development Checklist

> **Single Source of Truth** for all development progress.  
> Update this file as features are implemented. Every PR should reference items here.
> 
> **Last Updated**: 2026-01-13 (Phase 1 UI Complete)

---

## Architectural Constraints (MUST READ)

### Library vs App Layer Separation

| Concern | Library Allowed? | App Layer Only? |
|---------|-----------------|-----------------|
| Drawing logic | ✅ | |
| Tool abstractions | ✅ | |
| Undo/redo commands | ✅ | |
| Serialization interfaces | ✅ | |
| Premium/Free gating | ❌ | ✅ |
| Subscription logic | ❌ | ✅ |
| AI integration | ❌ | ✅ |
| Database implementation | ❌ | ✅ |
| Network calls | ❌ | ✅ |
| Analytics | ❌ | ✅ |

**`drawing_core` and `drawing_ui` MUST remain premium-agnostic, AI-agnostic, and persistence-agnostic.**

---

## Phase 0: Scaffolding & Architecture Contracts ✅ COMPLETE

### Project Structure
- [x] Create melos workspace configuration
- [x] Set up `drawing_core` package skeleton
- [x] Set up `drawing_ui` package skeleton
- [x] Set up `drawing_toolkit` package skeleton
- [x] Set up `example_app` skeleton
- [x] Define dependency direction rules

### Documentation
- [x] Create `docs/ARCHITECTURE.md`
- [x] Create `docs/PERFORMANCE_STRATEGY.md`
- [x] Create this `CHECKLIST_TODO.md`
- [x] Create `docs/DESIGN_SYSTEM.md`
- [x] Create `docs/PROJECT_OVERVIEW.md`
- [ ] Add inline documentation templates to public APIs
- [x] Add "Monetization & Premium Strategy" section to ARCHITECTURE.md
- [x] Add "AI Integration Strategy" section to ARCHITECTURE.md
- [x] Add "AI Performance Considerations" section to PERFORMANCE_STRATEGY.md

### Core Interfaces (Stubs)
- [x] `DrawingTool` base interface
- [x] `Stroke` model
- [x] `DrawingDocument` model
- [x] `HistoryManager` interface
- [x] `ToolSettings` interfaces
- [x] `SerializationCodec` interface

### UI Interfaces (Stubs)
- [x] `DrawingCanvas` widget stub
- [x] `ToolbarWidget` stub
- [x] `PenBoxWidget` stub
- [x] `ToolSettingsPanel` base stub
- [x] Painter base classes

---

## Phase 1: UI Skeleton (Mocked State) 🔄 IN PROGRESS

> **Reference**: See `docs/PHASE1_UI_REFERENCE.md` for exact UI specifications.

### Top Toolbar - Basic ✅ DONE
- [x] Toolbar container widget
- [x] Tool button component (reusable)
- [x] Undo button (disabled state)
- [x] Redo button (disabled state)
- [x] Pen tool button
- [x] Highlighter button
- [x] Eraser button
- [x] Shapes button
- [x] Text tool button
- [x] Sticker button
- [x] Image insert button
- [x] Settings button
- [x] Tool selection state management (mock)
- [x] Scrollable tool row for overflow

### Top Toolbar - Extended ✅ DONE
- [x] **Kement (Lasso) tool button**
- [x] **Lazer pointer tool button**
- [x] **Right action buttons section**:
  - [x] Book/Reader mode button (placeholder)
  - [x] Home button (placeholder)
  - [x] Layers button (placeholder)
  - [x] Export button (placeholder)
  - [x] Grid toggle button (functional)
  - [x] More options button (placeholder)
- [x] **Quick access row** (appears when tool selected):
  - [x] 5 quick color chips
  - [x] 3 quick thickness dots
- [x] Divider between tool section and right section

### Pen Box (Left Sidebar) ✅ DONE
- [x] Pen box container widget
- [x] Pen preset slot widget
- [x] Nib preview renderer (circle, ellipse, rect)
- [x] Color indicator
- [x] Thickness indicator
- [x] Selected state styling
- [x] Support for 16 preset slots
- [x] Scroll behavior for overflow
- [x] Add preset button
- [x] Long press for edit/delete

### Tool Settings Panels - Core ✅ DONE
- [x] Panel base component (anchored overlay)
- [x] Panel open/close animation
- [x] Single-panel-at-a-time logic

### Pen Settings Panel ✅ DONE
- [x] Nib preview widget
- [x] Thickness slider
- [x] Stabilization slider
- [x] Color chips grid
- [x] "Add to Pen Box" button
- [x] **Pen type visual selector** (4 pen icons with selection)
- [x] **Live stroke preview** at top

### Highlighter Settings Panel ✅ DONE
- [x] Thickness slider
- [x] Straight-line toggle
- [x] Color chips
- [x] "Add to Pen Box" button
- [x] **Marker visual preview** (3 marker icons)
- [x] **Thickness bar preview**

### Eraser Settings Panel ✅ DONE
- [x] Mode selector (pixel/stroke/lasso)
- [x] Size slider
- [x] Pressure toggle
- [x] "Erase only highlighter" toggle
- [x] "Erase band only" toggle
- [x] Auto-lift toggle
- [x] Clear page button
- [x] Lock icon on Lasso mode (premium placeholder)

### Shapes Settings Panel ✅ DONE (24 shapes)
- [x] Shape grid (24 shapes)
- [x] Stroke thickness slider
- [x] Stroke color picker
- [x] Fill toggle
- [x] Fill color picker (conditional)
- [x] **Expanded shape grid (24 shapes)**:
  - [x] Lines: straight, wavy, curved, dashed, arrow, double-arrow
  - [x] Lines: curved arrow, angled, plus, T-shape, bracket, triangle-arrow
  - [x] Shapes: triangle (3 variants), square, rectangle, right-triangle
  - [x] Shapes: square-outline, rectangle-outline, diamond, pentagon, hexagon, star
- [x] **Favorites placeholder** ("Drag shape to add to favorites")
- [ ] **Saved favorites row** (deferred)

### Sticker Panel ⚠️ NEEDS UPDATE
- [x] Category tabs
- [x] Sticker grid
- [x] Select CTA
- [x] Premium stickers (locked)
- [ ] **Updated tab names**: Text, Sign, Daily, Natural, EMOJI
- [ ] **Daily category stickers** (OK, To Do, YES, NO, etc.)

### Image Panel ✅ DONE
- [x] Recent images grid
- [x] "Add from Album" button
- [x] "Take Photo" button
- [x] Cloud images (locked premium)

### Lazer Pointer Panel ✅ DONE
- [x] **Mode selector**: Çizgi (Line) / Nokta (Dot)
- [x] **Thickness slider** (0.10mm - 5.00mm)
- [x] **Duration slider** (0.5s - 5.0s)
- [x] **Color chips** (5 colors)

### Kement (Lasso Selection) Panel ✅ DONE
- [x] **Panel container** with title "Kement"
- [x] **Mode selector**: Serbest kement / Dikdörtgen kement
- [x] **Selectable types section** with 8 toggles:
  - [x] Şekil (Shape) - default ON
  - [x] Resim/Çıkartma (Image/Sticker) - default ON
  - [x] Bant (Tape) - default ON
  - [x] Metin kutusu (Text box) - default ON
  - [x] El yazısı (Handwriting) - default ON
  - [x] Vurgulayıcı (Highlighter) - default OFF
  - [x] Bağlantı (Link) - default ON
  - [x] Etiket (Label) - default ON

### Custom Toolbar Editor ✅ DONE
- [x] Reorderable tool list
- [x] Visibility toggles
- [x] Reset defaults button
- [x] Done/Close button

### AI Assistant Panel ✅ DONE (mock only)
- [x] Text input field for user question
- [x] "Ask" submit button
- [x] Response display area (scrollable)
- [x] Loading indicator placeholder
- [x] Close button
- [x] Premium badge indicator
- [x] Mock AI response data
- [x] Selection context indicator
- [x] Quick suggestion chips

### Mock Canvas ✅ DONE
- [x] Grid pattern background
- [x] Current tool display
- [x] Cursor indicator
- [x] Press state visual feedback
- [x] Placeholder message

### State Management ✅ DONE
- [x] Set up Riverpod providers structure
- [x] `currentToolProvider`
- [x] `toolSettingsProvider` family
- [x] `toolbarConfigProvider`
- [x] `penBoxPresetsProvider`
- [x] `highlighterSettingsProvider`
- [x] `eraserSettingsProvider`
- [x] `shapesSettingsProvider`
- [x] `selectedPresetIndexProvider`
- [x] `activePanelProvider`
- [x] `canUndoProvider` / `canRedoProvider` (mock)
- [x] **`lassoSettingsProvider`** (LassoMode, SelectableType toggles)
- [x] **`laserSettingsProvider`** (mode, thickness, duration, color)
- [x] **`gridVisibilityProvider`** (bool, default true)
- [x] **`quickColorsProvider`** (5 colors)
- [x] **`quickThicknessProvider`** (3 values: 1.0, 2.5, 5.0)

### Premium UI Indicators ✅ DONE
- [x] `LockedOverlay` widget component
- [x] `PremiumBadge` widget
- [x] Lock icon on premium features
- [x] Premium indicator on eraser lasso mode
- [x] Premium stickers section
- [x] Premium cloud images section

### Responsive Layout
- [x] Tablet landscape layout (primary)
- [ ] Tablet portrait adaptation
- [ ] Phone layout (condensed toolbar)

### Tests - Phase 1 ✅ DONE
- [x] `toolbar_test.dart` - Toolbar widget tests
- [x] `pen_box_test.dart` - Pen box widget tests
- [x] `panels_test.dart` - Panel widget tests
- [x] `providers_test.dart` - Provider state tests
- [x] `drawing_screen_test.dart` - Integration tests
- [x] **`lasso_panel_test.dart`** - Lasso panel tests
- [x] **`laser_panel_test.dart`** - Laser panel tests (updated)
- [x] **`toolbar_extended_test.dart`** - Right buttons & quick access tests
- [ ] **`shapes_expanded_test.dart`** - Optional (shapes tested in panels_test)

### Golden Tests - Phase 1 ⚠️ PARTIAL
- [x] `toolbar_golden_test.dart`
- [x] `pen_box_golden_test.dart`
- [x] `panels_golden_test.dart`
- [ ] **Golden: Kement panel**
- [ ] **Golden: Lazer panel updated**
- [ ] **Golden: Shapes panel expanded**
- [ ] **Golden: Toolbar with right buttons**

---

## Phase 2: Drawing Core v1 ❌ NOT STARTED

> ⚠️ DO NOT START until Phase 1 is 100% complete.

### Stroke System
- [ ] `Point` model with pressure/tilt
- [ ] `Stroke` model implementation
- [ ] `StrokeStyle` configuration
- [ ] Path generation from points
- [ ] Bezier smoothing algorithm
- [ ] Pressure-to-width mapping

### Tool Implementations
- [ ] `BallpointPenTool` - circular nib
- [ ] `FountainPenTool` - angled ellipse nib
- [ ] `PencilTool` - textured/noisy (simplified v1)
- [ ] `BrushTool` - variable pressure response
- [ ] `HighlighterTool` - rectangular, translucent
- [ ] Tool registry / factory

### Nib Geometry System
- [ ] `NibShape` sealed class hierarchy
- [ ] `CircleNib` implementation
- [ ] `EllipseNib` implementation (rotation-aware)
- [ ] `RectangleNib` implementation
- [ ] Nib-to-path stamping algorithm

### Drawing Document
- [ ] `Layer` model
- [ ] `DrawingDocument` with layers
- [ ] Active layer management
- [ ] Layer visibility toggle

### Canvas Integration
- [ ] Replace MockCanvas with real DrawingCanvas
- [ ] Gesture handling (pointer events)
- [ ] Stroke preview rendering
- [ ] Stroke completion flow

### Tests - Phase 2
- [ ] Unit: Stroke model
- [ ] Unit: Point interpolation
- [ ] Unit: Path smoothing
- [ ] Unit: Tool behavior
- [ ] Widget: Canvas gesture handling
- [ ] Integration: Drawing flow

---

## Phase 3: Advanced Features ❌ NOT STARTED

### History System
- [ ] Command pattern implementation
- [ ] `AddStrokeCommand`
- [ ] `RemoveStrokeCommand`
- [ ] `BatchCommand`
- [ ] HistoryManager integration
- [ ] Undo/Redo execution
- [ ] Snapshot strategy

### Eraser Implementation
- [ ] Pixel eraser hit testing
- [ ] Stroke eraser detection
- [ ] Lasso eraser selection

### Selection System
- [ ] Selection context model
- [ ] Bounding box selection
- [ ] Lasso selection
- [ ] Multi-stroke selection

### App Layer Integration (example_app only)
- [ ] AI assistant service interface
- [ ] Mock AI service implementation
- [ ] Feature gate implementation
- [ ] Premium tier definitions
- [ ] Database repository implementations

---

## Phase 4: Performance Hardening ❌ NOT STARTED

(See PERFORMANCE_STRATEGY.md for details)

---

## Phase 5: Publishing Readiness ❌ NOT STARTED

(See original checklist for details)

---

## Notes

### Phase 1 Completion Criteria

Phase 1 is COMPLETE when:
1. All items above are checked ✅
2. UI matches PHASE1_UI_REFERENCE.md exactly
3. All widget tests pass
4. All golden tests are generated and pass
5. `flutter run` shows working UI skeleton
6. NO real drawing logic implemented (intentional)

### Layer Responsibility Quick Reference

| Need to... | Where? |
|------------|--------|
| Add new drawing tool | `drawing_core` |
| Add new UI widget | `drawing_ui` |
| Check if feature is premium | `example_app` only |
| Call AI API | `example_app` only |
| Save to database | `example_app` only |
| Define serialization format | `drawing_core` |
| Define repository interface | `drawing_core` |
| Implement repository | `example_app` only |

---

*Last updated: 2026-01-13 - Phase 1 UI implementation complete (toolbar extended, all panels, providers)*

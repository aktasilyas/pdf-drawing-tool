# StarNote Drawing Library - Development Checklist

> **Single Source of Truth** for all development progress.  
> Update this file as features are implemented. Every PR should reference items here.
> 
> **Last Updated**: 2026-01-13 (Phase 2 Complete)

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
- [x] Add "Monetization & Premium Strategy" section to ARCHITECTURE.md
- [x] Add "AI Integration Strategy" section to ARCHITECTURE.md
- [x] Add "AI Performance Considerations" section to PERFORMANCE_STRATEGY.md

---

## Phase 1: UI Skeleton (Mocked State) ✅ COMPLETE

### Top Toolbar
- [x] Two-row toolbar (Navigation + Tools)
- [x] TopNavigationBar with document tabs
- [x] ToolBar with tool buttons
- [x] Undo/Redo buttons (disabled state)
- [x] Tool selection state management
- [x] Quick access colors and thickness
- [x] Right action buttons (Book, Home, Layers, Export, Grid, Settings, More)

### Floating Pen Box
- [x] Draggable pen box
- [x] Collapsible/expandable
- [x] Pen preset slots with preview
- [x] Add/remove presets
- [x] Edit mode for deletion

### Tool Panels
- [x] Pen settings panel (4 pen types, live preview)
- [x] Highlighter settings panel
- [x] Eraser settings panel (3 modes)
- [x] Shapes settings panel
- [x] Sticker panel with categories
- [x] Image panel
- [x] Laser pointer panel (mode + duration)
- [x] Lasso selection panel (8 toggles)
- [x] Toolbar editor panel

### Shared Components
- [x] UnifiedColorPicker with palette
- [x] Quick color chips
- [x] Quick thickness dots
- [x] Panel base component
- [x] Tool button with chevron indicator

### State Management
- [x] Riverpod providers structure
- [x] All tool settings providers
- [x] Lasso settings provider
- [x] Laser settings provider
- [x] Grid visibility provider

### Canvas
- [x] MockCanvas placeholder
- [x] Grid pattern background
- [x] Tool indicator

---

## Phase 2: Drawing Core v1 ✅ COMPLETE

### Models
- [x] `DrawingPoint` - x, y, pressure, tilt, timestamp
- [x] `StrokeStyle` - color (ARGB int), thickness, opacity, nibShape, blendMode
- [x] `NibShape` enum - circle, ellipse, rectangle
- [x] `DrawingBlendMode` enum - normal, multiply, screen, overlay, darken, lighten
- [x] `BoundingBox` - bounds calculation
- [x] `Stroke` - id, points, style, bounds, createdAt
- [x] `Layer` - id, name, strokes, visibility, locked, opacity
- [x] `DrawingDocument` - id, title, layers, activeLayerIndex, dimensions

### Tools
- [x] `DrawingTool` abstract class
- [x] `PenTool` - default pen style
- [x] `HighlighterTool` - semi-transparent, rectangle nib
- [x] `BrushTool` - ellipse nib, pressure-ready

### History (Command Pattern)
- [x] `DrawingCommand` abstract class
- [x] `AddStrokeCommand` - execute/undo stroke addition
- [x] `RemoveStrokeCommand` - execute/undo stroke removal
- [x] `HistoryManager` - undo/redo stacks, max 100 steps

### Input Processing
- [x] `PathSmoother` - smooth, simplify, interpolate methods

### Public API
- [x] `drawing_core.dart` exports all public classes

### Tests
- [x] DrawingPoint tests
- [x] StrokeStyle tests
- [x] Stroke tests
- [x] Layer tests
- [x] DrawingDocument tests
- [x] PenTool tests
- [x] HighlighterTool tests
- [x] BrushTool tests
- [x] Commands tests
- [x] HistoryManager tests
- [x] PathSmoother tests

### Quality
- [x] Zero Flutter imports in drawing_core
- [x] All models immutable with copyWith
- [x] JSON serialization for all models
- [x] Full test coverage

---

## Phase 3: Canvas Integration ❌ NOT STARTED

### Rendering
- [ ] `StrokeRenderer` abstract class
- [ ] `FlutterStrokeRenderer` implementation in drawing_ui
- [ ] Stroke to Path conversion
- [ ] Nib shape rendering (circle, ellipse, rectangle)

### Canvas Widget
- [ ] Replace `MockCanvas` with `DrawingCanvas`
- [ ] Gesture handling (pointer down/move/up)
- [ ] Pressure and tilt support
- [ ] Live stroke preview (aktif çizim)
- [ ] Committed strokes rendering

### Tool Integration
- [ ] Connect UI tools to drawing_core tools
- [ ] Tool selection → active tool instance
- [ ] Style sync between UI and core

### History Integration
- [ ] Connect Undo button to HistoryManager.undo()
- [ ] Connect Redo button to HistoryManager.redo()
- [ ] Update canUndo/canRedo providers

### Layer Integration
- [ ] Layer panel connection
- [ ] Active layer selection
- [ ] Layer visibility toggle

### Performance
- [ ] Separate live stroke canvas from committed strokes
- [ ] RepaintBoundary optimization
- [ ] Dirty rectangle tracking (basic)

### Tests
- [ ] Canvas gesture tests
- [ ] Stroke rendering tests
- [ ] Tool integration tests
- [ ] History integration tests

---

## Phase 4: Advanced Features ❌ NOT STARTED

### Eraser Implementation
- [ ] Pixel eraser hit testing
- [ ] Stroke eraser (whole stroke removal)
- [ ] Lasso eraser (selection-based)

### Selection System
- [ ] `SelectionContext` model
- [ ] Lasso selection tool
- [ ] Rectangle selection tool
- [ ] Multi-stroke selection
- [ ] Selection bounds visualization

### Shape Tools
- [ ] Line tool
- [ ] Rectangle tool
- [ ] Ellipse tool
- [ ] Arrow tool
- [ ] Shape rendering

### Text Tool
- [ ] Text element model
- [ ] Text input handling
- [ ] Text rendering on canvas

---

## Phase 5: Performance Hardening ❌ NOT STARTED

### Rendering Optimization
- [ ] Stroke segmentation (500 points max)
- [ ] PictureRecorder → Image caching
- [ ] Incremental raster cache
- [ ] Off-screen stroke baking
- [ ] Idle-time layer merging

### Memory Optimization
- [ ] Stroke data compression
- [ ] History snapshot intervals
- [ ] Old history pruning
- [ ] Image asset pooling

### Input Optimization
- [ ] Pointer event coalescing
- [ ] Predictive stroke extension

---

## Phase 6: Publishing Readiness ❌ NOT STARTED

### Package Preparation
- [ ] Final API review
- [ ] Version numbering (semver)
- [ ] CHANGELOG.md for each package
- [ ] LICENSE files
- [ ] pubspec.yaml polish

### Documentation
- [ ] README.md for drawing_core
- [ ] README.md for drawing_ui
- [ ] README.md for drawing_toolkit
- [ ] API documentation (dartdoc)
- [ ] Usage examples

### Quality Assurance
- [ ] Full test coverage review (>80%)
- [ ] Manual testing checklist
- [ ] Accessibility audit

### Pub.dev Submission
- [ ] `dart pub publish --dry-run` passes
- [ ] Package scores optimization
- [ ] Submit packages

---

## Git Tags

| Tag | Description | Date |
|-----|-------------|------|
| v0.1.0-phase1 | Phase 1: UI Skeleton | 2025-01-13 |
| v0.2.0-phase2 | Phase 2: Drawing Core | 2025-01-13 |

---

## Notes

### Test Coverage Summary

| Package | Tests | Status |
|---------|-------|--------|
| drawing_core | 337 | ✅ Full coverage |
| drawing_ui | 69 pass, 47 skip | ⚠️ Needs update |

### Phase 2 Achievements
- Zero Flutter dependencies in drawing_core
- 100% immutable models
- Full JSON serialization
- Command pattern for undo/redo
- 100-step history support
- Path smoothing utilities

---

*Last updated: 2026-01-13 - Phase 2 Complete*
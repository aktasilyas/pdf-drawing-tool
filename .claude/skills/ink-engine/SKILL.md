---
name: ink-engine
description: Rules and target design for the stroke/ink pipeline in packages/drawing_core and packages/drawing_ui (input filtering, stroke geometry, rendering, caching). Use before changing pens, strokes, canvas painters, or gesture handlers.
---
# Ink engine

## Known problems in the current code (M1 targets)
- No input stabilization: raw points joined by midpoint quadratic béziers
  (`rendering/flutter_stroke_renderer.dart`) → jitter.
- Variable width built from per-point normals (`rendering/variable_width_renderer.dart`)
  → kinks when point density changes.
- Active stroke path rebuilt from scratch on every pointer event (O(n) per frame).
- `CommittedStrokesPainter` re-renders every stroke as vectors whenever a stroke
  is added → hitch on pen-up, worse on full pages.

## Target pipeline
```
PointerEvent (incl. coalesced) → One Euro filter → resample (fixed spacing)
  → pressure/velocity → width → outline polygon (perfect-freehand style)
  → active layer: incremental path, only new segment work per event
  → pen-up: rasterize stroke into the page's tile cache (ui.Image per tile)
```
- Pure math (filter, resampling, outline) lives in `drawing_core` with unit tests;
  no Flutter imports there.
- Painters only draw: cached tiles + the active outline. No allocation in `paint()`.
- Undo/erase invalidates only the tiles whose bounds intersect the stroke.
- Zoom: re-rasterize visible tiles at the new scale after the gesture settles;
  scale cached images during the gesture.

## References (study the technique, write our own code)
- perfect-freehand (MIT) — outline from pressure/velocity, streamline, taper.
- Jetpack Ink (androidx.ink, Apache-2.0) — low-latency stroke modeling.
- One Euro filter paper (Casiez et al., CHI 2012).
Never copy code or assets from closed-source apps.

## Verification for any ink change
- Unit tests for filter/outline determinism (fixed input → fixed output).
- Golden test of a reference stroke set per pen preset.
- Benchmark: 1,000-stroke page, report worst and p95 frame time.

# Plan: incremental active-stroke rendering (#43)

Milestone M1 Ink engine v2. Depends on #42 (`StrokeOutline`, merged in 7fb7713).
Follow-ups that build on this: #44 (raster tile cache), #45 (pen presets v2).

## 1. Problem and acceptance criteria
On every pointer event, `ActiveStrokePainter` calls
`FlutterStrokeRenderer.renderActiveStroke`, which rebuilds the whole stroke (full `Path`, or
`StrokeOutline.build` over all n points). On top of that, `ListenableBuilder` rebuilds the
painter and `DrawingController.activePoints` copies the list (`List.unmodifiable`). The cost
of each event therefore grows with stroke length: O(n) per event and O(n^2) per stroke.

AC (from the issue, made checkable):
- A1 Benchmark: on a 2,000-point active stroke, the UI-thread p95 per-event time (controller
  update + `paint()` recorded into a `PictureRecorder`) for events 1800-2000 is <= 2x the p95
  for events 0-200. Before/after numbers go in the PR. The legacy path is measured in the same run.
- A2 Deterministic O(1) proof: `IncrementalStrokeOutline.lastRecomputed` is bounded by a constant
  that depends only on the options, never on n (unit test with n = 50 / 500 / 5000).
- A3 Parity: for every prefix of the test strokes, the incremental outline matches
  `StrokeOutline.build` within 1e-3 px. The live render of a finished stroke matches the
  committed render (raster diff test), so the stroke does not jump at pen-up.
- A4 `paint()` of the live painter allocates nothing (no `Path()`, `Paint()`, lists). The
  painter is never rebuilt per event, and `shouldRepaint` is never a constant `true`.
- A5 `./scripts/check.sh analyze` and `test` are green, including the existing
  `stroke_painter_test`, `drawing_controller_filter_test`, `drawing_canvas_test` and
  `flutter_stroke_renderer_test`.

## 2. Affected files
drawing_core
- `lib/src/input/outline_math.dart` (new, not exported): the `_P`, radius/speed/taper/tangent/cap
  helpers moved out of `stroke_outline.dart` and shared. No behaviour change.
- `lib/src/input/stroke_outline.dart`: uses `outline_math.dart`. Public API unchanged.
- `lib/src/input/incremental_stroke_outline.dart` (new, about 220 lines): the streaming outline.
- `lib/src/input/input.dart`: export the new class.
- `test/input/incremental_stroke_outline_test.dart` (new).

drawing_ui
- `lib/src/rendering/variable_width_renderer.dart`: add `static StrokeOutlineOptions
  optionsFor(StrokeStyle)`, which the committed and live renders both use so they cannot drift.
- `lib/src/rendering/active_stroke_geometry.dart` (new): owns the `Path`s, the `Paint`s and the
  bounds of the live stroke, and appends to them incrementally.
- `lib/src/rendering/rendering.dart`: export it.
- `lib/src/canvas/drawing_controller.dart` (new): `DrawingController` moved here from
  `stroke_painter.dart` (389 lines, over the limit) and wired to `ActiveStrokeGeometry`.
  `stroke_painter.dart` re-exports it so existing imports keep working.
- `lib/src/canvas/live_stroke_painter.dart` (new): `LiveStrokePainter(geometry, repaint: controller)`.
- `lib/src/canvas/active_stroke_layer.dart` (new widget): the active-layer block pulled out of
  `drawing_canvas.dart` (lines ~1077-1103). This is a small step toward splitting that file.
- `lib/src/canvas/drawing_canvas.dart`: use `ActiveStrokeLayer`. The straight-line preview keeps
  the points-based `ActiveStrokePainter`, which stays unchanged.
- `test/rendering/active_stroke_geometry_test.dart`, `test/canvas/live_stroke_painter_test.dart` (new).
- `test/benchmark/ink_benchmark_test.dart`, `scripts/ink_benchmark.sh`: length-independence section.

## 3. Design
### 3.1 `IncrementalStrokeOutline` (drawing_core, pure Dart)
```dart
class IncrementalStrokeOutline {
  IncrementalStrokeOutline(StrokeOutlineOptions options);
  void reset([StrokeOutlineOptions? options]);
  void addAll(Iterable<DrawingPoint> points);   // O(new + W) per call
  int get frozenCount;                           // samples whose edges are final
  int get lastRecomputed;                        // samples touched by last addAll (test hook)
  /// Appends a closed polygon for frozen samples [from, to] (x,y interleaved); `from == 0` includes start cap.
  void writeFrozen(int from, int to, List<double> out);
  /// Closed polygon: samples [max(0, frozenCount-2) .. end] + end cap (or the dot when one sample).
  void writeTail(List<double> out);
  List<Point2D> toPolygon();                     // full polygon; tests and parity only
}
```
How it works, mirroring the stages of `StrokeOutline.build`:
- Streamline, arc length, raw radius (pressure, speed, taperStart) and the forward EMA are causal,
  so each new sample is appended once and never touched again. The "true end point" that `build`
  appends is ephemeral and exists only in the tail.
- Tail window [frozenCount, n): each call recomputes the taperEnd factor, the forward EMA from the
  frozen state, the backward EMA starting at n-1, the forward clamp (seeded by the last frozen
  radius), the backward clamp (which stops at the boundary) and the tangents.
- Freeze rule for sample i: `n-1-i >= Kema` AND `arc[n-1]-arc[i] >= max(taperEnd, 2*size)`,
  with `Kema = ceil(ln 1e-4 / ln(1-k))` and `k = 1-0.8*smoothing`. Kema is 10 at the default
  smoothing and 41 at smoothing 1. The backward clamp moves values at most size/1.8 of arc length,
  so 2*size covers it. Streamline dedup keeps a minimum spacing of minR, which bounds W at about
  27 + Kema samples. W is constant in n, which gives A2.
- Store the arrays for each stage (f, b, forward-clamped, final r) in growable `Float64List`
  buffers that double in size. The prefix-parity test (A3) decides whether the result is correct.

### 3.2 `ActiveStrokeGeometry` (drawing_ui)
It owns `Path body` (append-only), `Path tail` (cleared with `reset()` each update), `Paint fill`,
`Paint layer`, `Rect bounds`, a scratch `List<double>` and `int version`. Mode is chosen at `begin(style)`:
- outline (`pressureSensitive`): new frozen samples go into `body` as closed chunk polygons
  (`writeFrozen`, 8+ samples per chunk, consecutive chunks share one sample). The tail polygon is
  rebuilt into `tail` and starts 2 samples before the boundary, so the edge where `body` and `tail`
  meet lies inside the tail's fill. That avoids an anti-aliasing seam.
- stroked (solid pens, highlighter, glow): each new point appends one `quadraticBezierTo(p_i, mid)`
  to `body`, as in `_createPath`. `tail` holds only `moveTo(lastMid)`/`lineTo(last)`.
  The cases n=1 (dot) and n=2 (line) go into `tail`.
- fallback (dashed pattern, pencil texture, straight-line mode, legacy stabilization without the
  filter): `rebuild(points)` calls the existing renderer helpers. This stays O(n) and is documented.
- Overlap and alpha: chunks inside `body` are unioned by nonZero fill (they all have the same
  orientation). `body` and `tail` overlap, so for translucent styles (opacity < 1 or a blend mode
  other than normal) the painter draws both with an opaque `fill` inside
  `saveLayer(bounds, layer)`, and `layer` carries the alpha and blend mode. This keeps a single
  stroke from darkening where it overlaps itself, the same as a committed stroke.

### 3.3 Data flow and state ownership
`gesture handler → DrawingController.addPoint → (filter) → geometry.append(newPts) → notifyListeners`.
`DrawingController` owns the geometry and is still the only source of truth for active points.
`LiveStrokePainter(super(repaint: controller))` is built once in `ActiveStrokeLayer`. Its `paint`
only draws `body` and `tail` (plus a saveLayer when translucent). `shouldRepaint` compares the
geometry identity. `activePoints` (the copy) stays for tests and is off the hot path. `endStroke()`
still returns `Stroke.create(points)`, so the committed render is unchanged.
Layer rules are respected: the math is in core and Flutter objects are in ui. No rule is bent
except that `drawing_canvas.dart` gets only a small extraction instead of a full split (see risks).

## 4. Test plan
- core `incremental_stroke_outline_test`: prefix parity against `StrokeOutline.build` (sine,
  spiral with sharp turns, pressure ramp, taperStart/End > 0, smoothing 0/0.5/1, streamline
  0/1); bound on `lastRecomputed` (A2); single point and duplicate points; reset; `writeFrozen`
  plus `writeTail` cover the polygon from `build` (area check within 0.5%).
- ui `active_stroke_geometry_test`: mode selection per style; `version` bumps; body grows
  without a rebuild (path bounds grow, scratch list capacity is stable); fallback modes are
  selected for dashed and pencil.
- ui `live_stroke_painter_test`: raster parity between the live and committed renders for pen,
  highlighter (0.4 alpha) and brush (pressure). Fewer than 0.5% of pixels may differ by more than 8/255.
  Repaint goes through the listenable, and `shouldRepaint` is false for the same geometry.
- The existing canvas, renderer and golden tests (`variable_width_pressures.png`) stay as they are.
- Benchmark (A1): new group in `ink_benchmark_test.dart` with a scripted 2,000-point stroke fed
  through `DrawingController` (filter on), timing addPoint + paint per event. It reports first-200
  and last-200 p95 for `legacy` (renderActiveStroke) and `incremental`, and asserts the
  incremental ratio is <= 2. `ink_benchmark.sh` greps the new lines.

## 5. Task breakdown (one implementer run each)
1. Core refactor: extract `outline_math.dart`. Verify with `cd packages/drawing_core && dart test test/input`.
2. Core `IncrementalStrokeOutline`, TDD with the parity and bound tests first. Verify with
   `dart test test/input/incremental_stroke_outline_test.dart && dart analyze`.
3. UI `optionsFor` + `ActiveStrokeGeometry` (outline, stroked, fallback) + its tests. Verify with
   `cd packages/drawing_ui && flutter test test/rendering`.
4. UI: move `DrawingController` to its own file, wire the geometry, add `LiveStrokePainter`
   and `ActiveStrokeLayer`, and switch `drawing_canvas.dart` to the layer. Verify with `flutter test test/canvas test/rendering`.
5. Benchmark section + script, then record the before/after numbers. Verify with
   `./scripts/ink_benchmark.sh && ./scripts/check.sh analyze && ./scripts/check.sh test`.

## 6. Risks and what is left out
- Feasibility: the full issue does not fit one implementer run. It fits one PR of the 5 steps
  above. If time is short, steps 1-2 alone are a mergeable slice (core only, no UI change).
  Steps 3-5 then follow in the same branch.
- The raster thread still tessellates `body`, which is O(n) on the GPU/raster side. The issue and
  the benchmark target UI-thread work. Rasterizing the frozen prefix is part of #44 (tile cache)
  and is deliberately not done here. This is stated in the PR so A1 is not over-claimed.
- Backward-EMA truncation can produce tiny differences. The 1e-3 px parity test and the raster
  parity test guard against them.
- Inner-edge folds on very sharp turns can flip a chunk's orientation, which would leave holes
  under nonZero fill. This is covered by the spiral and sharp-turn parity tests. If it fails,
  use `PathFillType.nonZero` with per-chunk orientation correction (reverse the chunk winding
  when its signed area is negative).
- Translucent styles add one saveLayer per frame. The cost is bounded by the stroke bounds.
- Left out (YAGNI): incremental dashing and pencil grain (they stay on the O(n) fallback; #45
  redesigns pencil and should use the geometry), predicted points, and a full split of
  `drawing_canvas.dart` / `drawing_canvas_gesture_handlers.dart`.

## 7. Reference check
GoodNotes, StarNote and Flexcil document no internals. All three are reviewed and marketed on
low-latency ink, where the live stroke is identical to the committed one and does not jump at
pen-up. The pattern we follow is the open references from the ink-engine skill: Jetpack Ink's
in-progress stroke, which keeps a stable prefix and recomputes only the unstable tail on each
input, and perfect-freehand's stages. The only user-visible decision is parity between live and
committed ink (A3), which matches all three apps. There is no deviation.

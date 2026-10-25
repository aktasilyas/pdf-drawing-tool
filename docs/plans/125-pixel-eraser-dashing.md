# #125 Pixel eraser turns strokes into dashes

## Root cause
The pixel eraser hit-tested a disc at each pointer sample only
(`PixelEraserTool.findSegmentsAt`). Samples arrive every 8-30 screen px on a
fast swipe, while the erase radius is `size / 2 / zoom`, scaled down to 30 %
at light pressure (pressure sensitivity on). With the dense 1.5 px resampled
strokes from #41, every sample removed only a few segments and the ink between
samples stayed: a swipe along a line left dashes over its whole length.

Two smaller defects made it worse:
- Removal was per whole segment, so sparse (legacy/raw) strokes lost far more
  than the eraser radius, and a long segment the eraser crossed was dropped.
- The preview map was a shallow copy of the live hit lists; the tile cache
  diffs previews by value and saw the mutated shared lists as unchanged, so
  tiles did not refresh during the gesture.

## Fix
- `EraserSweep` (drawing_core): the gesture path as a chain of capsules, each
  joining a sample to the previous one (radius = max of both, so pressure
  changes never open a gap).
- `PixelEraserTool.findSegmentsAlong(strokes, capsule)`: segment-vs-capsule
  hit test with bounding-box pre-filter, used for the live preview.
- `SweepStrokeEraser.erase(stroke, capsules)`: cuts exactly the covered part
  (eraser radius + half ink width) out of a stroke. Near segments are
  sub-stepped and each boundary is bisected, so cut points are interpolated
  (x, y, pressure, tilt, timestamp) and kept ink never reaches into the swept
  area. Pieces keep the `<id>_split_<k>` ids `ErasePointsCommand` uses for
  z-order; undo restores the stored originals.
- Pixel eraser gestures build the sweep in canvas units (zoom-correct), copy
  preview lists, and only replace strokes the sweep really touched.

Sticky-note internal erasing keeps the old segment splitter (out of scope).

## Reference check
GoodNotes (precision eraser), Flexcil (partial eraser) and StarNote (pixel
eraser) all remove ink continuously along the eraser path, whatever the drag
speed, and only where the eraser covers it. We now do the same. None of them
shrinks the eraser below the cursor with pressure; our pressure scaling stays
as is (setting exists), but the cursor still shows the full size. Follow-up
candidate: draw the cursor at the pressure-scaled size.

## Tests
- `drawing_core/test/tools/sweep_stroke_eraser_test.dart`: fast sparse sweep
  gives one gap (regression), kept ink stays outside the sweep, long segment
  is cut not dropped, interpolation, untouched/fully erased/dot strokes,
  undo through `ErasePointsCommand`, `findSegmentsAlong`.
- `drawing_ui/test/canvas/pixel_eraser_gestures_test.dart`: fast swipe through
  the canvas handlers at zoom 1.0 / 1.7 / 4.0 cuts one gap at the expected
  canvas positions; undo restores the stroke; a miss changes nothing.

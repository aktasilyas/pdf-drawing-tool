# Plan: export all shape types and sticky notes faithfully (#161)

## Problem
- Star, pentagon, hexagon and plus export as rectangles in the vector path
  (`pdf_vector_shapes.dart`) and the raster path (`pdf_raster_layer_renderer.dart`).
- `layer.stickyNotes` are painted on screen (`StickyNotePainter`) but never exported.
- The raster path paints all strokes, then shapes, images, texts, ignoring
  `Layer.elementOrder`.

## Design
1. **One geometry source** — `drawing_core/lib/src/models/shape_geometry.dart`:
   `ShapeGeometry.polygonPaths(shape)` returns the vertex lists for triangle,
   diamond, star, pentagon, hexagon and plus (null for the native primitives
   line, arrow, rectangle, ellipse). Pure Dart, unit-tested in core.
2. **Screen** — `ShapePainter` draws those types from `ShapeGeometry`
   (same vertices and order as before, so the canvas output is unchanged).
3. **Vector PDF** — `PdfVectorShapeRenderer` builds `m`/`l`/`h` paths from the
   same geometry. Open paths (plus bars) are never filled. Round caps/joins in
   both fill and stroke modes, as on screen.
4. **Raster PDF** — `PdfRasterLayerRenderer` now paints with the canvas
   renderers: `ElementSceneRenderer` (z-order from `elementOrder`, shapes via
   `ShapePainter`, text via `layoutTextParagraph`) after preloading images into
   a per-layer `ImageCacheManager`, then `StickyNotePainter` on top. The
   rasterize/pixel-cap code moved here from `PDFExporter`.
5. **Sticky notes** — a vectorizable layer exports its elements as vectors and
   its sticky notes as a raster overlay above them (the canvas paints notes
   above the layer content); a raster layer includes them in its overlay.

## Tests
- `drawing_core/test/models/shape_geometry_test.dart`: vertices per type.
- `drawing_ui/test/services/pdf_vector_shapes_test.dart`: ops test per
  `ShapeType` (vertices, no `re` fallback, closePath, fill rules).
- `drawing_ui/test/services/pdf_raster_layer_renderer_test.dart`: per-type
  pixel test (bounding-box corner stays empty), elementOrder across strokes and
  shapes, sticky-note pixels.
- `drawing_ui/test/services/pdf_exporter_sticky_test.dart`: sticky note on a
  vector layer embeds an overlay image.

## Reference check
GoodNotes, Flexcil and StarNote export exactly what is on the page → same:
the exporter reuses the canvas geometry and painters.

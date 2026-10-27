# #294 PNG export renders the page, not a viewport screenshot

**Builds on #287 (PR #304):** reuses `PageBackgroundRaster` and
`infiniteCanvasExportBounds`; this branch merges that branch until it lands.

## Steps
1. Extract the off-screen page render from `ThumbnailGenerator` into
   `services/page_rasterizer.dart` (`PageRasterizer.render/renderPng`): background via
   `PageBackgroundRaster`, PDF page via pdfx at a caller-chosen scale, layers via
   `PdfRasterLayerRenderer`; optional `region` (page coordinates) for an infinite canvas.
   `ThumbnailGenerator.generate` delegates to it (same output for region = page rect).
2. `services/page_png_exporter.dart`: `layout` = page rect (paged) or the PDF
   export's infinite-canvas bounds; 2 px per point, longest side ≤ 4096 px.
3. `panels/png_export_action.dart`: `performPNGExport(progress, page, …)` renders with
   `PagePngExporter` instead of `RepaintBoundary.toImage`; `exportCurrentPageAsPNG(ref)`
   is used by the export panel and document options. `debugPrint` → `dart:developer` log
   (drawing_ui has no logger dependency). Filename helpers move to
   `panels/export_file_name.dart` to keep `export_panel.dart` < 300 lines.
4. Delete the unused `ImageExportDialog` (no PNG options in v1.0; scale is fixed).
5. Tests: layout math (2x, cap, infinite bounds), rendered size + ink pixel + white
   corners, infinite-canvas ink outside the page, error path keeps the progress UI.

## Reference check
GoodNotes, Flexcil and StarNote export a page as an image of the whole page at page
resolution, not a screenshot of the current view → same. For an infinite canvas we
export the same content bounds as its PDF export.

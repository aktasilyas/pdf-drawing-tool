# #287 Export template and cover backgrounds with the canvas painters

Approach (from the issue, architect): rasterize template/cover backgrounds with
the canvas painters at the export DPI, embed one full-page image, cache per
`(background, page size, dpi)` within an export. Legacy blank/grid/lined/dotted
stay vector; PDF backgrounds unchanged.

## Steps
1. `canvas/page_background_raster.dart`: one off-screen background renderer
   (base color → image cover asset → `PageBackgroundPatternPainter`), extracted
   from `ThumbnailGenerator` so thumbnails and export share it.
2. `services/pdf_background_rasterizer.dart`: renders that to opaque RGBA at
   `min(dpi, 300)` capped to 4096 px on the longest side; embeds it as an
   opaque Flate RGB image (`addCompressedRgbImage`, no soft mask); caches by
   `(background, w, h, dpi)`.
3. `PDFExporter`: templates/covers go through the rasterizer (fallback: base
   color); cache cleared per export. Move infinite-canvas bounds helpers to
   `pdf_export_bounds.dart` to keep the exporter under 300 lines.
4. `PdfContentPainter.paintBackground`: drop the template grid.
5. Tests: every `TemplatePattern` raster differs from blank and (non grid/dot)
   from the old grid; engineer-pad margin via `templateExtraData`; covers not
   flat; 20 Cornell pages → one image XObject; `includeBackground: false` → no
   image; legacy grid stays vector; DPI caps.

## Deviation
DPI capped at 300 for backgrounds: `print` (600 dpi) would need ~140 MB of
transient RGBA per A4 background with no visible gain for paper lines.

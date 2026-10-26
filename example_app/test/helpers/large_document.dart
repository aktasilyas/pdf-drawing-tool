import 'package:drawing_core/drawing_core.dart';

/// Synthetic notebook: [pages] pages, each with [strokesPerPage] pen strokes
/// of [pointsPerStroke] points. Deterministic content, no clock in the data.
DrawingDocument buildLargeDocument({
  int pages = 300,
  int strokesPerPage = 20,
  int pointsPerStroke = 40,
}) {
  final created = DateTime.utc(2026, 1, 1);
  final style = StrokeStyle.pen(color: 0xFF1F2A44, thickness: 2.5);
  return DrawingDocument.multiPage(
    id: 'doc_large',
    title: 'Büyük defter',
    createdAt: created,
    updatedAt: created,
    pages: [
      for (var p = 0; p < pages; p++)
        Page(
          id: 'page_$p',
          index: p,
          size: PageSize.a4Portrait,
          background: PageBackground.blank,
          createdAt: created,
          updatedAt: created,
          layers: [
            Layer.empty('Katman 1').copyWith(
              strokes: [
                for (var s = 0; s < strokesPerPage; s++)
                  Stroke(
                    id: 'stroke_${p}_$s',
                    style: style,
                    createdAt: created,
                    points: [
                      for (var i = 0; i < pointsPerStroke; i++)
                        DrawingPoint(
                          x: 10.0 + i * 1.5,
                          y: 20.0 + s * 12.25,
                          pressure: (i % 10) / 10,
                          timestamp: i * 8,
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
    ],
  );
}

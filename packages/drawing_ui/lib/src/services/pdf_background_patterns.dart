import 'package:pdf/pdf.dart';

/// Draws a square grid.
void drawPdfGrid(PdfGraphics g, double w, double h, PdfColor color,
    double spacing, double lineWidth) {
  g.setStrokeColor(color);
  g.setLineWidth(lineWidth);
  for (double x = spacing; x < w; x += spacing) {
    g.drawLine(x, 0, x, h);
  }
  for (double y = spacing; y < h; y += spacing) {
    g.drawLine(0, h - y, w, h - y);
  }
  g.strokePath();
}

/// Draws horizontal ruled lines.
void drawPdfLines(PdfGraphics g, double w, double h, PdfColor color,
    double spacing, double lineWidth) {
  g.setStrokeColor(color);
  g.setLineWidth(lineWidth);
  for (double y = spacing * 2; y < h; y += spacing) {
    g.drawLine(0, h - y, w, h - y);
  }
  g.strokePath();
}

/// Draws a dot grid.
void drawPdfDots(
    PdfGraphics g, double w, double h, double spacing, PdfColor color) {
  g.setFillColor(color);
  for (double x = spacing; x < w; x += spacing) {
    for (double y = spacing; y < h; y += spacing) {
      g.drawEllipse(x, h - y, 1.0, 1.0);
    }
  }
  g.fillPath();
}

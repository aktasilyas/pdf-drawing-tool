import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

/// PDF export mode.
enum PDFExportMode { vector, raster, hybrid }

/// PDF export quality level.
enum PDFExportQuality {
  low,
  medium,
  high,
  print;

  int get dpi {
    switch (this) {
      case PDFExportQuality.low:
        return 72;
      case PDFExportQuality.medium:
        return 150;
      case PDFExportQuality.high:
        return 300;
      case PDFExportQuality.print:
        return 600;
    }
  }
}

/// PDF page format.
class PDFPageFormat {
  final double width;
  final double height;

  const PDFPageFormat({required this.width, required this.height});

  static const a4 = PDFPageFormat(width: 595, height: 842);
  static const a5 = PDFPageFormat(width: 420, height: 595);
  static const letter = PDFPageFormat(width: 612, height: 792);
  static const legal = PDFPageFormat(width: 612, height: 1008);

  PdfPageFormat toPdfPageFormat() => PdfPageFormat(width, height);
}

/// Options for PDF export.
class PDFExportOptions {
  final bool includeBackground;
  final PDFExportMode exportMode;
  final PDFExportQuality quality;
  final PDFPageFormat? pageFormat;

  /// When true, calculates content bounding box and uses it as page size
  /// instead of the fixed page dimensions. Used for infinite/whiteboard canvas.
  final bool isInfiniteCanvas;

  const PDFExportOptions({
    this.includeBackground = true,
    this.exportMode = PDFExportMode.raster,
    this.quality = PDFExportQuality.medium,
    this.pageFormat,
    this.isInfiniteCanvas = false,
  });

  PDFExportOptions copyWith({
    bool? includeBackground,
    PDFExportMode? exportMode,
    PDFExportQuality? quality,
    PDFPageFormat? pageFormat,
    bool? isInfiniteCanvas,
  }) {
    return PDFExportOptions(
      includeBackground: includeBackground ?? this.includeBackground,
      exportMode: exportMode ?? this.exportMode,
      quality: quality ?? this.quality,
      pageFormat: pageFormat ?? this.pageFormat,
      isInfiniteCanvas: isInfiniteCanvas ?? this.isInfiniteCanvas,
    );
  }
}

/// Result of PDF export operation.
class PDFExportResult {
  final bool isSuccess;
  final List<int> pdfBytes;
  final String? errorMessage;

  const PDFExportResult({
    required this.isSuccess,
    required this.pdfBytes,
    this.errorMessage,
  });

  factory PDFExportResult.success(List<int> bytes) =>
      PDFExportResult(isSuccess: true, pdfBytes: bytes);

  factory PDFExportResult.error(String message) =>
      PDFExportResult(isSuccess: false, pdfBytes: const [], errorMessage: message);

  int get fileSizeBytes => pdfBytes.length;

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// PDF document metadata.
class PDFDocumentMetadata {
  final String? title;
  final String? author;
  final String? creator;

  const PDFDocumentMetadata({this.title, this.author, this.creator = 'StarNote'});
}

/// Raster-based PDF exporter.
///
/// Renders each page to a PNG image using Flutter's Canvas (same rendering
/// pipeline as the screen) and embeds the images in a PDF document.
/// This guarantees WYSIWYG output.
class PDFExporter {
  final _strokeRenderer = FlutterStrokeRenderer();

  /// Calculates render scale from DPI. PDF points are at 72 DPI base.
  static double _scaleFromDpi(int dpi) => dpi / 72.0;

  /// Exports all pages to a single PDF document.
  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    PDFDocumentMetadata? metadata,
    PDFExportOptions options = const PDFExportOptions(),
    void Function(int current, int total)? onProgress,
  }) async {
    if (pages.isEmpty) return PDFExportResult.error('Sayfa bulunamadı');

    final renderScale = _scaleFromDpi(options.quality.dpi);

    try {
      final pdf = pw.Document();

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];

        Uint8List? imageBytes;
        double pdfW, pdfH;

        if (options.isInfiniteCanvas) {
          if (page.size.width <= 0 || page.size.height <= 0) continue;

          // Start with page area (0,0,w,h) — typically A4
          final pageW = page.size.width;
          final pageH = page.size.height;

          // Find content bounds; if empty, render just the blank page
          final contentRect = _calculateContentBounds(page);

          // Union of page area and content area (+ padding)
          const padding = 24.0;
          final double left;
          final double top;
          final double right;
          final double bottom;
          if (contentRect != null) {
            left = min(0.0, contentRect.left - padding);
            top = min(0.0, contentRect.top - padding);
            right = max(pageW, contentRect.right + padding);
            bottom = max(pageH, contentRect.bottom + padding);
          } else {
            left = 0;
            top = 0;
            right = pageW;
            bottom = pageH;
          }

          pdfW = right - left;
          pdfH = bottom - top;

          // Offset to shift origin so (left,top) maps to (0,0) in the image
          final offsetX = -left;
          final offsetY = -top;

          imageBytes = await _renderInfinitePage(
            page, renderScale, pdfW, pdfH, offsetX, offsetY,
          );
        } else {
          if (page.size.width <= 0 || page.size.height <= 0) continue;
          pdfW = page.size.width;
          pdfH = page.size.height;
          imageBytes = await _renderPageToImage(page, renderScale);
        }

        if (imageBytes == null) continue;

        final pageFormat = PdfPageFormat(pdfW, pdfH);
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(image),
          ),
        ));

        onProgress?.call(i + 1, pages.length);
      }

      final bytes = await pdf.save();
      return PDFExportResult.success(bytes);
    } catch (e) {
      return PDFExportResult.error(e.toString());
    }
  }

  /// Renders a single page to PNG bytes using PictureRecorder.
  Future<Uint8List?> _renderPageToImage(Page page, double renderScale) async {
    final w = page.size.width;
    final h = page.size.height;
    final renderW = (w * renderScale).toInt();
    final renderH = (h * renderScale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(renderScale);

    // 1. Background color + pattern
    _renderBackground(canvas, page);

    // 2. PDF background image (if any)
    if (page.background.type == BackgroundType.pdf) {
      await _renderPdfBackground(canvas, page, renderScale);
    }

    // 3. All visible layers
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;

      final needsOpacity = layer.opacity < 1.0;
      if (needsOpacity) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = Color.fromARGB(
            (layer.opacity * 255).round(), 255, 255, 255,
          ),
        );
      }

      _strokeRenderer.renderStrokes(canvas, layer.strokes);
      _renderShapes(canvas, layer.shapes);
      await _renderImages(canvas, layer.images);
      _renderTexts(canvas, layer.texts);

      if (needsOpacity) canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(renderW, renderH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Calculates the bounding rect of all content across visible layers.
  Rect? _calculateContentBounds(Page page) {
    double? minX, minY, maxX, maxY;

    void expand(BoundingBox b) {
      minX = minX == null ? b.left : min(minX!, b.left);
      minY = minY == null ? b.top : min(minY!, b.top);
      maxX = maxX == null ? b.right : max(maxX!, b.right);
      maxY = maxY == null ? b.bottom : max(maxY!, b.bottom);
    }

    for (final layer in page.layers) {
      if (!layer.isVisible) continue;
      for (final stroke in layer.strokes) {
        final b = stroke.bounds;
        if (b != null) expand(b);
      }
      for (final shape in layer.shapes) {
        expand(shape.bounds);
      }
      for (final img in layer.images) {
        expand(img.bounds);
      }
      for (final text in layer.texts) {
        expand(text.bounds);
      }
      for (final note in layer.stickyNotes) {
        expand(note.bounds);
      }
    }

    if (minX == null) return null;
    return Rect.fromLTRB(minX!, minY!, maxX!, maxY!);
  }

  /// Renders an infinite canvas page with a content-derived size.
  Future<Uint8List?> _renderInfinitePage(
    Page page,
    double renderScale,
    double w,
    double h,
    double offsetX,
    double offsetY,
  ) async {
    final renderW = (w * renderScale).toInt();
    final renderH = (h * renderScale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(renderScale);

    // Background fills the entire export area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Color(page.background.color),
    );
    _renderBackgroundPattern(canvas, w, h, page.background);

    // Translate so content is positioned correctly
    canvas.translate(offsetX, offsetY);

    // Render all visible layers
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;

      final needsOpacity = layer.opacity < 1.0;
      if (needsOpacity) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromARGB(
            (layer.opacity * 255).round(), 255, 255, 255,
          ),
        );
      }

      _strokeRenderer.renderStrokes(canvas, layer.strokes);
      _renderShapes(canvas, layer.shapes);
      await _renderImages(canvas, layer.images);
      _renderTexts(canvas, layer.texts);

      if (needsOpacity) canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(renderW, renderH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _renderBackground(Canvas canvas, Page page) {
    final w = page.size.width;
    final h = page.size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Color(page.background.color),
    );
    _renderBackgroundPattern(canvas, w, h, page.background);
  }

  void _renderBackgroundPattern(
    Canvas canvas, double w, double h, PageBackground bg,
  ) {
    final lineColor = bg.lineColor ?? 0xFFE0E0E0;
    final linePaint = Paint()
      ..color = Color(lineColor)
      ..strokeWidth = bg.templateLineWidth ?? 0.5
      ..isAntiAlias = true;

    switch (bg.type) {
      case BackgroundType.blank:
      case BackgroundType.cover:
      case BackgroundType.pdf:
        break;
      case BackgroundType.grid:
        _drawGrid(canvas, w, h, linePaint, bg.gridSpacing ?? 25.0);
        break;
      case BackgroundType.lined:
        _drawLines(canvas, w, h, linePaint, bg.lineSpacing ?? 25.0);
        break;
      case BackgroundType.dotted:
        _drawDots(canvas, w, h, bg.gridSpacing ?? 20.0, Color(lineColor));
        break;
      case BackgroundType.template:
        if (bg.templatePattern != null) {
          final sp = (bg.templateSpacingMm ?? 8.0) * 3.78;
          _drawGrid(canvas, w, h, linePaint, sp);
        }
        break;
    }
  }

  void _drawGrid(Canvas c, double w, double h, Paint p, double s) {
    for (double x = s; x < w; x += s) {
      c.drawLine(Offset(x, 0), Offset(x, h), p);
    }
    for (double y = s; y < h; y += s) {
      c.drawLine(Offset(0, y), Offset(w, y), p);
    }
  }

  void _drawLines(Canvas c, double w, double h, Paint p, double s) {
    for (double y = s * 2; y < h; y += s) {
      c.drawLine(Offset(0, y), Offset(w, y), p);
    }
  }

  void _drawDots(Canvas c, double w, double h, double s, Color color) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    for (double x = s; x < w; x += s) {
      for (double y = s; y < h; y += s) {
        c.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  Future<void> _renderPdfBackground(
    Canvas canvas, Page page, double renderScale,
  ) async {
    if (page.background.pdfPageIndex == null) return;
    try {
      Uint8List? bytes;

      // Prefer re-rendering from file at export resolution for best quality
      if (page.background.pdfFilePath != null) {
        bytes = await _renderPdfPage(
          page.background.pdfFilePath!,
          page.background.pdfPageIndex!,
          renderScale,
        );
      }

      // Fall back to cached pdfData (may be lower resolution)
      bytes ??= page.background.pdfData;
      if (bytes == null) return;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(0, 0, page.size.width, page.size.height),
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (_) {}
  }

  Future<Uint8List?> _renderPdfPage(
    String path, int index, double renderScale,
  ) async {
    if (!await File(path).exists()) return null;
    pdfx.PdfDocument? doc;
    pdfx.PdfPage? pg;
    try {
      doc = await pdfx.PdfDocument.openFile(path);
      pg = await doc.getPage(index);
      final img = await pg.render(
        width: pg.width * renderScale,
        height: pg.height * renderScale,
        format: pdfx.PdfPageImageFormat.png,
      );
      return img?.bytes;
    } finally {
      try { await pg?.close(); } catch (_) {}
      try { await doc?.close(); } catch (_) {}
    }
  }

  void _renderShapes(Canvas canvas, List<Shape> shapes) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final shape in shapes) {
      if (shape.isFilled) {
        paint.color = Color(shape.fillColor ?? shape.style.color);
        paint.style = PaintingStyle.fill;
        _drawShapeByType(canvas, shape, paint);

        paint.color = Color(shape.style.color).withValues(
          alpha: shape.style.opacity,
        );
        paint.strokeWidth = shape.style.thickness;
        paint.style = PaintingStyle.stroke;
        _drawShapeByType(canvas, shape, paint);
      } else {
        paint.color = Color(shape.style.color).withValues(
          alpha: shape.style.opacity,
        );
        paint.strokeWidth = shape.style.thickness;
        paint.style = PaintingStyle.stroke;
        _drawShapeByType(canvas, shape, paint);
      }
    }
  }

  void _drawShapeByType(Canvas canvas, Shape shape, Paint paint) {
    final s = Offset(shape.startPoint.x, shape.startPoint.y);
    final e = Offset(shape.endPoint.x, shape.endPoint.y);
    final rect = Rect.fromPoints(s, e);

    switch (shape.type) {
      case ShapeType.line:
        canvas.drawLine(s, e, paint);
      case ShapeType.arrow:
        canvas.drawLine(s, e, paint);
        _drawArrowHead(canvas, s, e, paint);
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
      case ShapeType.ellipse:
        canvas.drawOval(rect, paint);
      case ShapeType.triangle:
        final l = min(s.dx, e.dx);
        final r = max(s.dx, e.dx);
        final t = min(s.dy, e.dy);
        final b = max(s.dy, e.dy);
        canvas.drawPath(
          Path()..moveTo((l + r) / 2, t)..lineTo(l, b)..lineTo(r, b)..close(),
          paint,
        );
      case ShapeType.diamond:
        final cx = (s.dx + e.dx) / 2;
        final cy = (s.dy + e.dy) / 2;
        final hw = (e.dx - s.dx).abs() / 2;
        final hh = (e.dy - s.dy).abs() / 2;
        canvas.drawPath(
          Path()..moveTo(cx, cy - hh)..lineTo(cx + hw, cy)
            ..lineTo(cx, cy + hh)..lineTo(cx - hw, cy)..close(),
          paint,
        );
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        canvas.drawRect(rect, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 10) return;

    final ux = dx / len;
    final uy = dy / len;
    final sz = paint.strokeWidth * 4;
    final bx = end.dx - ux * sz;
    final by = end.dy - uy * sz;
    final px = -uy * sz * 0.5;
    final py = ux * sz * 0.5;

    canvas.drawPath(
      Path()..moveTo(end.dx, end.dy)
        ..lineTo(bx + px, by + py)..lineTo(bx - px, by - py)..close(),
      Paint()..color = paint.color..style = PaintingStyle.fill..isAntiAlias = true,
    );
  }

  void _renderTexts(Canvas canvas, List<TextElement> texts) {
    for (final t in texts) {
      if (t.text.isEmpty) continue;
      final style = ui.TextStyle(
        color: Color(t.color),
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontWeight: t.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: t.isUnderline ? TextDecoration.underline : TextDecoration.none,
      );
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: t.alignment == TextAlignment.center
            ? TextAlign.center
            : t.alignment == TextAlignment.right
                ? TextAlign.right
                : TextAlign.left,
      ))..pushStyle(style)..addText(t.text);
      final paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: t.width ?? 1000.0));
      canvas.save();
      if (t.rotation != 0.0) {
        final cx = t.x + paragraph.maxIntrinsicWidth / 2;
        final cy = t.y + paragraph.height / 2;
        canvas.translate(cx, cy);
        canvas.rotate(t.rotation);
        canvas.translate(-cx, -cy);
      }
      canvas.drawParagraph(paragraph, Offset(t.x, t.y));
      canvas.restore();
    }
  }

  /// Renders image elements on the canvas by loading from their file paths.
  Future<void> _renderImages(
    Canvas canvas, List<ImageElement> images,
  ) async {
    for (final img in images) {
      try {
        final file = File(img.filePath);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        canvas.save();
        if (img.rotation != 0.0) {
          final cx = img.x + img.width / 2;
          final cy = img.y + img.height / 2;
          canvas.translate(cx, cy);
          canvas.rotate(img.rotation);
          canvas.translate(-cx, -cy);
        }

        final src = Rect.fromLTWH(
          0, 0, uiImage.width.toDouble(), uiImage.height.toDouble(),
        );
        final dst = Rect.fromLTWH(img.x, img.y, img.width, img.height);
        canvas.drawImageRect(
          uiImage, src, dst,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      } catch (_) {
        // Skip images that fail to load
      }
    }
  }
}

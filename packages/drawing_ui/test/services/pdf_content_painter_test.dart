import 'dart:convert';
import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/variable_width_renderer.dart';
import 'package:drawing_ui/src/services/pdf_content_painter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

const _w = 200.0;
const _h = 100.0;

List<DrawingPoint> _curve() => [
      for (var i = 0; i <= 30; i++)
        DrawingPoint(
          x: 20 + i * 5.0,
          y: 50 + 20 * math.sin(i / 5),
          pressure: 0.3 + 0.7 * math.sin(i / 30 * math.pi),
          timestamp: i * 8,
        ),
    ];

/// Paints [stroke] and returns the page content stream as text.
Future<String> _export(Stroke stroke) async {
  final doc = PdfDocument(compress: false);
  final page = PdfPage(doc, pageFormat: const PdfPageFormat(_w, _h));
  final g = page.getGraphics();
  final layer = Layer.empty('l').addStroke(stroke);
  await PdfContentPainter().paintLayerContent(g, doc, layer, _w, _h);
  final bytes = await doc.save();
  return latin1.decode(bytes);
}

Stroke _stroke(StrokeStyle style) =>
    Stroke.create(style: style, points: _curve());

void main() {
  group('PdfContentPainter pressure/outline strokes', () {
    test('tapered fountain stroke exports the shared outline as a fill',
        () async {
      final style = PenType.fountainPen.toStrokeStyle(color: 0xFF000000);
      final content = await _export(_stroke(style));

      final outline = StrokeOutline.build(
        _curve(),
        VariableWidthStrokeRenderer.optionsFor(style),
      );
      final m = RegExp(r'(-?[\d.]+) (-?[\d.]+) m\b').firstMatch(content);
      expect(m, isNotNull, reason: 'outline must start with a moveTo');
      expect(double.parse(m!.group(1)!), closeTo(outline.first.x, 0.01));
      expect(double.parse(m.group(2)!), closeTo(_h - outline.first.y, 0.01));
      // Filled polygon, not a stroked bezier path.
      expect(content, contains(RegExp(r'\bf\b')));
      expect(content, isNot(contains(RegExp(r' S\b'))));
      final lineTos = RegExp(r' l\b').allMatches(content).length;
      expect(lineTos, outline.length - 1);
    });

    test('ballpoint (round ends, outline) uses the same routing as screen',
        () async {
      final style = PenType.ballpointPen.toStrokeStyle(color: 0xFF000000);
      expect(VariableWidthStrokeRenderer.usesOutline(style), isTrue);
      final content = await _export(_stroke(style));
      expect(content, contains(RegExp(r'\bf\b')));
      expect(content, isNot(contains(RegExp(r' S\b'))));
    });

    test('legacy stroked style (no pressure, no dynamics) stays stroked',
        () async {
      final style = StrokeStyle.pen(thickness: 2).copyWith(
        pressureSensitive: false,
        dynamics: StrokeDynamics.none,
      );
      expect(VariableWidthStrokeRenderer.usesOutline(style), isFalse);
      final content = await _export(_stroke(style));
      expect(content, contains(RegExp(r' S\b')));
    });
  });

  group('PdfContentPainter blend mode', () {
    test('highlighter sets a multiply graphic state', () async {
      final style = PenType.highlighter.toStrokeStyle(color: 0xFFFFEB3B);
      expect(style.blendMode, DrawingBlendMode.multiply);
      final content = await _export(_stroke(style));
      expect(content, contains('/BM/Multiply'));
    });

    test('normal ballpoint does not set a blend mode', () async {
      final style = PenType.ballpointPen.toStrokeStyle(color: 0xFF000000);
      final content = await _export(_stroke(style));
      expect(content, isNot(contains('/BM')));
    });
  });

  group('PdfContentPainter dot strokes', () {
    Stroke dot(StrokeStyle style) => Stroke.create(
          style: style,
          points: [
            DrawingPoint(x: 100, y: 50, pressure: 0.8, timestamp: 0),
          ],
        );

    for (final pen in PenType.values) {
      test('single-point ${pen.name} stroke is filled', () async {
        final style = pen.toStrokeStyle(color: 0xFF000000);
        final content = await _export(dot(style));
        expect(content, contains(RegExp(r'\bf\b')),
            reason: 'a dot must produce a fill op');
      });
    }

    test('stroked (non-outline) dot is a filled circle of the stroke width',
        () async {
      final style = StrokeStyle.pen(thickness: 6).copyWith(
        pressureSensitive: false,
        dynamics: StrokeDynamics.none,
      );
      expect(VariableWidthStrokeRenderer.usesOutline(style), isFalse);
      final content = await _export(dot(style));
      expect(content, contains(RegExp(r'\bf\b')));
      expect(content, isNot(contains(RegExp(r' S\b'))));
      // Circle spans x in [97, 103] around the dot centre at x = 100.
      final xs = RegExp(r'(-?[\d.]+) (-?[\d.]+) (?:m|c|l)\b')
          .allMatches(content)
          .map((m) => double.parse(m.group(1)!));
      expect(xs.reduce(math.max), closeTo(103, 0.5));
      expect(xs.reduce(math.min), closeTo(97, 0.5));
    });

    test('highlighter dot keeps the multiply blend', () async {
      final style = PenType.highlighter.toStrokeStyle(color: 0xFFFFEB3B);
      final content = await _export(dot(style));
      expect(content, contains('/BM/Multiply'));
    });
  });
}

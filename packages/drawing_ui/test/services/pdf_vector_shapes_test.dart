import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_content_painter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

const _w = 200.0;
const _h = 100.0;

Shape _shape(ShapeType type, {bool filled = false}) => Shape(
      id: 'shape-${type.name}',
      type: type,
      startPoint: DrawingPoint(x: 20, y: 10),
      endPoint: DrawingPoint(x: 120, y: 70),
      style: StrokeStyle.pen(thickness: 2),
      isFilled: filled,
      fillColor: filled ? 0xFFFF0000 : null,
    );

/// Exports [shape] through the vector path; returns the content streams
/// only (the xref table would otherwise match operators such as `f`).
Future<String> _export(Shape shape) async {
  final doc = PdfDocument(compress: false);
  final page = PdfPage(doc, pageFormat: const PdfPageFormat(_w, _h));
  final g = page.getGraphics();
  final layer = Layer.empty('l').addShape(shape);
  await PdfContentPainter().paintLayerContent(g, doc, layer, _w, _h);
  final file = latin1.decode(await doc.save());
  return RegExp(r'stream\r?\n([\s\S]*?)endstream')
      .allMatches(file)
      .map((m) => m.group(1)!)
      .join('\n');
}

const _num = r'(-?\d+(?:\.\d+)?)';

List<(double, double)> _ops(String content, String op) => [
      for (final m in RegExp('$_num $_num $op\\b').allMatches(content))
        (double.parse(m.group(1)!), double.parse(m.group(2)!)),
    ];

int _count(String content, String op) =>
    RegExp('(^|\\s)$op(\\s|\$)').allMatches(content).length;

/// Expected PDF vertices (y flipped) of every geometry path, in order.
List<(double, double)> _expectedVertices(Shape shape) => [
      for (final p in ShapeGeometry.polygonPaths(shape)!)
        for (final v in p.points) (v.x, _h - v.y),
    ];

void _expectSameVertices(String content, Shape shape) {
  final moves = _ops(content, 'm');
  final lines = _ops(content, 'l');
  final paths = ShapeGeometry.polygonPaths(shape)!;
  expect(moves, hasLength(paths.length), reason: 'one moveTo per path');

  // Rebuild the emitted vertex list in drawing order: m, then its l's.
  final emitted = <(double, double)>[];
  var li = 0;
  for (var pi = 0; pi < paths.length; pi++) {
    emitted.add(moves[pi]);
    for (var i = 1; i < paths[pi].points.length; i++) {
      emitted.add(lines[li++]);
    }
  }
  final expected = _expectedVertices(shape);
  expect(emitted, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(emitted[i].$1, closeTo(expected[i].$1, 0.01), reason: 'x[$i]');
    expect(emitted[i].$2, closeTo(expected[i].$2, 0.01), reason: 'y[$i]');
  }
}

void main() {
  group('PdfVectorShapeRenderer geometry', () {
    for (final type in ShapeType.values) {
      if (ShapeGeometry.isNative(type)) continue;

      test('${type.name} exports the on-screen vertices, not a rectangle',
          () async {
        final shape = _shape(type);
        final content = await _export(shape);
        expect(_count(content, 're'), 0, reason: 'no rectangle fallback');
        _expectSameVertices(content, shape);
        final paths = ShapeGeometry.polygonPaths(shape)!;
        final closed = paths.where((p) => p.closed).length;
        expect(_count(content, 'h'), closed, reason: 'closePath per polygon');
        expect(_count(content, 'S'), 1, reason: 'one stroke paint');
      });
    }

    test('filled star fills then strokes the same outline', () async {
      final shape = _shape(ShapeType.star, filled: true);
      final content = await _export(shape);
      expect(_count(content, 'f'), 1);
      expect(_count(content, 'S'), 1);
      // Fill pass + stroke pass each emit the 10 star vertices.
      expect(_ops(content, 'm'), hasLength(2));
      expect(_ops(content, 'l'), hasLength(18));
    });

    test('filled plus has no fill (its bars are open paths)', () async {
      final content = await _export(_shape(ShapeType.plus, filled: true));
      expect(_count(content, 'f'), 0);
      expect(_count(content, 'S'), 1);
    });

    test('rectangle still exports as a PDF rectangle', () async {
      final content = await _export(_shape(ShapeType.rectangle));
      final m = RegExp('$_num $_num $_num $_num re').firstMatch(content);
      expect(m, isNotNull);
      expect(double.parse(m!.group(1)!), closeTo(20, 0.01));
      expect(double.parse(m.group(2)!), closeTo(_h - 70, 0.01));
      expect(double.parse(m.group(3)!), closeTo(100, 0.01));
      expect(double.parse(m.group(4)!), closeTo(60, 0.01));
    });

    test('ellipse exports as bezier curves', () async {
      final content = await _export(_shape(ShapeType.ellipse));
      expect(_count(content, 'c'), greaterThanOrEqualTo(4));
      expect(_count(content, 're'), 0);
    });

    test('line and arrow export as strokes', () async {
      for (final type in [ShapeType.line, ShapeType.arrow]) {
        final content = await _export(_shape(type));
        final m = _ops(content, 'm').first;
        expect(m.$1, closeTo(20, 0.01), reason: type.name);
        expect(m.$2, closeTo(_h - 10, 0.01), reason: type.name);
        expect(_count(content, 'S'), 1, reason: type.name);
      }
    });
  });
}

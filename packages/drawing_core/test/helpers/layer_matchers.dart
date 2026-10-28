import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

/// Tolerance for geometry that went through a transform and its inverse.
const double kGeometryEpsilon = 1e-9;

/// Expects [actual] to equal [expected] element by element, comparing
/// geometry (points, positions, sizes, rotations, font sizes) within
/// [kGeometryEpsilon] and everything else exactly, including list order.
void expectLayerClose(Layer actual, Layer expected) {
  expect(actual.elementOrder, expected.elementOrder, reason: 'elementOrder');

  expect(actual.strokes.map((s) => s.id), expected.strokes.map((s) => s.id),
      reason: 'stroke order');
  for (var i = 0; i < expected.strokes.length; i++) {
    final a = actual.strokes[i];
    final e = expected.strokes[i];
    expect(a.style.copyWith(thickness: e.style.thickness), e.style,
        reason: 'style of ${e.id}');
    expect(a.style.thickness, closeTo(e.style.thickness, kGeometryEpsilon),
        reason: 'thickness of ${e.id}');
    expect(a.points.length, e.points.length);
    for (var p = 0; p < e.points.length; p++) {
      _expectPointClose(a.points[p], e.points[p], '${e.id}[$p]');
      expect(a.points[p].pressure, e.points[p].pressure);
      expect(a.points[p].tilt, e.points[p].tilt);
      expect(a.points[p].timestamp, e.points[p].timestamp);
    }
  }

  expect(actual.shapes.map((s) => s.id), expected.shapes.map((s) => s.id),
      reason: 'shape order');
  for (var i = 0; i < expected.shapes.length; i++) {
    final a = actual.shapes[i];
    final e = expected.shapes[i];
    _expectPointClose(a.startPoint, e.startPoint, '${e.id}.start');
    _expectPointClose(a.endPoint, e.endPoint, '${e.id}.end');
    expect(a.style, e.style, reason: 'style of ${e.id}');
  }

  expect(actual.images.map((i) => i.id), expected.images.map((i) => i.id),
      reason: 'image order');
  for (var i = 0; i < expected.images.length; i++) {
    final a = actual.images[i];
    final e = expected.images[i];
    _expectClose(a.x, e.x, '${e.id}.x');
    _expectClose(a.y, e.y, '${e.id}.y');
    _expectClose(a.width, e.width, '${e.id}.width');
    _expectClose(a.height, e.height, '${e.id}.height');
    _expectClose(a.rotation, e.rotation, '${e.id}.rotation');
  }

  expect(actual.texts.map((t) => t.id), expected.texts.map((t) => t.id),
      reason: 'text order');
  for (var i = 0; i < expected.texts.length; i++) {
    final a = actual.texts[i];
    final e = expected.texts[i];
    _expectClose(a.x, e.x, '${e.id}.x');
    _expectClose(a.y, e.y, '${e.id}.y');
    _expectClose(a.fontSize, e.fontSize, '${e.id}.fontSize');
    _expectClose(a.rotation, e.rotation, '${e.id}.rotation');
    expect(a.width == null, e.width == null, reason: '${e.id}.width null');
    if (e.width != null) _expectClose(a.width!, e.width!, '${e.id}.width');
    expect(a.height == null, e.height == null, reason: '${e.id}.height null');
    if (e.height != null) _expectClose(a.height!, e.height!, '${e.id}.height');
    expect(a.color, e.color, reason: '${e.id}.color');
    expect(a.text, e.text);
  }
}

void _expectPointClose(DrawingPoint a, DrawingPoint e, String what) {
  _expectClose(a.x, e.x, '$what.x');
  _expectClose(a.y, e.y, '$what.y');
}

void _expectClose(double a, double e, String what) {
  expect(a, closeTo(e, kGeometryEpsilon), reason: what);
}

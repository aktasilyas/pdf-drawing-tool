import 'dart:math';

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

import '../helpers/document_helpers.dart';
import '../helpers/layer_matchers.dart';

Stroke _stroke(String id, List<DrawingPoint> points,
        {double thickness = 2, int color = 0xFF000000}) =>
    Stroke(
      id: id,
      points: points,
      style: StrokeStyle.pen(thickness: thickness, color: color),
      createdAt: DateTime(2026),
    );

/// a: normal stroke; thick: hits the 50 cap when doubled; thin: hits the
/// 0.1 floor when halved. t: boxed text; big: hits the 200 font cap when
/// doubled; small: hits the 4 font floor when halved.
Layer _layer() => Layer.empty('L')
    .addStroke(_stroke('a', [
      DrawingPoint(x: 10, y: 10, pressure: 0.4, tilt: 0.2, timestamp: 7),
      DrawingPoint(x: 30, y: 20, pressure: 0.8),
    ]))
    .addStroke(_stroke('thick', [DrawingPoint(x: 5, y: 40)], thickness: 40))
    .addStroke(_stroke('thin', [DrawingPoint(x: 8, y: 8)], thickness: 0.15))
    .addStroke(_stroke('other', [DrawingPoint(x: 90, y: 90)],
        color: 0xFF00FF00))
    .addShape(Shape(
      id: 'r',
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 0, y: 0),
      endPoint: DrawingPoint(x: 20, y: 10),
      style: StrokeStyle.pen(),
    ))
    .addImage(ImageElement(
        id: 'i', filePath: 'i.png', x: 50, y: 50, width: 20, height: 10))
    .addText(TextElement(
        id: 't',
        text: 'Hello',
        x: 10,
        y: 10,
        fontSize: 16,
        width: 100,
        height: 40,
        color: 0xFF0000FF))
    .addText(TextElement(id: 'big', text: 'Big', x: 0, y: 100, fontSize: 150))
    .addText(TextElement(id: 'small', text: 'tiny', x: 40, y: 0, fontSize: 6));

const _strokes = ['a', 'thick', 'thin'];
const _texts = ['t', 'big', 'small'];

ScaleSelectionCommand _scale(double sx, double sy) => ScaleSelectionCommand(
      layerIndex: 0,
      strokeIds: _strokes,
      shapeIds: ['r'],
      imageIds: ['i'],
      textIds: _texts,
      centerX: 0,
      centerY: 0,
      scaleX: sx,
      scaleY: sy,
    );

/// Executes, undoes and redoes [command]; checks undo restores the
/// original and redo reproduces the first execution.
void _expectRoundTrip(DrawingCommand command, DrawingDocument doc) {
  final executed = command.execute(doc);
  final undone = command.undo(executed);
  expectLayerClose(undone.layers[0], doc.layers[0]);

  final redone = command.execute(undone);
  expectLayerClose(redone.layers[0], executed.layers[0]);
  expectLayerClose(command.undo(redone).layers[0], doc.layers[0]);
}

void main() {
  late DrawingDocument doc;

  setUp(() => doc = multiPageDocWithLayers('Test', [_layer()]));

  group('ScaleSelectionCommand', () {
    test('execute scales positions, thickness and font size', () {
      final layer = _scale(2, 2).execute(doc).layers[0];

      final a = layer.strokes.firstWhere((s) => s.id == 'a');
      expect([a.points[0].x, a.points[0].y, a.points[1].x, a.points[1].y],
          [20, 20, 60, 40]);
      expect(a.points[0].pressure, 0.4);
      expect(a.points[0].tilt, 0.2);
      expect(a.points[0].timestamp, 7);
      expect(a.style.thickness, 4);

      final t = layer.getTextById('t')!;
      expect([t.x, t.y, t.fontSize, t.width, t.height], [20, 20, 32, 200, 80]);

      final i = layer.getImageById('i')!;
      expect([i.x, i.y, i.width, i.height], [100, 100, 40, 20]);
    });

    test('execute clamps thickness and font size at the caps', () {
      final layer = _scale(2, 2).execute(doc).layers[0];

      expect(layer.strokes.firstWhere((s) => s.id == 'thick').style.thickness,
          50);
      expect(layer.getTextById('big')!.fontSize, 200);
    });

    test('execute clamps thickness and font size at the floors', () {
      final layer = _scale(0.5, 0.5).execute(doc).layers[0];

      expect(layer.strokes.firstWhere((s) => s.id == 'thin').style.thickness,
          0.1);
      expect(layer.getTextById('small')!.fontSize, 4);
    });

    test('undo restores everything after clamping up', () {
      final command = _scale(2, 2);
      final undone = command.undo(command.execute(doc)).layers[0];

      expect(undone.strokes.firstWhere((s) => s.id == 'thick').style.thickness,
          40);
      expect(undone.getTextById('big')!.fontSize, 150);
      expectLayerClose(undone, doc.layers[0]);
    });

    test('undo restores everything after clamping down', () {
      final command = _scale(0.5, 0.5);
      final undone = command.undo(command.execute(doc)).layers[0];

      expect(undone.strokes.firstWhere((s) => s.id == 'thin').style.thickness,
          0.15);
      expect(undone.getTextById('small')!.fontSize, 6);
      expectLayerClose(undone, doc.layers[0]);
    });

    test('uniform scale round-trips through undo and redo', () {
      _expectRoundTrip(_scale(2, 2), doc);
      _expectRoundTrip(_scale(0.5, 0.5), doc);
    });

    test('non-uniform scale round-trips through undo and redo', () {
      _expectRoundTrip(_scale(3, 0.25), doc);
    });

    test('description counts every element type', () {
      expect(_scale(2, 2).description, 'Scale 8 element(s)');
    });
  });

  group('RotateSelectionCommand', () {
    RotateSelectionCommand rotate(double angle, {double cx = 25}) =>
        RotateSelectionCommand(
          layerIndex: 0,
          strokeIds: _strokes,
          shapeIds: ['r'],
          imageIds: ['i'],
          textIds: _texts,
          centerX: cx,
          centerY: cx,
          angle: angle,
        );

    test('execute rotates points and element rotation', () {
      final layer = rotate(pi / 2, cx: 0).execute(doc).layers[0];

      final a = layer.strokes.firstWhere((s) => s.id == 'a');
      expect(a.points[1].x, closeTo(-20, kGeometryEpsilon));
      expect(a.points[1].y, closeTo(30, kGeometryEpsilon));
      expect(a.points[0].timestamp, 7);

      final i = layer.getImageById('i')!;
      expect(i.rotation, closeTo(pi / 2, kGeometryEpsilon));
      // Image center (60, 55) rotates to (-55, 60).
      expect(i.x + i.width / 2, closeTo(-55, kGeometryEpsilon));
      expect(i.y + i.height / 2, closeTo(60, kGeometryEpsilon));

      expect(layer.getTextById('t')!.rotation, closeTo(pi / 2, 1e-12));
    });

    test('execute -> undo -> redo round-trips to equal documents', () {
      _expectRoundTrip(rotate(pi / 3), doc);
      _expectRoundTrip(rotate(-2.5), doc);
    });

    test('round-trips text that is already rotated', () {
      final layer = doc.layers[0];
      final rotatedDoc = doc.updateLayer(
          0, layer.updateText(layer.getTextById('t')!.copyWith(rotation: 0.7)));

      _expectRoundTrip(rotate(1.1), rotatedDoc);
    });
  });

  group('ChangeSelectionStyleCommand', () {
    ChangeSelectionStyleCommand recolor() => ChangeSelectionStyleCommand(
          layerIndex: 0,
          strokeIds: ['a', 'other'],
          textIds: ['t'],
          newColor: 0xFFFF0000,
        );

    test('execute recolors only the selected strokes and texts', () {
      final layer = recolor().execute(doc).layers[0];

      Stroke s(String id) => layer.strokes.firstWhere((x) => x.id == id);
      expect(s('a').style.color, 0xFFFF0000);
      expect(s('other').style.color, 0xFFFF0000);
      expect(s('thick').style.color, 0xFF000000);
      expect(layer.getTextById('t')!.color, 0xFFFF0000);
      expect(layer.getTextById('big')!.color,
          doc.layers[0].getTextById('big')!.color);
    });

    test('undo restores each original color exactly', () {
      final command = recolor();
      final undone = command.undo(command.execute(doc));

      expect(undone.layers[0], doc.layers[0]);
    });

    test('execute -> undo -> redo round-trips to equal documents', () {
      final command = recolor();
      final executed = command.execute(doc);
      final redone = command.execute(command.undo(executed));

      expect(redone.layers[0], executed.layers[0]);
      expect(command.undo(redone).layers[0], doc.layers[0]);
    });

    test('works through HistoryManager undo/redo', () {
      final history = HistoryManager();
      final executed = history.execute(recolor(), doc);
      final undone = history.undo(executed)!;
      final redone = history.redo(undone)!;

      expect(undone.layers[0], doc.layers[0]);
      expect(redone.layers[0], executed.layers[0]);
    });
  });
}

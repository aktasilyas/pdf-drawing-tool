import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _s(String id, double x, double y) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: y),
        DrawingPoint(x: x + 20, y: y + 20),
      ],
      style: StrokeStyle(color: 0xFF000000, thickness: 2),
      createdAt: DateTime(2024),
    );

ElementScene _scene(
  List<Stroke> strokes, {
  List<String>? order,
  Set<String> excluded = const {},
  List<Shape> shapes = const [],
  Map<String, List<int>> pixel = const {},
}) =>
    ElementScene(
      strokes: strokes,
      shapes: shapes,
      elementOrder: order ?? [for (final s in strokes) s.id],
      excludedIds: excluded,
      pixelEraserPreview: pixel,
    );

void main() {
  final a = _s('a', 0, 0);
  final b = _s('b', 100, 100);
  final c = _s('c', 300, 300);

  test('null prev is full', () {
    expect(diffScenes(null, _scene([a])).full, isTrue);
  });

  test('identical content yields empty diff', () {
    final d = diffScenes(_scene([a, b]), _scene([a, b]));
    expect(d.isEmpty, isTrue);
  });

  test('append on top uses fast path', () {
    final d = diffScenes(_scene([a, b]), _scene([a, b, c]));
    expect(d.appendedOnTop, ['c']);
    expect(d.dirty, isEmpty);
    expect(d.full, isFalse);
  });

  test('undo of last stroke dirties its bounds', () {
    final d = diffScenes(_scene([a, b, c]), _scene([a, b]));
    expect(d.appendedOnTop, isEmpty);
    expect(d.dirty, [strokeBounds(c)]);
    expect(d.full, isFalse);
  });

  test('erase in the middle dirties only the removed stroke', () {
    final d = diffScenes(_scene([a, b, c]), _scene([a, c]));
    expect(d.dirty, [strokeBounds(b)]);
    expect(d.full, isFalse);
  });

  test('pixel-erase split: new ids not a suffix', () {
    final b1 = _s('b1', 100, 100);
    final b2 = _s('b2', 110, 110);
    final prev = _scene([a, b, c]);
    final next = _scene([a, b1, b2, c], order: ['a', 'b1', 'b2', 'c']);
    final d = diffScenes(prev, next);
    expect(d.appendedOnTop, isEmpty);
    expect(d.full, isFalse);
    expect(
      d.dirty,
      containsAll([strokeBounds(b), strokeBounds(b1), strokeBounds(b2)]),
    );
    expect(d.dirty, isNot(contains(strokeBounds(c))));
  });

  test('move dirties old and new bounds', () {
    final moved = _s('b', 150, 150);
    final d = diffScenes(_scene([a, b, c]), _scene([a, moved, c]));
    expect(d.dirty, [strokeBounds(b), strokeBounds(moved)]);
    expect(d.full, isFalse);
  });

  test('excluded set on and off', () {
    final base = _scene([a, b]);
    final hidden = _scene([a, b], excluded: {'b'});
    final on = diffScenes(base, hidden);
    expect(on.dirty, [strokeBounds(b)]);
    final off = diffScenes(hidden, base);
    expect(off.appendedOnTop, ['b']);
  });

  test('reorder of survivors is full', () {
    final d = diffScenes(
      _scene([a, b, c], order: ['a', 'b', 'c']),
      _scene([a, b, c], order: ['b', 'c', 'a']),
    );
    expect(d.full, isTrue);
  });

  test('pixel eraser preview change dirties that stroke', () {
    final d = diffScenes(
      _scene([a, b]),
      _scene([
        a,
        b
      ], pixel: {
        'b': [0]
      }),
    );
    expect(d.dirty, [strokeBounds(b), strokeBounds(b)]);
  });

  test('stroke eraser preview hides stroke', () {
    final next = ElementScene(
      strokes: [a, b],
      elementOrder: ['a', 'b'],
      strokeEraserPreview: {'a'},
    );
    final d = diffScenes(_scene([a, b]), next);
    expect(d.dirty, [strokeBounds(a)]);
  });

  test('entries follow elementOrder across element types', () {
    final shape = Shape(
      id: 'sh',
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 0, y: 0),
      endPoint: DrawingPoint(x: 10, y: 10),
      style: StrokeStyle(color: 0xFF000000, thickness: 2),
    );
    final scene = _scene([a, b], shapes: [shape], order: ['b', 'sh', 'a']);
    expect([for (final e in scene.entries) e.id], ['b', 'sh', 'a']);
  });

  test('unlisted elements are appended sorted by id', () {
    final scene = _scene([c, a, b], order: ['b']);
    expect([for (final e in scene.entries) e.id], ['b', 'a', 'c']);
  });

  test('append with unlisted ids works as dirty, not fast path', () {
    final d = diffScenes(
      _scene([a, c], order: []),
      _scene([a, b, c], order: []),
    );
    expect(d.appendedOnTop, isEmpty);
    expect(d.dirty, [strokeBounds(b)]);
  });

  test('bounds helper returns Rect', () {
    expect(_scene([a]).entries.single.bounds, isA<Rect>());
  });
}

import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _point(double x, double y) =>
    {'x': x, 'y': y, 'pressure': 1.0, 'tilt': 0.0, 'timestamp': 0};

Map<String, dynamic> _style() => StrokeStyle.pen().toJson();

Map<String, dynamic> _shape(String id, String type) => {
      'id': id,
      'type': type,
      'startPoint': _point(0, 0),
      'endPoint': _point(10, 10),
      'style': _style(),
    };

Map<String, dynamic> _stroke(String? id, {String createdAt = '2026-01-01'}) =>
    {
      if (id != null) 'id': id,
      'points': [_point(0, 0), _point(5, 5)],
      'style': _style(),
      'createdAt': createdAt,
    };

Map<String, dynamic> _layerJson({
  List<Object?> strokes = const [],
  List<Object?> shapes = const [],
  List<String> order = const [],
}) =>
    {
      'id': 'layer-1',
      'name': 'Layer',
      'strokes': strokes,
      'shapes': shapes,
      'elementOrder': order,
    };

/// Decodes [json] after a real JSON round trip, as storage does.
Layer _decode(Map<String, dynamic> json) =>
    Layer.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);

void main() {
  group('Layer.fromJson with unreadable elements (#514)', () {
    test('an unknown shape type is kept aside and the rest decodes', () {
      final layer = _decode(_layerJson(
        shapes: [
          _shape('s1', 'rectangle'),
          {'id': 'heart-1', 'type': 'heart'},
          _shape('s2', 'ellipse'),
        ],
        order: ['s1', 'heart-1', 's2'],
      ));

      expect(layer.shapes.map((s) => s.id), ['s1', 's2']);
      expect(layer.unreadableElements, hasLength(1));
      expect(layer.unreadableElements.single.listKey, 'shapes');
      expect(layer.unreadableElements.single.id, 'heart-1');
      expect(layer.elementOrder, ['s1', 'heart-1', 's2']);
    });

    test('toJson writes the unreadable element back unchanged', () {
      final heart = {'id': 'heart-1', 'type': 'heart', 'petals': 3};
      final json = _layerJson(
        shapes: [_shape('s1', 'rectangle'), heart],
        order: ['heart-1', 's1'],
      );

      final out = jsonDecode(jsonEncode(_decode(json).toJson()))
          as Map<String, dynamic>;

      expect(out['shapes'], hasLength(2));
      expect((out['shapes'] as List).last, heart);
      expect(out['elementOrder'], ['heart-1', 's1']);
      // Decoding again keeps it unreadable and keeps the valid shape.
      final again = Layer.fromJson(out);
      expect(again.shapes.single.id, 's1');
      expect(again.unreadableElements.single.raw, heart);
    });

    test('a stroke without id is kept aside, other strokes decode', () {
      final layer = _decode(_layerJson(strokes: [
        _stroke('a'),
        _stroke(null),
        _stroke('b'),
      ]));

      expect(layer.strokes.map((s) => s.id), ['a', 'b']);
      expect(layer.unreadableElements.single.listKey, 'strokes');
      expect(layer.unreadableElements.single.id, isNull);
    });

    test('a stroke with an invalid createdAt is kept aside', () {
      final layer = _decode(_layerJson(strokes: [
        _stroke('a'),
        _stroke('bad', createdAt: 'not a date'),
      ]));

      expect(layer.strokes.single.id, 'a');
      expect(layer.unreadableElements.single.id, 'bad');
      final out = layer.toJson();
      expect((out['strokes'] as List).map((s) => (s as Map)['id']),
          ['a', 'bad']);
    });

    test('non-map entries are kept aside too', () {
      final layer = _decode(_layerJson(strokes: [_stroke('a'), 42, null]));

      expect(layer.strokes.single.id, 'a');
      expect(layer.unreadableElements.map((e) => e.raw), [42, null]);
      expect(layer.toJson()['strokes'], hasLength(3));
    });

    test('edits keep the unreadable elements', () {
      final layer = _decode(_layerJson(
        shapes: [
          {'id': 'heart-1', 'type': 'heart'},
        ],
      ));
      final stroke = Stroke.fromJson(_stroke('new'));

      final edited = layer
          .addStroke(stroke)
          .updateStroke(stroke)
          .copyWith(name: 'Renamed')
          .removeStroke('new');

      expect(edited.unreadableElements, layer.unreadableElements);
    });

    test('a duplicated page does not copy unreadable elements', () {
      final layer = _decode(_layerJson(
        strokes: [_stroke('a')],
        shapes: [
          {'id': 'heart-1', 'type': 'heart'},
        ],
      ));
      final page = Page.create(index: 0).copyWith(layers: [layer]);

      final copy = page.copyWithFreshIds().layers.single;

      expect(copy.strokes, hasLength(1));
      expect(copy.unreadableElements, isEmpty);
      expect(page.layers.single.unreadableElements, hasLength(1));
    });

    test('a valid layer has no unreadable elements', () {
      final layer = _decode(_layerJson(
        strokes: [_stroke('a')],
        shapes: [_shape('s1', 'line')],
      ));

      expect(layer.unreadableElements, isEmpty);
      expect(layer.toJson()['shapes'], hasLength(1));
    });

    test('equality includes the unreadable elements', () {
      final a = _decode(_layerJson(shapes: [
        {'id': 'x', 'type': 'heart'},
      ]));
      final b = _decode(_layerJson(shapes: [
        {'id': 'x', 'type': 'heart'},
      ]));
      final c = _decode(_layerJson());

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  test('an unknown TextAlignment decodes as left', () {
    final text = TextElement.fromJson({
      'id': 't1',
      'text': 'hi',
      'alignment': 'justify',
    });

    expect(text.alignment, TextAlignment.left);
  });
}

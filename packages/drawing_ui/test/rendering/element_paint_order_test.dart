import 'package:drawing_ui/src/rendering/element_paint_order.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _order(
  List<String> elementOrder, {
  Map<String, Object> strokes = const {},
  Map<String, Object> shapes = const {},
  Map<String, Object> images = const {},
  Map<String, Object> texts = const {},
}) =>
    elementPaintOrder<String>(
      elementOrder: elementOrder,
      strokes: strokes,
      shapes: shapes,
      images: images,
      texts: texts,
      entry: (id, element) => '$element:$id',
    );

void main() {
  test('listed ids first, then missing elements of every kind by id', () {
    expect(
      _order(
        ['30'],
        strokes: {'30': 's', '10': 's', '20': 's'},
        shapes: {'25': 'sh'},
        images: {'15': 'i'},
        texts: {'05': 't'},
      ),
      ['s:30', 't:05', 's:10', 'i:15', 's:20', 'sh:25'],
    );
  });

  test('unknown and duplicate ids in elementOrder are skipped', () {
    expect(
      _order(['x', '2', '1', '2'], strokes: {'1': 's', '2': 's'}),
      ['s:2', 's:1'],
    );
  });

  test('empty elementOrder: strokes, shapes in list order, then objects', () {
    expect(
      _order(
        const [],
        strokes: {'9': 's', '1': 's'},
        shapes: {'8': 'sh'},
        images: {'7': 'i'},
        texts: {'3': 't'},
      ),
      ['s:9', 's:1', 'sh:8', 't:3', 'i:7'],
    );
  });
}

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  Stroke stroke(String id) => Stroke(
        id: id,
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 5, y: 5)],
        style: StrokeStyle.pen(),
        createdAt: DateTime(2024),
      );

  Shape shape(String id) => Shape(
        id: id,
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 10, y: 10),
        style: StrokeStyle.pen(),
      );

  Page source() => Page(
        id: 'p1',
        index: 3,
        size: PageSize.a4Portrait,
        background: PageBackground.blank,
        isBookmarked: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        layers: [
          Layer(
            id: 'l1',
            name: 'Katman 1',
            strokes: [stroke('s1'), stroke('s2')],
            shapes: [shape('sh1')],
            texts: const [TextElement(id: 't1', text: 'hi', x: 1, y: 2)],
            images: const [
              ImageElement(
                  id: 'i1', filePath: 'a.png', x: 0, y: 0, width: 5, height: 5),
            ],
            stickyNotes: [
              StickyNote(
                id: 'n1',
                x: 0,
                y: 0,
                width: 50,
                height: 50,
                strokes: [stroke('ns1')],
                shapes: [shape('nsh1')],
              ),
            ],
            elementOrder: const ['sh1', 's2', 'missing', 't1', 's1', 'i1'],
          ),
        ],
      );

  Set<String> allIds(Page p) => {
        p.id,
        for (final l in p.layers) ...[
          l.id,
          ...l.strokes.map((s) => s.id),
          ...l.shapes.map((s) => s.id),
          ...l.texts.map((t) => t.id),
          ...l.images.map((i) => i.id),
          for (final n in l.stickyNotes) ...[
            n.id,
            ...n.strokes.map((s) => s.id),
            ...n.shapes.map((s) => s.id),
          ],
        ],
      };

  group('Page.copyWithFreshIds', () {
    test('shares no id with the source page', () {
      final original = source();
      final copy = original.copyWithFreshIds();

      expect(allIds(copy).intersection(allIds(original)), isEmpty);
      // Every id in the copy is distinct.
      final layer = copy.layers.single;
      final count = 2 +
          layer.strokes.length +
          layer.shapes.length +
          layer.texts.length +
          layer.images.length +
          layer.stickyNotes.length +
          layer.stickyNotes.single.strokes.length +
          layer.stickyNotes.single.shapes.length;
      expect(allIds(copy), hasLength(count));
    });

    test('keeps content and remaps elementOrder, dropping unknown ids', () {
      final original = source();
      final copy = original.copyWithFreshIds();
      final from = original.layers.single;
      final to = copy.layers.single;

      expect(to.strokes.map((s) => s.points), from.strokes.map((s) => s.points));
      expect(to.texts.single.text, 'hi');
      expect(to.images.single.filePath, 'a.png');
      expect(to.stickyNotes.single.strokes, hasLength(1));
      expect(to.name, from.name);
      expect(to.elementOrder, [
        to.shapes[0].id,
        to.strokes[1].id,
        to.texts[0].id,
        to.strokes[0].id,
        to.images[0].id,
      ]);
    });

    test('keeps size and background, drops bookmark and cover flags', () {
      final copy = source().copyWithFreshIds();
      expect(copy.size, PageSize.a4Portrait);
      expect(copy.background, PageBackground.blank);
      expect(copy.isBookmarked, isFalse);
      expect(copy.isCover, isFalse);
      expect(copy.thumbnail, isNull);
    });

    test('two copies made back to back get different page ids', () {
      final original = source();
      expect(original.copyWithFreshIds().id,
          isNot(original.copyWithFreshIds().id));
    });
  });
}

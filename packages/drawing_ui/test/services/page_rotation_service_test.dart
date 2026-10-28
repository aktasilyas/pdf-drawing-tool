import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/page_rotation_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _eps = 1e-9;

// Page is 600 wide, 800 tall.
const _w = 600.0;
const _h = 800.0;

DrawingPoint _p(double x, double y) => DrawingPoint(x: x, y: y);

Page _page({
  List<Stroke> strokes = const [],
  List<Shape> shapes = const [],
  List<TextElement> texts = const [],
  List<ImageElement> images = const [],
  List<StickyNote> notes = const [],
  bool isBookmarked = false,
}) {
  final layer = Layer.empty('L').copyWith(
    strokes: strokes,
    shapes: shapes,
    texts: texts,
    images: images,
    stickyNotes: notes,
  );
  return Page(
    id: 'page-1',
    index: 3,
    size: const PageSize(width: _w, height: _h, preset: PagePreset.custom),
    background: const PageBackground(type: BackgroundType.grid),
    layers: [layer],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isCover: false,
    isBookmarked: isBookmarked,
  );
}

Stroke _stroke(List<DrawingPoint> points) =>
    Stroke.create(style: StrokeStyle.pen(), points: points);

Matcher _at(double x, double y) => isA<DrawingPoint>()
    .having((p) => p.x, 'x', closeTo(x, _eps))
    .having((p) => p.y, 'y', closeTo(y, _eps));

Page _rotateN(Page page, RotationAngle a, int n) {
  var result = page;
  for (var i = 0; i < n; i++) {
    result = PageRotationService.rotatePage(result, a);
  }
  return result;
}

void main() {
  group('page size', () {
    test('90° rotations swap width and height', () {
      for (final a in [RotationAngle.cw90, RotationAngle.ccw90]) {
        final r = PageRotationService.rotatePage(_page(), a);
        expect(r.size.width, _h, reason: '$a');
        expect(r.size.height, _w, reason: '$a');
      }
    });

    test('180° keeps the size', () {
      final r = PageRotationService.rotatePage(_page(), RotationAngle.half);
      expect(r.size.width, _w);
      expect(r.size.height, _h);
    });
  });

  group('page metadata', () {
    test('identity, background and flags are preserved', () {
      final page = _page(isBookmarked: true);
      final r = PageRotationService.rotatePage(page, RotationAngle.cw90);
      expect(r.id, page.id);
      expect(r.index, page.index);
      expect(r.background.type, BackgroundType.grid);
      expect(r.createdAt, page.createdAt);
      expect(r.isCover, isFalse);
      expect(r.isBookmarked, isTrue);
      expect(r.thumbnail, isNull);
    });
  });

  group('points and strokes', () {
    final cases = {
      RotationAngle.cw90: (750.0, 100.0), // (h - y, x)
      RotationAngle.ccw90: (50.0, 500.0), // (y, w - x)
      RotationAngle.half: (500.0, 750.0), // (w - x, h - y)
    };

    for (final entry in cases.entries) {
      test('${entry.key} moves stroke points', () {
        final page = _page(strokes: [
          _stroke([_p(100, 50), _p(0, 0)]),
        ]);
        final r = PageRotationService.rotatePage(page, entry.key);
        final points = r.layers.single.strokes.single.points;
        expect(points.first, _at(entry.value.$1, entry.value.$2));
        expect(points, hasLength(2));
      });
    }

    test('stroke style, id and point pressure are preserved', () {
      final stroke = Stroke.create(
        style: StrokeStyle.pen(color: 0xFF112233, thickness: 4),
        points: [DrawingPoint(x: 10, y: 20, pressure: 0.4, tilt: 0.3)],
      );
      final r = PageRotationService.rotatePage(
          _page(strokes: [stroke]), RotationAngle.cw90);
      final rotated = r.layers.single.strokes.single;
      expect(rotated.id, stroke.id);
      expect(rotated.style, stroke.style);
      expect(rotated.points.single.pressure, closeTo(0.4, _eps));
      expect(rotated.points.single.tilt, closeTo(0.3, _eps));
    });
  });

  group('shapes', () {
    test('start and end points are transformed', () {
      final shape = Shape.create(
        type: ShapeType.line,
        startPoint: _p(100, 50),
        endPoint: _p(300, 400),
        style: StrokeStyle.pen(),
      );
      final page = _page(shapes: [shape]);

      final cw = PageRotationService.rotatePage(page, RotationAngle.cw90)
          .layers
          .single
          .shapes
          .single;
      expect(cw.startPoint, _at(750, 100));
      expect(cw.endPoint, _at(400, 300));
      expect(cw.type, ShapeType.line);

      final ccw = PageRotationService.rotatePage(page, RotationAngle.ccw90)
          .layers
          .single
          .shapes
          .single;
      expect(ccw.startPoint, _at(50, 500));
      expect(ccw.endPoint, _at(400, 300));

      final half = PageRotationService.rotatePage(page, RotationAngle.half)
          .layers
          .single
          .shapes
          .single;
      expect(half.startPoint, _at(500, 750));
      expect(half.endPoint, _at(300, 400));
    });
  });

  group('boxed elements', () {
    test('text box center moves and 90° swaps its dimensions', () {
      final text = TextElement.create(
          text: 'hi', x: 100, y: 50, width: 200, height: 40);
      final r = PageRotationService.rotatePage(
          _page(texts: [text]), RotationAngle.cw90);
      final t = r.layers.single.texts.single;
      // Center (200, 70) -> (730, 200); box becomes 40 x 200.
      expect(t.x, closeTo(710, _eps));
      expect(t.y, closeTo(100, _eps));
      expect(t.width, closeTo(40, _eps));
      expect(t.height, closeTo(200, _eps));
      expect(t.rotation, text.rotation);
    });

    test('auto-sized text keeps null dimensions', () {
      final text = TextElement.create(text: 'hi', x: 100, y: 50);
      final r = PageRotationService.rotatePage(
          _page(texts: [text]), RotationAngle.half);
      final t = r.layers.single.texts.single;
      expect(t.x, closeTo(500, _eps));
      expect(t.y, closeTo(750, _eps));
      expect(t.width, isNull);
      expect(t.height, isNull);
    });

    test('image center moves but size and orientation are kept', () {
      final image = ImageElement.create(
          filePath: 'a.png', x: 100, y: 50, width: 200, height: 100);
      final r = PageRotationService.rotatePage(
          _page(images: [image]), RotationAngle.cw90);
      final img = r.layers.single.images.single;
      // Center (200, 100) -> (700, 200).
      expect(img.x, closeTo(600, _eps));
      expect(img.y, closeTo(150, _eps));
      expect(img.width, 200);
      expect(img.height, 100);
      expect(img.rotation, 0);
    });

    test('sticky note moves, swaps size and rotates its local ink', () {
      final note = StickyNote.create(x: 100, y: 50, width: 200, height: 100)
          .copyWith(strokes: [
        _stroke([_p(10, 20)]),
      ]);
      final r = PageRotationService.rotatePage(
          _page(notes: [note]), RotationAngle.cw90);
      final n = r.layers.single.stickyNotes.single;
      // Center (200, 100) -> (700, 200); note becomes 100 x 200.
      expect(n.x, closeTo(650, _eps));
      expect(n.y, closeTo(100, _eps));
      expect(n.width, closeTo(100, _eps));
      expect(n.height, closeTo(200, _eps));
      // Note-local (10, 20) in a 200 x 100 note -> (100 - 20, 10).
      expect(n.strokes.single.points.single, _at(80, 10));
    });
  });

  group('round trips', () {
    Page richPage() => _page(
          strokes: [
            _stroke([_p(100, 50), _p(321.5, 777.25), _p(0, 800)]),
          ],
          shapes: [
            Shape.create(
              type: ShapeType.rectangle,
              startPoint: _p(12, 34),
              endPoint: _p(560, 700),
              style: StrokeStyle.pen(),
            ),
          ],
          texts: [
            TextElement.create(
                text: 't', x: 40, y: 60, width: 120, height: 30),
          ],
          images: [
            ImageElement.create(
                filePath: 'i.png', x: 300, y: 500, width: 90, height: 60),
          ],
          notes: [
            StickyNote.create(x: 20, y: 600, width: 150, height: 80)
                .copyWith(shapes: [
              Shape.create(
                type: ShapeType.line,
                startPoint: _p(5, 5),
                endPoint: _p(140, 70),
                style: StrokeStyle.pen(),
              ),
            ]),
          ],
        );

    void expectSameGeometry(Page actual, Page expected) {
      expect(actual.size.width, closeTo(expected.size.width, _eps));
      expect(actual.size.height, closeTo(expected.size.height, _eps));
      final a = actual.layers.single;
      final e = expected.layers.single;

      final ap = a.strokes.single.points;
      final ep = e.strokes.single.points;
      for (var i = 0; i < ep.length; i++) {
        expect(ap[i], _at(ep[i].x, ep[i].y));
      }
      expect(a.shapes.single.startPoint,
          _at(e.shapes.single.startPoint.x, e.shapes.single.startPoint.y));
      expect(a.shapes.single.endPoint,
          _at(e.shapes.single.endPoint.x, e.shapes.single.endPoint.y));

      final at = a.texts.single;
      final et = e.texts.single;
      expect(at.x, closeTo(et.x, _eps));
      expect(at.y, closeTo(et.y, _eps));
      expect(at.width, closeTo(et.width!, _eps));
      expect(at.height, closeTo(et.height!, _eps));

      expect(a.images.single.x, closeTo(e.images.single.x, _eps));
      expect(a.images.single.y, closeTo(e.images.single.y, _eps));

      final an = a.stickyNotes.single;
      final en = e.stickyNotes.single;
      expect(an.x, closeTo(en.x, _eps));
      expect(an.y, closeTo(en.y, _eps));
      expect(an.width, closeTo(en.width, _eps));
      expect(an.height, closeTo(en.height, _eps));
      final ansh = an.shapes.single;
      final ensh = en.shapes.single;
      expect(ansh.startPoint, _at(ensh.startPoint.x, ensh.startPoint.y));
      expect(ansh.endPoint, _at(ensh.endPoint.x, ensh.endPoint.y));
    }

    test('4 x cw90 returns to the original', () {
      final page = richPage();
      expectSameGeometry(_rotateN(page, RotationAngle.cw90, 4), page);
    });

    test('4 x ccw90 returns to the original', () {
      final page = richPage();
      expectSameGeometry(_rotateN(page, RotationAngle.ccw90, 4), page);
    });

    test('cw90 then ccw90 is the identity', () {
      final page = richPage();
      final r = PageRotationService.rotatePage(
        PageRotationService.rotatePage(page, RotationAngle.cw90),
        RotationAngle.ccw90,
      );
      expectSameGeometry(r, page);
    });

    test('2 x cw90 equals half and 2 x half is the identity', () {
      final page = richPage();
      expectSameGeometry(
        _rotateN(page, RotationAngle.cw90, 2),
        PageRotationService.rotatePage(page, RotationAngle.half),
      );
      expectSameGeometry(_rotateN(page, RotationAngle.half, 2), page);
    });
  });
}

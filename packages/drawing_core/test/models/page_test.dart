import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('Page', () {
    test('should create with factory', () {
      final page = Page.create(index: 0);
      expect(page.index, 0);
      expect(page.size, PageSize.a4Portrait);
      expect(page.background.type, BackgroundType.blank);
      expect(page.layers.length, 1);
    });

    test('should create with custom size', () {
      final page = Page.create(
        index: 1,
        size: PageSize.letterLandscape,
        background: PageBackground.grid,
      );
      expect(page.size, PageSize.letterLandscape);
      expect(page.background.type, BackgroundType.grid);
    });

    test('should calculate stroke count', () {
      final stroke = Stroke.create(
        style: StrokeStyle.pen(),
        points: [DrawingPoint(x: 0, y: 0)],
      );
      final page = Page.create(index: 0).addStroke(stroke);
      expect(page.strokeCount, 1);
    });

    test('should detect empty page', () {
      final page = Page.create(index: 0);
      expect(page.isEmpty, true);
    });

    test('should add stroke to active layer', () {
      final stroke = Stroke.create(
        style: StrokeStyle.pen(),
        points: [DrawingPoint(x: 0, y: 0)],
      );
      final page = Page.create(index: 0).addStroke(stroke);
      expect(page.layers.last.strokes.length, 1);
    });

    test('should serialize to JSON', () {
      final page = Page.create(index: 0);
      final json = page.toJson();
      expect(json['index'], 0);
      expect(json['size'], isNotNull);
      expect(json['layers'], isNotEmpty);
    });

    test('should deserialize from JSON', () {
      final page = Page.create(index: 0);
      final json = page.toJson();
      final restored = Page.fromJson(json);
      expect(restored.id, page.id);
      expect(restored.index, page.index);
    });

    test('should copy with new values', () {
      final page = Page.create(index: 0);
      final copied = page.copyWith(index: 5);
      expect(copied.index, 5);
      expect(copied.id, page.id);
    });
  });
}

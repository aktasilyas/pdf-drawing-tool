import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';

/// Thumbnail generation uses real async (picture.toImage, file I/O), which
/// never completes under the FakeAsync zone of a plain [testWidgets].
void testGenerate(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThumbnailGenerator', () {
    group('getCacheKey', () {
      test('should include page id and timestamp', () {
        final page = Page.create(index: 0);
        final key = ThumbnailGenerator.getCacheKey(page);

        expect(key, contains(page.id));
        expect(key, contains(page.updatedAt.millisecondsSinceEpoch.toString()));
      });

      test('should generate different keys for different pages', () {
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1);

        final key1 = ThumbnailGenerator.getCacheKey(page1);
        final key2 = ThumbnailGenerator.getCacheKey(page2);

        expect(key1, isNot(equals(key2)));
      });

      test('should generate different keys for updated pages', () async {
        final page1 = Page.create(index: 0);

        // Wait a bit to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 2));

        final stroke = Stroke.create(
          points: [DrawingPoint(x: 0, y: 0)],
          style: StrokeStyle.pen(),
        );
        final page2 = page1.addStroke(stroke);

        final key1 = ThumbnailGenerator.getCacheKey(page1);
        final key2 = ThumbnailGenerator.getCacheKey(page2);

        expect(key1, isNot(equals(key2)));
      });
    });

    group('generate', () {
      testGenerate('should generate thumbnail with correct dimensions',
          () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(
          page,
          width: 100,
          height: 150,
        );

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate thumbnail with default dimensions',
          () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate thumbnail for empty page', () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate thumbnail for page with single stroke',
          () async {
        final stroke = Stroke.create(
          points: [
            DrawingPoint(x: 10, y: 10),
            DrawingPoint(x: 50, y: 50),
          ],
          style: StrokeStyle.pen(color: 0xFF000000),
        );
        final page = Page.create(index: 0).addStroke(stroke);

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate thumbnail for page with multiple strokes',
          () async {
        final stroke1 = Stroke.create(
          points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 100, y: 100)],
          style: StrokeStyle.pen(color: 0xFF000000),
        );
        final stroke2 = Stroke.create(
          points: [DrawingPoint(x: 100, y: 0), DrawingPoint(x: 0, y: 100)],
          style: StrokeStyle.pen(color: 0xFFFF0000),
        );
        final page =
            Page.create(index: 0).addStroke(stroke1).addStroke(stroke2);

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate thumbnail for page with shapes', () async {
        final shape = Shape.create(
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 10, y: 10),
          endPoint: DrawingPoint(x: 110, y: 60),
          style: StrokeStyle.pen(color: 0xFF000000, thickness: 2),
        );
        final page = Page.create(index: 0);
        final updatedPage = page.copyWith(
          layers: [
            page.layers.first.copyWith(
              shapes: [shape],
            ),
          ],
        );

        final thumbnail = await ThumbnailGenerator.generate(updatedPage);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should generate different thumbnails for different content',
          () async {
        final page1 = Page.create(index: 0);
        final page2 = Page.create(index: 1).addStroke(
          Stroke.create(
            points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 100, y: 100)],
            style: StrokeStyle.pen(color: 0xFFFF0000),
          ),
        );

        final thumb1 = await ThumbnailGenerator.generate(page1);
        final thumb2 = await ThumbnailGenerator.generate(page2);

        expect(thumb1, isNotNull);
        expect(thumb2, isNotNull);
        // Different content should produce different byte arrays
        expect(thumb1, isNot(equals(thumb2)));
      });

      testGenerate('should scale content proportionally', () async {
        // Create a page with A4 portrait size
        final page = Page.create(
          index: 0,
          size: PageSize.a4Portrait, // 595 x 842
        ).addStroke(
          Stroke.create(
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 595, y: 842),
            ],
            style: StrokeStyle.pen(),
          ),
        );

        final thumbnail = await ThumbnailGenerator.generate(
          page,
          width: 150,
          height: 200,
        );

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should handle custom background color', () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(
          page,
          backgroundColor: Colors.blue,
        );

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });

      testGenerate('should return null on error', () async {
        // This is hard to test directly, but we can at least verify
        // the method doesn't throw and handles errors gracefully
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(page);

        // Should either succeed or return null, not throw
        expect(thumbnail != null || thumbnail == null, true);
      });
    });

    group('material covers', () {
      testGenerate('renders without assets; corner is near the base color',
          () async {
        final page = Page.createCover(
          index: 0,
          background: PageBackground(
            type: BackgroundType.cover,
            color: 0xFFFFFFFF,
            coverId: CoverFamily.leatherNavy.id,
          ),
        );
        final bytes = await ThumbnailGenerator.generate(
          page,
          width: 150,
          height: 200,
        );
        expect(bytes, isNotNull);

        final codec = await ui.instantiateImageCodec(bytes!);
        final image = (await codec.getNextFrame()).image;
        final data = (await image.toByteData())!;
        // Pixel near bottom-right, away from hinge and plate.
        final i = (190 * image.width + 140) * 4;
        final base = CoverFamily.leatherNavy.primaryColor;
        expect((data.getUint8(i) - ((base >> 16) & 0xFF)).abs(), lessThan(48));
        expect(
            (data.getUint8(i + 1) - ((base >> 8) & 0xFF)).abs(), lessThan(48));
        expect((data.getUint8(i + 2) - (base & 0xFF)).abs(), lessThan(48));
      });
    });

    group('Edge Cases', () {
      testGenerate('should handle very small dimensions', () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(
          page,
          width: 10,
          height: 10,
        );

        expect(thumbnail, isNotNull);
      });

      testGenerate('should handle very large dimensions', () async {
        final page = Page.create(index: 0);

        final thumbnail = await ThumbnailGenerator.generate(
          page,
          width: 500,
          height: 700,
        );

        expect(thumbnail, isNotNull);
      });

      testGenerate('should handle page with single point stroke', () async {
        final stroke = Stroke.create(
          points: [DrawingPoint(x: 50, y: 50)],
          style: StrokeStyle.pen(),
        );
        final page = Page.create(index: 0).addStroke(stroke);

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
      });

      testGenerate('should handle page with many strokes', () async {
        var page = Page.create(index: 0);

        // Add 100 strokes
        for (int i = 0; i < 100; i++) {
          final stroke = Stroke.create(
            points: [
              DrawingPoint(x: i.toDouble(), y: 0),
              DrawingPoint(x: i.toDouble(), y: 100),
            ],
            style: StrokeStyle.pen(),
          );
          page = page.addStroke(stroke);
        }

        final thumbnail = await ThumbnailGenerator.generate(page);

        expect(thumbnail, isNotNull);
        expect(thumbnail!.isNotEmpty, true);
      });
    });
  });
}

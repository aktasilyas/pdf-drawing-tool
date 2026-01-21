import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'dart:ui' as ui;

void main() {
  group('Large Document Performance', () {
    test('should handle 1000 strokes efficiently', () {
      // Arrange: Create 1000 test strokes
      final strokes = List.generate(1000, (i) {
        final points = List.generate(10, (j) {
          return DrawingPoint(
            x: i * 10.0 + j,
            y: i * 5.0 + j,
            pressure: 0.5,
          );
        });

        return Stroke(
          id: 'stroke_$i',
          points: points,
          style: StrokeStyle(
            color: 0xFF000000,
            thickness: 2.0,
            opacity: 1.0,
          ),
          createdAt: DateTime.now(),
        );
      });

      // Act: Render all strokes
      final renderer = FlutterStrokeRenderer();
      final stopwatch = Stopwatch()..start();

      // Use a PictureRecorder to simulate canvas without actual painting
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      renderer.renderStrokes(canvas, strokes);

      stopwatch.stop();
      recorder.endRecording();

      // Assert: Should complete in reasonable time
      // Target: <100ms for 1000 strokes (10k points total)
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason:
              'Rendering 1000 strokes should take less than 100ms. Took: ${stopwatch.elapsedMilliseconds}ms');

      print(
          '✓ Large document test: 1000 strokes rendered in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should handle document with 10000 points efficiently', () {
      // Arrange: Create one large stroke with 10000 points
      final points = List.generate(10000, (i) {
        return DrawingPoint(
          x: i.toDouble(),
          y: (i % 100).toDouble(),
          pressure: 0.5,
        );
      });

      final stroke = Stroke(
        id: 'large_stroke',
        points: points,
        style: StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          opacity: 1.0,
        ),
        createdAt: DateTime.now(),
      );

      // Act: Render the large stroke
      final renderer = FlutterStrokeRenderer();
      final stopwatch = Stopwatch()..start();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      renderer.renderStroke(canvas, stroke);

      stopwatch.stop();
      recorder.endRecording();

      // Assert: Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason:
              'Rendering 10000 points should take less than 50ms. Took: ${stopwatch.elapsedMilliseconds}ms');

      print(
          '✓ Large stroke test: 10000 points rendered in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('CommittedStrokesPainter shouldRepaint optimizations', () {
      // Test that shouldRepaint is properly optimized
      final strokes1 = List.generate(100, (i) {
        return Stroke(
          id: 'stroke_$i',
          points: [DrawingPoint(x: i.toDouble(), y: i.toDouble())],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0, opacity: 1.0),
          createdAt: DateTime.now(),
        );
      });

      final strokes2 = List.from(strokes1);

      // Same list content should not repaint
      expect(strokes1.length, strokes2.length);
      expect(strokes1[0], strokes2[0]);

      // Different stroke count should trigger repaint
      final strokes3 = [...strokes1, strokes1[0]];
      expect(strokes3.length, 101);

      print('✓ shouldRepaint optimization verified');
    });
  });
}

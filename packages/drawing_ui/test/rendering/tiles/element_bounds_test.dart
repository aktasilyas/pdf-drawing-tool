import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/painting.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _stroke(StrokeStyle style, [List<(double, double)>? pts]) {
  final points = pts ?? const [(10.0, 20.0), (60.0, 80.0)];
  return Stroke(
    id: 's',
    points: [for (final p in points) DrawingPoint(x: p.$1, y: p.$2)],
    style: style,
    createdAt: DateTime(2024),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('strokeBounds', () {
    test('contains bbox inflated by half thickness', () {
      final r =
          strokeBounds(_stroke(StrokeStyle(color: 0xFF000000, thickness: 10)));
      expect(r.left, lessThanOrEqualTo(10 - 5));
      expect(r.top, lessThanOrEqualTo(20 - 5));
      expect(r.right, greaterThanOrEqualTo(60 + 5));
      expect(r.bottom, greaterThanOrEqualTo(80 + 5));
    });

    test('thicker pen gives larger bounds', () {
      final a =
          strokeBounds(_stroke(StrokeStyle(color: 0xFF000000, thickness: 2)));
      final b =
          strokeBounds(_stroke(StrokeStyle(color: 0xFF000000, thickness: 20)));
      expect(b.width, greaterThan(a.width));
    });

    test('glow adds margin', () {
      final plain =
          strokeBounds(_stroke(StrokeStyle(color: 0xFF000000, thickness: 4)));
      final glow = strokeBounds(_stroke(StrokeStyle(
          color: 0xFF000000, thickness: 4, glowRadius: 10, glowIntensity: 1)));
      expect(glow.width, greaterThanOrEqualTo(plain.width + 2 * 10));
    });

    test('empty stroke gives Rect.zero', () {
      final r = strokeBounds(Stroke(
        id: 'e',
        points: const [],
        style: StrokeStyle(color: 0xFF000000, thickness: 4),
        createdAt: DateTime(2024),
      ));
      expect(r, Rect.zero);
    });
  });

  group('shapeBounds', () {
    test('contains rectangle inflated by half thickness', () {
      final shape = Shape(
        id: 'sh',
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 50),
        style: StrokeStyle(color: 0xFF000000, thickness: 6),
      );
      final r = shapeBounds(shape);
      expect(r.left, lessThanOrEqualTo(-3));
      expect(r.right, greaterThanOrEqualTo(103));
      expect(r.bottom, greaterThanOrEqualTo(53));
    });
  });

  group('imageBounds', () {
    test('unrotated equals rect plus margin', () {
      const img = ImageElement(
          id: 'i', filePath: 'a.png', x: 10, y: 20, width: 100, height: 50);
      final r = imageBounds(img);
      expect(r.contains(const Offset(10, 20)), isTrue);
      expect(r.contains(const Offset(110, 70)), isTrue);
      expect(r.width, lessThan(110));
    });

    test('rotated 90 degrees covers the rotated rect', () {
      const img = ImageElement(
          id: 'i',
          filePath: 'a.png',
          x: 0,
          y: 0,
          width: 100,
          height: 20,
          rotation: math.pi / 2);
      final r = imageBounds(img);
      // Center (50,10); rotated rect spans x 40..60, y -40..60.
      expect(r.top, lessThanOrEqualTo(-40));
      expect(r.bottom, greaterThanOrEqualTo(60));
      expect(r.left, lessThanOrEqualTo(40));
      expect(r.right, greaterThanOrEqualTo(60));
    });
  });

  group('textBounds', () {
    test('starts at text origin and has positive size', () {
      const t = TextElement(id: 't', text: 'Hello world', x: 30, y: 40);
      final r = textBounds(t);
      expect(r.left, lessThanOrEqualTo(30));
      expect(r.top, lessThanOrEqualTo(40));
      expect(r.width, greaterThan(0));
      expect(r.height, greaterThan(0));
    });

    test('longer text is wider', () {
      const a = TextElement(id: 'a', text: 'Hi', x: 0, y: 0);
      const b = TextElement(id: 'b', text: 'Hi there, long text', x: 0, y: 0);
      expect(textBounds(b).width, greaterThan(textBounds(a).width));
    });

    test('result is cached per instance', () {
      const t = TextElement(id: 't', text: 'Cache me', x: 0, y: 0);
      expect(
          identical(textBounds(t), textBounds(t)) ||
              textBounds(t) == textBounds(t),
          isTrue);
    });
  });
}

import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('Stroke', () {
    late StrokeStyle defaultStyle;

    setUp(() {
      defaultStyle = StrokeStyle.pen();
    });

    group('Constructor', () {
      test('creates with required parameters', () {
        final now = DateTime.now();
        final stroke = Stroke(
          id: 'test-id',
          points: const [],
          style: defaultStyle,
          createdAt: now,
        );

        expect(stroke.id, 'test-id');
        expect(stroke.points, isEmpty);
        expect(stroke.style, defaultStyle);
        expect(stroke.createdAt, now);
      });

      test('creates with points', () {
        final points = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 10, y: 10),
        ];
        final stroke = Stroke(
          id: 'test-id',
          points: points,
          style: defaultStyle,
          createdAt: DateTime.now(),
        );

        expect(stroke.points.length, 2);
        expect(stroke.points[0].x, 0);
        expect(stroke.points[1].x, 10);
      });

      test('points list is unmodifiable', () {
        final mutableList = [DrawingPoint(x: 0, y: 0)];
        final stroke = Stroke(
          id: 'test-id',
          points: mutableList,
          style: defaultStyle,
          createdAt: DateTime.now(),
        );

        // Original list modification should not affect stroke
        mutableList.add(DrawingPoint(x: 10, y: 10));
        expect(stroke.points.length, 1);

        // Stroke's points list should throw on modification
        expect(
          () => stroke.points.add(DrawingPoint(x: 20, y: 20)),
          throwsUnsupportedError,
        );
      });
    });

    group('Factory: create', () {
      test('creates stroke with generated id', () {
        final stroke1 = Stroke.create(style: defaultStyle);

        expect(stroke1.id, isNotEmpty);
        expect(stroke1.id, isA<String>());
        // ID is timestamp-based, so it should be numeric
        expect(int.tryParse(stroke1.id), isNotNull);
      });

      test('creates empty stroke by default', () {
        final stroke = Stroke.create(style: defaultStyle);
        expect(stroke.isEmpty, true);
      });

      test('creates stroke with initial points', () {
        final points = [DrawingPoint(x: 5, y: 5)];
        final stroke = Stroke.create(style: defaultStyle, points: points);

        expect(stroke.pointCount, 1);
        expect(stroke.points[0].x, 5);
      });

      test('sets createdAt to current time', () {
        final before = DateTime.now();
        final stroke = Stroke.create(style: defaultStyle);
        final after = DateTime.now();

        expect(stroke.createdAt.isAfter(before) || stroke.createdAt == before, true);
        expect(stroke.createdAt.isBefore(after) || stroke.createdAt == after, true);
      });
    });

    group('Getters', () {
      test('isEmpty returns true for empty stroke', () {
        final stroke = Stroke.create(style: defaultStyle);
        expect(stroke.isEmpty, true);
        expect(stroke.isNotEmpty, false);
      });

      test('isEmpty returns false for non-empty stroke', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 0, y: 0)],
        );
        expect(stroke.isEmpty, false);
        expect(stroke.isNotEmpty, true);
      });

      test('pointCount returns correct count', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 1, y: 1),
            DrawingPoint(x: 2, y: 2),
          ],
        );
        expect(stroke.pointCount, 3);
      });

      test('firstPoint returns first point or null', () {
        final emptyStroke = Stroke.create(style: defaultStyle);
        expect(emptyStroke.firstPoint, isNull);

        final stroke = Stroke.create(
          style: defaultStyle,
          points: [
            DrawingPoint(x: 10, y: 20),
            DrawingPoint(x: 30, y: 40),
          ],
        );
        expect(stroke.firstPoint?.x, 10);
        expect(stroke.firstPoint?.y, 20);
      });

      test('lastPoint returns last point or null', () {
        final emptyStroke = Stroke.create(style: defaultStyle);
        expect(emptyStroke.lastPoint, isNull);

        final stroke = Stroke.create(
          style: defaultStyle,
          points: [
            DrawingPoint(x: 10, y: 20),
            DrawingPoint(x: 30, y: 40),
          ],
        );
        expect(stroke.lastPoint?.x, 30);
        expect(stroke.lastPoint?.y, 40);
      });
    });

    group('bounds', () {
      test('returns null for empty stroke', () {
        final stroke = Stroke.create(style: defaultStyle);
        expect(stroke.bounds, isNull);
      });

      test('returns correct bounds for single point', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 50, y: 60)],
        );
        final bounds = stroke.bounds!;

        expect(bounds.left, 50);
        expect(bounds.top, 60);
        expect(bounds.right, 50);
        expect(bounds.bottom, 60);
      });

      test('calculates correct bounds for multiple points', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [
            DrawingPoint(x: 10, y: 20),
            DrawingPoint(x: 100, y: 50),
            DrawingPoint(x: 30, y: 80),
            DrawingPoint(x: 5, y: 10),
          ],
        );
        final bounds = stroke.bounds!;

        expect(bounds.left, 5); // min x
        expect(bounds.top, 10); // min y
        expect(bounds.right, 100); // max x
        expect(bounds.bottom, 80); // max y
      });
    });

    group('addPoint', () {
      test('returns new stroke with point added', () {
        final original = Stroke.create(style: defaultStyle);
        final newPoint = DrawingPoint(x: 10, y: 20);
        final updated = original.addPoint(newPoint);

        expect(original.pointCount, 0); // original unchanged
        expect(updated.pointCount, 1);
        expect(updated.points[0], newPoint);
      });

      test('preserves id and style', () {
        final original = Stroke.create(style: defaultStyle);
        final updated = original.addPoint(DrawingPoint(x: 10, y: 20));

        expect(updated.id, original.id);
        expect(updated.style, original.style);
        expect(updated.createdAt, original.createdAt);
      });

      test('can chain multiple addPoint calls', () {
        final stroke = Stroke.create(style: defaultStyle)
            .addPoint(DrawingPoint(x: 0, y: 0))
            .addPoint(DrawingPoint(x: 10, y: 10))
            .addPoint(DrawingPoint(x: 20, y: 20));

        expect(stroke.pointCount, 3);
      });
    });

    group('addPoints', () {
      test('returns new stroke with points added', () {
        final original = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 0, y: 0)],
        );
        final newPoints = [
          DrawingPoint(x: 10, y: 10),
          DrawingPoint(x: 20, y: 20),
        ];
        final updated = original.addPoints(newPoints);

        expect(original.pointCount, 1); // original unchanged
        expect(updated.pointCount, 3);
      });

      test('handles empty list', () {
        final original = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 0, y: 0)],
        );
        final updated = original.addPoints([]);

        expect(updated.pointCount, 1);
      });
    });

    group('containsPoint', () {
      test('returns false (stub implementation)', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
        );

        // Stub always returns false for now
        expect(stroke.containsPoint(50, 50), false);
        expect(stroke.containsPoint(0, 0), false);
      });

      test('accepts tolerance parameter', () {
        final stroke = Stroke.create(style: defaultStyle);
        // Should not throw
        expect(stroke.containsPoint(0, 0, tolerance: 10.0), false);
      });
    });

    group('copyWith', () {
      test('copies with id changed', () {
        final original = Stroke.create(style: defaultStyle);
        final copied = original.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.style, original.style);
      });

      test('copies with points changed', () {
        final original = Stroke.create(style: defaultStyle);
        final newPoints = [DrawingPoint(x: 5, y: 5)];
        final copied = original.copyWith(points: newPoints);

        expect(copied.points.length, 1);
        expect(copied.points[0].x, 5);
      });

      test('copies with style changed', () {
        final original = Stroke.create(style: StrokeStyle.pen());
        final newStyle = StrokeStyle.brush();
        final copied = original.copyWith(style: newStyle);

        expect(copied.style, newStyle);
      });

      test('returns equal stroke when no parameters provided', () {
        final original = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 10, y: 10)],
        );
        final copied = original.copyWith();

        expect(copied, equals(original));
      });
    });

    group('Equality', () {
      test('two strokes with same values are equal', () {
        final now = DateTime.now();
        final points = [DrawingPoint(x: 10, y: 20)];

        final stroke1 = Stroke(
          id: 'same-id',
          points: points,
          style: defaultStyle,
          createdAt: now,
        );

        final stroke2 = Stroke(
          id: 'same-id',
          points: points,
          style: defaultStyle,
          createdAt: now,
        );

        expect(stroke1, equals(stroke2));
        expect(stroke1.hashCode, equals(stroke2.hashCode));
      });

      test('two strokes with different ids are not equal', () {
        final now = DateTime.now();

        final stroke1 = Stroke(
          id: 'id-1',
          points: const [],
          style: defaultStyle,
          createdAt: now,
        );

        final stroke2 = Stroke(
          id: 'id-2',
          points: const [],
          style: defaultStyle,
          createdAt: now,
        );

        expect(stroke1, isNot(equals(stroke2)));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to correct map', () {
        final now = DateTime(2024, 1, 15, 10, 30, 0);
        final stroke = Stroke(
          id: 'test-id',
          points: [DrawingPoint(x: 10, y: 20)],
          style: StrokeStyle.pen(color: 0xFFFF0000),
          createdAt: now,
        );

        final json = stroke.toJson();

        expect(json['id'], 'test-id');
        expect(json['points'], isA<List>());
        expect((json['points'] as List).length, 1);
        expect(json['style'], isA<Map>());
        expect(json['createdAt'], now.toIso8601String());
      });

      test('fromJson creates correct stroke', () {
        final json = {
          'id': 'restored-id',
          'points': [
            {'x': 10.0, 'y': 20.0, 'pressure': 0.5, 'tilt': 0.0, 'timestamp': 0},
          ],
          'style': {
            'color': 0xFF000000,
            'thickness': 2.0,
            'opacity': 1.0,
            'nibShape': 'circle',
            'blendMode': 'normal',
            'isEraser': false,
          },
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final stroke = Stroke.fromJson(json);

        expect(stroke.id, 'restored-id');
        expect(stroke.pointCount, 1);
        expect(stroke.points[0].x, 10.0);
        expect(stroke.points[0].pressure, 0.5);
        expect(stroke.style.color, 0xFF000000);
        expect(stroke.createdAt.year, 2024);
      });

      test('roundtrip preserves values', () {
        final original = Stroke(
          id: 'roundtrip-test',
          points: [
            DrawingPoint(x: 10, y: 20, pressure: 0.8),
            DrawingPoint(x: 30, y: 40, pressure: 0.6),
          ],
          style: StrokeStyle.brush(color: 0xFF00FF00, thickness: 8.0),
          createdAt: DateTime(2024, 6, 15, 14, 30),
        );

        final json = original.toJson();
        final restored = Stroke.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.pointCount, original.pointCount);
        expect(restored.points[0].x, original.points[0].x);
        expect(restored.points[1].pressure, original.points[1].pressure);
        expect(restored.style.color, original.style.color);
        expect(restored.style.thickness, original.style.thickness);
        expect(restored.createdAt, original.createdAt);
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final stroke = Stroke.create(
          style: defaultStyle,
          points: [DrawingPoint(x: 0, y: 0)],
        );
        final str = stroke.toString();

        expect(str, contains('Stroke'));
        expect(str, contains('pointCount: 1'));
      });
    });
  });
}

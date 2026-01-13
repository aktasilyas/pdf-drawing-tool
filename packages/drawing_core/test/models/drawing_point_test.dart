import 'package:test/test.dart';
import 'package:drawing_core/src/models/drawing_point.dart';

void main() {
  group('DrawingPoint', () {
    group('Constructor', () {
      test('creates with required parameters only', () {
        final point = DrawingPoint(x: 10.0, y: 20.0);

        expect(point.x, 10.0);
        expect(point.y, 20.0);
        expect(point.pressure, 1.0); // default
        expect(point.tilt, 0.0); // default
        expect(point.timestamp, 0); // default
      });

      test('creates with all parameters', () {
        final point = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        expect(point.x, 10.0);
        expect(point.y, 20.0);
        expect(point.pressure, 0.5);
        expect(point.tilt, 0.3);
        expect(point.timestamp, 1000);
      });
    });

    group('Pressure clamping', () {
      test('clamps pressure above 1.0 to 1.0', () {
        final point = DrawingPoint(x: 0, y: 0, pressure: 1.5);
        expect(point.pressure, 1.0);
      });

      test('clamps pressure below 0.0 to 0.0', () {
        final point = DrawingPoint(x: 0, y: 0, pressure: -0.5);
        expect(point.pressure, 0.0);
      });

      test('keeps valid pressure unchanged', () {
        final point = DrawingPoint(x: 0, y: 0, pressure: 0.7);
        expect(point.pressure, 0.7);
      });

      test('clamps boundary values correctly', () {
        final pointZero = DrawingPoint(x: 0, y: 0, pressure: 0.0);
        final pointOne = DrawingPoint(x: 0, y: 0, pressure: 1.0);

        expect(pointZero.pressure, 0.0);
        expect(pointOne.pressure, 1.0);
      });
    });

    group('copyWith', () {
      test('copies with single parameter changed', () {
        final original = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        final copied = original.copyWith(x: 15.0);

        expect(copied.x, 15.0);
        expect(copied.y, 20.0); // unchanged
        expect(copied.pressure, 0.5); // unchanged
        expect(copied.tilt, 0.3); // unchanged
        expect(copied.timestamp, 1000); // unchanged
      });

      test('copies with multiple parameters changed', () {
        final original = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        final copied = original.copyWith(
          x: 15.0,
          y: 25.0,
          pressure: 0.8,
        );

        expect(copied.x, 15.0);
        expect(copied.y, 25.0);
        expect(copied.pressure, 0.8);
        expect(copied.tilt, 0.3); // unchanged
        expect(copied.timestamp, 1000); // unchanged
      });

      test('copyWith clamps pressure values', () {
        final original = DrawingPoint(x: 10.0, y: 20.0);
        final copied = original.copyWith(pressure: 2.0);

        expect(copied.pressure, 1.0);
      });

      test('returns new instance when no parameters provided', () {
        final original = DrawingPoint(x: 10.0, y: 20.0);
        final copied = original.copyWith();

        expect(copied, equals(original));
        expect(identical(copied, original), isFalse);
      });
    });

    group('Equality', () {
      test('two points with same values are equal', () {
        final point1 = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        final point2 = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        expect(point1, equals(point2));
        expect(point1.hashCode, equals(point2.hashCode));
      });

      test('two points with different x are not equal', () {
        final point1 = DrawingPoint(x: 10.0, y: 20.0);
        final point2 = DrawingPoint(x: 15.0, y: 20.0);

        expect(point1, isNot(equals(point2)));
      });

      test('two points with different y are not equal', () {
        final point1 = DrawingPoint(x: 10.0, y: 20.0);
        final point2 = DrawingPoint(x: 10.0, y: 25.0);

        expect(point1, isNot(equals(point2)));
      });

      test('two points with different pressure are not equal', () {
        final point1 = DrawingPoint(x: 10.0, y: 20.0, pressure: 0.5);
        final point2 = DrawingPoint(x: 10.0, y: 20.0, pressure: 0.8);

        expect(point1, isNot(equals(point2)));
      });

      test('two points with different tilt are not equal', () {
        final point1 = DrawingPoint(x: 10.0, y: 20.0, tilt: 0.3);
        final point2 = DrawingPoint(x: 10.0, y: 20.0, tilt: 0.5);

        expect(point1, isNot(equals(point2)));
      });

      test('two points with different timestamp are not equal', () {
        final point1 = DrawingPoint(x: 10.0, y: 20.0, timestamp: 1000);
        final point2 = DrawingPoint(x: 10.0, y: 20.0, timestamp: 2000);

        expect(point1, isNot(equals(point2)));
      });
    });

    group('toJson', () {
      test('converts to correct JSON map', () {
        final point = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        final json = point.toJson();

        expect(json, {
          'x': 10.0,
          'y': 20.0,
          'pressure': 0.5,
          'tilt': 0.3,
          'timestamp': 1000,
        });
      });

      test('converts default values correctly', () {
        final point = DrawingPoint(x: 10.0, y: 20.0);

        final json = point.toJson();

        expect(json['pressure'], 1.0);
        expect(json['tilt'], 0.0);
        expect(json['timestamp'], 0);
      });
    });

    group('fromJson', () {
      test('creates from complete JSON map', () {
        final json = {
          'x': 10.0,
          'y': 20.0,
          'pressure': 0.5,
          'tilt': 0.3,
          'timestamp': 1000,
        };

        final point = DrawingPoint.fromJson(json);

        expect(point.x, 10.0);
        expect(point.y, 20.0);
        expect(point.pressure, 0.5);
        expect(point.tilt, 0.3);
        expect(point.timestamp, 1000);
      });

      test('creates from minimal JSON map with defaults', () {
        final json = {
          'x': 10.0,
          'y': 20.0,
        };

        final point = DrawingPoint.fromJson(json);

        expect(point.x, 10.0);
        expect(point.y, 20.0);
        expect(point.pressure, 1.0);
        expect(point.tilt, 0.0);
        expect(point.timestamp, 0);
      });

      test('handles integer values in JSON', () {
        final json = {
          'x': 10,
          'y': 20,
          'pressure': 1,
          'tilt': 0,
          'timestamp': 1000,
        };

        final point = DrawingPoint.fromJson(json);

        expect(point.x, 10.0);
        expect(point.y, 20.0);
        expect(point.pressure, 1.0);
        expect(point.tilt, 0.0);
        expect(point.timestamp, 1000);
      });

      test('clamps invalid pressure from JSON', () {
        final json = {
          'x': 10.0,
          'y': 20.0,
          'pressure': 2.0,
        };

        final point = DrawingPoint.fromJson(json);

        expect(point.pressure, 1.0);
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final point = DrawingPoint(
          x: 10.0,
          y: 20.0,
          pressure: 0.5,
          tilt: 0.3,
          timestamp: 1000,
        );

        expect(
          point.toString(),
          'DrawingPoint(x: 10.0, y: 20.0, pressure: 0.5, tilt: 0.3, timestamp: 1000)',
        );
      });
    });

    group('JSON roundtrip', () {
      test('toJson and fromJson are inverse operations', () {
        final original = DrawingPoint(
          x: 10.5,
          y: 20.5,
          pressure: 0.75,
          tilt: 0.25,
          timestamp: 12345,
        );

        final json = original.toJson();
        final restored = DrawingPoint.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}

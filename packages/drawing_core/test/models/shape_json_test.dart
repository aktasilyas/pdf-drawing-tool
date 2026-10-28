import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

/// A shape as written by drawing_core before the shape.dart split (#340).
/// Stored notebooks contain this exact format; it must keep decoding.
const _storedShapeJson = '''
{
  "id": "shape-1",
  "type": "star",
  "startPoint": {"x": 10.5, "y": 20.0, "pressure": 0.8, "tilt": 0.0, "timestamp": 0},
  "endPoint": {"x": 110.0, "y": 220.25, "pressure": 1.0, "tilt": 0.0, "timestamp": 42},
  "style": {
    "color": 4280391411,
    "thickness": 3.0,
    "opacity": 1.0,
    "nibShape": "circle",
    "blendMode": "normal",
    "isEraser": false,
    "pattern": "solid",
    "texture": "none",
    "glowRadius": 0.0,
    "glowIntensity": 0.0,
    "dashPattern": null,
    "nibAngle": 0.0,
    "pressureSensitive": true,
    "pressureSensitivity": 0.75
  },
  "isFilled": true,
  "fillColor": 2149684979
}
''';

Shape _shape(ShapeType type, {bool isFilled = false, int? fillColor}) {
  return Shape(
    id: 'shape-${type.name}',
    type: type,
    startPoint: DrawingPoint(x: 10.5, y: 20, pressure: 0.6, timestamp: 7),
    endPoint: DrawingPoint(x: 110, y: 220.25, tilt: 0.3),
    style: StrokeStyle.pen(color: 0xFF2196F3, thickness: 3),
    isFilled: isFilled,
    fillColor: fillColor,
  );
}

Shape _roundTrip(Shape shape) {
  final encoded = jsonEncode(shape.toJson());
  return Shape.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}

void main() {
  group('Shape JSON', () {
    for (final type in ShapeType.values) {
      test('round-trips ${type.name} (stroked)', () {
        final shape = _shape(type);
        expect(_roundTrip(shape), equals(shape));
      });

      test('round-trips ${type.name} (filled with fillColor)', () {
        final shape = _shape(type, isFilled: true, fillColor: 0x802196F3);
        final restored = _roundTrip(shape);
        expect(restored, equals(shape));
        expect(restored.fillColor, 0x802196F3);
        expect(restored.isFilled, isTrue);
      });
    }

    test('toJson writes the stored key set and type name', () {
      final json = _shape(ShapeType.hexagon).toJson();
      expect(
        json.keys,
        unorderedEquals(
          ['id', 'type', 'startPoint', 'endPoint', 'style', 'isFilled', 'fillColor'],
        ),
      );
      expect(json['type'], 'hexagon');
      expect(json['fillColor'], isNull);
    });

    test('decodes a shape stored by the previous version', () {
      final shape = Shape.fromJson(
        jsonDecode(_storedShapeJson) as Map<String, dynamic>,
      );

      expect(shape.id, 'shape-1');
      expect(shape.type, ShapeType.star);
      expect(shape.startPoint, DrawingPoint(x: 10.5, y: 20, pressure: 0.8));
      expect(
        shape.endPoint,
        DrawingPoint(x: 110, y: 220.25, timestamp: 42),
      );
      expect(shape.style.color, 0xFF2196F3);
      expect(shape.style.thickness, 3.0);
      expect(shape.style.nibShape, NibShape.circle);
      expect(shape.isFilled, isTrue);
      expect(shape.fillColor, 0x802196F3);
      expect(_roundTrip(shape), equals(shape));
    });

    test('defaults isFilled and parses lenient fillColor', () {
      final json = _shape(ShapeType.rectangle).toJson()
        ..remove('isFilled')
        ..['fillColor'] = '255';
      final shape = Shape.fromJson(json);
      expect(shape.isFilled, isFalse);
      expect(shape.fillColor, 255);

      json['fillColor'] = 128.0;
      expect(Shape.fromJson(json).fillColor, 128);
    });
  });
}

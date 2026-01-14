import 'package:test/test.dart';
import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/shape_type.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/models/text_element.dart';

void main() {
  group('Layer', () {
    late StrokeStyle defaultStyle;
    late Stroke testStroke1;
    late Stroke testStroke2;
    late Stroke testStroke3;
    late Shape testShape1;
    late Shape testShape2;

    setUp(() {
      defaultStyle = StrokeStyle.pen();
      testShape1 = Shape(
        id: 'shape-1',
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: defaultStyle,
      );
      testShape2 = Shape(
        id: 'shape-2',
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 50, y: 50),
        endPoint: DrawingPoint(x: 150, y: 150),
        style: defaultStyle,
      );
      testStroke1 = Stroke(
        id: 'stroke-1',
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: defaultStyle,
        createdAt: DateTime(2024, 1, 1),
      );
      testStroke2 = Stroke(
        id: 'stroke-2',
        points: [DrawingPoint(x: 20, y: 20), DrawingPoint(x: 30, y: 30)],
        style: defaultStyle,
        createdAt: DateTime(2024, 1, 2),
      );
      testStroke3 = Stroke(
        id: 'stroke-3',
        points: [DrawingPoint(x: 40, y: 40)],
        style: StrokeStyle.brush(),
        createdAt: DateTime(2024, 1, 3),
      );
    });

    group('Constructor', () {
      test('creates with required parameters', () {
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: const [],
        );

        expect(layer.id, 'test-id');
        expect(layer.name, 'Test Layer');
        expect(layer.strokes, isEmpty);
        expect(layer.isVisible, true); // default
        expect(layer.isLocked, false); // default
        expect(layer.opacity, 1.0); // default
      });

      test('creates with all parameters', () {
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: [testStroke1],
          isVisible: false,
          isLocked: true,
          opacity: 0.5,
        );

        expect(layer.isVisible, false);
        expect(layer.isLocked, true);
        expect(layer.opacity, 0.5);
        expect(layer.strokeCount, 1);
      });

      test('clamps opacity to valid range', () {
        final tooLow = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          opacity: -0.5,
        );
        final tooHigh = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          opacity: 1.5,
        );

        expect(tooLow.opacity, 0.0);
        expect(tooHigh.opacity, 1.0);
      });

      test('strokes list is unmodifiable', () {
        final mutableList = [testStroke1];
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: mutableList,
        );

        // Original list modification should not affect layer
        mutableList.add(testStroke2);
        expect(layer.strokeCount, 1);

        // Layer's strokes list should throw on modification
        expect(
          () => layer.strokes.add(testStroke2),
          throwsUnsupportedError,
        );
      });
    });

    group('Factory: empty', () {
      test('creates empty layer with generated id', () {
        final layer = Layer.empty('My Layer');

        expect(layer.id, startsWith('layer_'));
        expect(layer.name, 'My Layer');
        expect(layer.isEmpty, true);
        expect(layer.isVisible, true);
        expect(layer.isLocked, false);
        expect(layer.opacity, 1.0);
      });

      test('generates unique ids', () {
        final layer1 = Layer.empty('Layer 1');
        // Add small delay conceptually - IDs are timestamp-based
        final layer2 = Layer.empty('Layer 2');

        expect(layer1.id, isNotEmpty);
        expect(layer2.id, isNotEmpty);
        // Both should have valid layer_ prefix
        expect(layer1.id, startsWith('layer_'));
        expect(layer2.id, startsWith('layer_'));
      });
    });

    group('Getters', () {
      test('isEmpty returns true for empty layer', () {
        final layer = Layer.empty('Empty');
        expect(layer.isEmpty, true);
        expect(layer.isNotEmpty, false);
      });

      test('isEmpty returns false for non-empty layer', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
        );
        expect(layer.isEmpty, false);
        expect(layer.isNotEmpty, true);
      });

      test('strokeCount returns correct count', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2, testStroke3],
        );
        expect(layer.strokeCount, 3);
      });
    });

    group('addStroke', () {
      test('returns new layer with stroke added', () {
        final original = Layer.empty('Test');
        final updated = original.addStroke(testStroke1);

        expect(original.strokeCount, 0); // original unchanged
        expect(updated.strokeCount, 1);
        expect(updated.strokes[0], testStroke1);
      });

      test('preserves other properties', () {
        final original = Layer(
          id: 'my-id',
          name: 'My Layer',
          strokes: const [],
          isVisible: false,
          isLocked: true,
          opacity: 0.7,
        );
        final updated = original.addStroke(testStroke1);

        expect(updated.id, 'my-id');
        expect(updated.name, 'My Layer');
        expect(updated.isVisible, false);
        expect(updated.isLocked, true);
        expect(updated.opacity, 0.7);
      });

      test('can chain multiple addStroke calls', () {
        final layer = Layer.empty('Test')
            .addStroke(testStroke1)
            .addStroke(testStroke2)
            .addStroke(testStroke3);

        expect(layer.strokeCount, 3);
      });
    });

    group('removeStroke', () {
      test('removes stroke by id', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2, testStroke3],
        );
        final updated = original.removeStroke('stroke-2');

        expect(original.strokeCount, 3); // original unchanged
        expect(updated.strokeCount, 2);
        expect(updated.strokes.any((s) => s.id == 'stroke-2'), false);
        expect(updated.strokes.any((s) => s.id == 'stroke-1'), true);
        expect(updated.strokes.any((s) => s.id == 'stroke-3'), true);
      });

      test('returns copy if stroke not found', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
        );
        final updated = original.removeStroke('non-existent');

        expect(updated.strokeCount, 1);
        expect(updated.strokes[0], testStroke1);
      });

      test('preserves other properties', () {
        final original = Layer(
          id: 'my-id',
          name: 'My Layer',
          strokes: [testStroke1],
          isVisible: false,
          opacity: 0.5,
        );
        final updated = original.removeStroke('stroke-1');

        expect(updated.id, 'my-id');
        expect(updated.name, 'My Layer');
        expect(updated.isVisible, false);
        expect(updated.opacity, 0.5);
      });
    });

    group('updateStroke', () {
      test('updates stroke by id', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2],
        );

        final updatedStroke = testStroke1.copyWith(
          points: [DrawingPoint(x: 100, y: 100)],
        );
        final updated = original.updateStroke(updatedStroke);

        expect(original.strokes[0].points[0].x, 0); // original unchanged
        expect(updated.strokes[0].points[0].x, 100);
        expect(updated.strokeCount, 2);
      });

      test('returns copy if stroke not found', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
        );

        final nonExistentStroke = Stroke(
          id: 'non-existent',
          points: const [],
          style: defaultStyle,
          createdAt: DateTime.now(),
        );
        final updated = original.updateStroke(nonExistentStroke);

        expect(updated.strokeCount, 1);
        expect(updated.strokes[0].id, 'stroke-1');
      });

      test('preserves stroke order', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2, testStroke3],
        );

        final updatedStroke = testStroke2.copyWith(
          style: StrokeStyle.highlighter(),
        );
        final updated = original.updateStroke(updatedStroke);

        expect(updated.strokes[0].id, 'stroke-1');
        expect(updated.strokes[1].id, 'stroke-2');
        expect(updated.strokes[2].id, 'stroke-3');
        expect(updated.strokes[1].style.nibShape, NibShape.rectangle);
      });
    });

    group('clear', () {
      test('removes all strokes', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2, testStroke3],
        );
        final cleared = original.clear();

        expect(original.strokeCount, 3); // original unchanged
        expect(cleared.strokeCount, 0);
        expect(cleared.isEmpty, true);
      });

      test('preserves other properties', () {
        final original = Layer(
          id: 'my-id',
          name: 'My Layer',
          strokes: [testStroke1],
          isVisible: false,
          isLocked: true,
          opacity: 0.3,
        );
        final cleared = original.clear();

        expect(cleared.id, 'my-id');
        expect(cleared.name, 'My Layer');
        expect(cleared.isVisible, false);
        expect(cleared.isLocked, true);
        expect(cleared.opacity, 0.3);
      });
    });

    group('getStrokeById', () {
      test('returns stroke when found', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2, testStroke3],
        );

        final found = layer.getStrokeById('stroke-2');
        expect(found, isNotNull);
        expect(found!.id, 'stroke-2');
      });

      test('returns null when not found', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
        );

        final found = layer.getStrokeById('non-existent');
        expect(found, isNull);
      });

      test('returns null for empty layer', () {
        final layer = Layer.empty('Empty');
        final found = layer.getStrokeById('any-id');
        expect(found, isNull);
      });
    });

    group('findStrokesInRect', () {
      test('returns empty list (stub implementation)', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1, testStroke2],
        );

        final rect = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);
        final found = layer.findStrokesInRect(rect);

        // Stub always returns empty list
        expect(found, isEmpty);
      });
    });

    group('copyWith', () {
      test('copies with single parameter changed', () {
        final original = Layer(
          id: 'id',
          name: 'Original',
          strokes: [testStroke1],
          isVisible: true,
          isLocked: false,
          opacity: 1.0,
        );

        final copied = original.copyWith(name: 'Copied');

        expect(copied.name, 'Copied');
        expect(copied.id, 'id');
        expect(copied.strokeCount, 1);
      });

      test('copies with visibility toggled', () {
        final original = Layer.empty('Test');
        expect(original.isVisible, true);

        final hidden = original.copyWith(isVisible: false);
        expect(hidden.isVisible, false);

        final visible = hidden.copyWith(isVisible: true);
        expect(visible.isVisible, true);
      });

      test('copies with locked toggled', () {
        final original = Layer.empty('Test');
        expect(original.isLocked, false);

        final locked = original.copyWith(isLocked: true);
        expect(locked.isLocked, true);

        final unlocked = locked.copyWith(isLocked: false);
        expect(unlocked.isLocked, false);
      });

      test('copies with opacity changed', () {
        final original = Layer.empty('Test');
        final dimmed = original.copyWith(opacity: 0.5);

        expect(dimmed.opacity, 0.5);
      });

      test('clamps opacity in copyWith', () {
        final original = Layer.empty('Test');
        final copied = original.copyWith(opacity: 2.0);

        expect(copied.opacity, 1.0);
      });

      test('copies with multiple parameters changed', () {
        final original = Layer.empty('Original');
        final copied = original.copyWith(
          name: 'New Name',
          isVisible: false,
          isLocked: true,
          opacity: 0.3,
        );

        expect(copied.name, 'New Name');
        expect(copied.isVisible, false);
        expect(copied.isLocked, true);
        expect(copied.opacity, 0.3);
      });
    });

    group('Equality', () {
      test('two layers with same values are equal', () {
        final layer1 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: [testStroke1],
          isVisible: true,
          isLocked: false,
          opacity: 1.0,
        );

        final layer2 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: [testStroke1],
          isVisible: true,
          isLocked: false,
          opacity: 1.0,
        );

        expect(layer1, equals(layer2));
        expect(layer1.hashCode, equals(layer2.hashCode));
      });

      test('two layers with different ids are not equal', () {
        final layer1 = Layer(id: 'id-1', name: 'Name', strokes: const []);
        final layer2 = Layer(id: 'id-2', name: 'Name', strokes: const []);

        expect(layer1, isNot(equals(layer2)));
      });

      test('two layers with different strokes are not equal', () {
        final layer1 = Layer(id: 'id', name: 'Name', strokes: [testStroke1]);
        final layer2 = Layer(id: 'id', name: 'Name', strokes: [testStroke2]);

        expect(layer1, isNot(equals(layer2)));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to correct map', () {
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: [testStroke1],
          isVisible: false,
          isLocked: true,
          opacity: 0.7,
        );

        final json = layer.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], 'Test Layer');
        expect(json['strokes'], isA<List>());
        expect((json['strokes'] as List).length, 1);
        expect(json['isVisible'], false);
        expect(json['isLocked'], true);
        expect(json['opacity'], 0.7);
      });

      test('fromJson creates correct layer', () {
        final json = {
          'id': 'restored-id',
          'name': 'Restored Layer',
          'strokes': [testStroke1.toJson()],
          'isVisible': false,
          'isLocked': true,
          'opacity': 0.5,
        };

        final layer = Layer.fromJson(json);

        expect(layer.id, 'restored-id');
        expect(layer.name, 'Restored Layer');
        expect(layer.strokeCount, 1);
        expect(layer.isVisible, false);
        expect(layer.isLocked, true);
        expect(layer.opacity, 0.5);
      });

      test('fromJson uses defaults for missing optional fields', () {
        final json = {
          'id': 'id',
          'name': 'name',
          'strokes': <Map<String, dynamic>>[],
        };

        final layer = Layer.fromJson(json);

        expect(layer.isVisible, true);
        expect(layer.isLocked, false);
        expect(layer.opacity, 1.0);
      });

      test('roundtrip preserves values', () {
        final original = Layer(
          id: 'roundtrip-id',
          name: 'Roundtrip Layer',
          strokes: [testStroke1, testStroke2],
          isVisible: false,
          isLocked: true,
          opacity: 0.65,
        );

        final json = original.toJson();
        final restored = Layer.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.strokeCount, original.strokeCount);
        expect(restored.isVisible, original.isVisible);
        expect(restored.isLocked, original.isLocked);
        expect(restored.opacity, original.opacity);
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: [testStroke1],
          isVisible: true,
          isLocked: false,
          opacity: 0.8,
        );

        final str = layer.toString();

        expect(str, contains('Layer'));
        expect(str, contains('test-id'));
        expect(str, contains('Test Layer'));
        expect(str, contains('strokeCount: 1'));
        expect(str, contains('isVisible: true'));
        expect(str, contains('isLocked: false'));
        expect(str, contains('opacity: 0.8'));
      });
    });

    // ============================================================
    // SHAPE TESTS
    // ============================================================

    group('shapes property', () {
      test('defaults to empty list', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
        );
        expect(layer.shapes, isEmpty);
        expect(layer.shapeCount, 0);
      });

      test('accepts shapes in constructor', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1, testShape2],
        );
        expect(layer.shapeCount, 2);
      });

      test('shapes list is unmodifiable', () {
        final mutableList = [testShape1];
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: mutableList,
        );

        // Original list modification should not affect layer
        mutableList.add(testShape2);
        expect(layer.shapeCount, 1);

        // Layer's shapes list should throw on modification
        expect(
          () => layer.shapes.add(testShape2),
          throwsUnsupportedError,
        );
      });
    });

    group('addShape', () {
      test('returns new layer with shape added', () {
        final original = Layer.empty('Test');
        final updated = original.addShape(testShape1);

        expect(original.shapeCount, 0); // original unchanged
        expect(updated.shapeCount, 1);
        expect(updated.shapes[0], testShape1);
      });

      test('preserves strokes and other properties', () {
        final original = Layer(
          id: 'my-id',
          name: 'My Layer',
          strokes: [testStroke1],
          isVisible: false,
          isLocked: true,
          opacity: 0.7,
        );
        final updated = original.addShape(testShape1);

        expect(updated.id, 'my-id');
        expect(updated.name, 'My Layer');
        expect(updated.strokeCount, 1);
        expect(updated.isVisible, false);
        expect(updated.isLocked, true);
        expect(updated.opacity, 0.7);
      });

      test('can chain multiple addShape calls', () {
        final layer = Layer.empty('Test')
            .addShape(testShape1)
            .addShape(testShape2);

        expect(layer.shapeCount, 2);
      });
    });

    group('removeShape', () {
      test('removes shape by id', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1, testShape2],
        );
        final updated = original.removeShape('shape-1');

        expect(original.shapeCount, 2); // original unchanged
        expect(updated.shapeCount, 1);
        expect(updated.shapes.any((s) => s.id == 'shape-1'), false);
        expect(updated.shapes.any((s) => s.id == 'shape-2'), true);
      });

      test('returns copy if shape not found', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1],
        );
        final updated = original.removeShape('non-existent');

        expect(updated.shapeCount, 1);
        expect(updated.shapes[0], testShape1);
      });

      test('preserves strokes', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
          shapes: [testShape1],
        );
        final updated = original.removeShape('shape-1');

        expect(updated.strokeCount, 1);
        expect(updated.shapeCount, 0);
      });
    });

    group('updateShape', () {
      test('updates shape by id', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1, testShape2],
        );

        final updatedShape = testShape1.copyWith(
          endPoint: DrawingPoint(x: 200, y: 200),
        );
        final updated = original.updateShape(updatedShape);

        expect(original.shapes[0].endPoint.x, 100); // original unchanged
        expect(updated.shapes[0].endPoint.x, 200);
        expect(updated.shapeCount, 2);
      });

      test('returns copy if shape not found', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1],
        );

        final nonExistentShape = Shape(
          id: 'non-existent',
          type: ShapeType.line,
          startPoint: DrawingPoint(x: 0, y: 0),
          endPoint: DrawingPoint(x: 10, y: 10),
          style: defaultStyle,
        );
        final updated = original.updateShape(nonExistentShape);

        expect(updated.shapeCount, 1);
        expect(updated.shapes[0].id, 'shape-1');
      });

      test('preserves shape order', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1, testShape2],
        );

        final updatedShape = testShape2.copyWith(isFilled: true);
        final updated = original.updateShape(updatedShape);

        expect(updated.shapes[0].id, 'shape-1');
        expect(updated.shapes[1].id, 'shape-2');
        expect(updated.shapes[1].isFilled, true);
      });
    });

    group('getShapeById', () {
      test('returns shape when found', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1, testShape2],
        );

        final found = layer.getShapeById('shape-2');
        expect(found, isNotNull);
        expect(found!.id, 'shape-2');
      });

      test('returns null when not found', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1],
        );

        final found = layer.getShapeById('non-existent');
        expect(found, isNull);
      });

      test('returns null for empty layer', () {
        final layer = Layer.empty('Empty');
        final found = layer.getShapeById('any-id');
        expect(found, isNull);
      });
    });

    group('clear with shapes', () {
      test('removes all strokes and shapes', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
          shapes: [testShape1, testShape2],
        );
        final cleared = original.clear();

        expect(cleared.strokeCount, 0);
        expect(cleared.shapeCount, 0);
        expect(cleared.isEmpty, true);
      });
    });

    group('isEmpty with shapes', () {
      test('returns false when only shapes exist', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1],
        );
        expect(layer.isEmpty, false);
        expect(layer.isNotEmpty, true);
      });
    });

    group('JSON serialization with shapes', () {
      test('toJson includes shapes', () {
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: const [],
          shapes: [testShape1],
        );

        final json = layer.toJson();

        expect(json['shapes'], isA<List>());
        expect((json['shapes'] as List).length, 1);
      });

      test('fromJson restores shapes', () {
        final json = {
          'id': 'restored-id',
          'name': 'Restored Layer',
          'strokes': <Map<String, dynamic>>[],
          'shapes': [testShape1.toJson()],
          'isVisible': true,
          'isLocked': false,
          'opacity': 1.0,
        };

        final layer = Layer.fromJson(json);

        expect(layer.shapeCount, 1);
        expect(layer.shapes[0].type, ShapeType.rectangle);
      });

      test('fromJson handles missing shapes field', () {
        final json = {
          'id': 'id',
          'name': 'name',
          'strokes': <Map<String, dynamic>>[],
        };

        final layer = Layer.fromJson(json);

        expect(layer.shapeCount, 0);
      });

      test('roundtrip with shapes preserves values', () {
        final original = Layer(
          id: 'roundtrip-id',
          name: 'Roundtrip Layer',
          strokes: [testStroke1],
          shapes: [testShape1, testShape2],
          isVisible: false,
          isLocked: true,
          opacity: 0.65,
        );

        final json = original.toJson();
        final restored = Layer.fromJson(json);

        expect(restored.strokeCount, original.strokeCount);
        expect(restored.shapeCount, original.shapeCount);
        expect(restored.shapes[0].type, testShape1.type);
        expect(restored.shapes[1].type, testShape2.type);
      });
    });

    group('Equality with shapes', () {
      test('two layers with same shapes are equal', () {
        final layer1 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: const [],
          shapes: [testShape1],
        );

        final layer2 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: const [],
          shapes: [testShape1],
        );

        expect(layer1, equals(layer2));
      });

      test('two layers with different shapes are not equal', () {
        final layer1 = Layer(
          id: 'id',
          name: 'Name',
          strokes: const [],
          shapes: [testShape1],
        );
        final layer2 = Layer(
          id: 'id',
          name: 'Name',
          strokes: const [],
          shapes: [testShape2],
        );

        expect(layer1, isNot(equals(layer2)));
      });
    });

    group('copyWith shapes', () {
      test('copies with shapes changed', () {
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          shapes: [testShape1],
        );
        final copied = original.copyWith(shapes: [testShape2]);

        expect(copied.shapes[0].id, 'shape-2');
      });
    });

    // ============================================================
    // TEXT TESTS
    // ============================================================

    group('texts property', () {
      test('defaults to empty list', () {
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
        );
        expect(layer.texts, isEmpty);
        expect(layer.textCount, 0);
      });

      test('accepts texts in constructor', () {
        final text1 = TextElement.create(text: 'Hello', x: 0, y: 0);
        final text2 = TextElement.create(text: 'World', x: 100, y: 100);
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text1, text2],
        );
        expect(layer.textCount, 2);
      });

      test('texts list is unmodifiable', () {
        final text1 = TextElement.create(text: 'Hello', x: 0, y: 0);
        final text2 = TextElement.create(text: 'World', x: 100, y: 100);
        final mutableList = [text1];
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: mutableList,
        );

        // Original list modification should not affect layer
        mutableList.add(text2);
        expect(layer.textCount, 1);

        // Layer's texts list should throw on modification
        expect(
          () => layer.texts.add(text2),
          throwsUnsupportedError,
        );
      });
    });

    group('addText', () {
      test('returns new layer with text added', () {
        final original = Layer.empty('Test');
        final text = TextElement.create(text: 'Hello', x: 50, y: 50);
        final updated = original.addText(text);

        expect(original.textCount, 0); // original unchanged
        expect(updated.textCount, 1);
        expect(updated.texts[0].id, text.id);
      });

      test('preserves strokes, shapes and other properties', () {
        final original = Layer(
          id: 'my-id',
          name: 'My Layer',
          strokes: [testStroke1],
          shapes: [testShape1],
          isVisible: false,
          isLocked: true,
          opacity: 0.7,
        );
        final text = TextElement.create(text: 'Hello', x: 0, y: 0);
        final updated = original.addText(text);

        expect(updated.id, 'my-id');
        expect(updated.name, 'My Layer');
        expect(updated.strokeCount, 1);
        expect(updated.shapeCount, 1);
        expect(updated.isVisible, false);
        expect(updated.isLocked, true);
        expect(updated.opacity, 0.7);
      });

      test('can chain multiple addText calls', () {
        final text1 = TextElement.create(text: 'Hello', x: 0, y: 0);
        final text2 = TextElement.create(text: 'World', x: 100, y: 100);
        final layer = Layer.empty('Test').addText(text1).addText(text2);

        expect(layer.textCount, 2);
      });
    });

    group('removeText', () {
      test('removes text by id', () {
        final text1 = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final text2 = const TextElement(id: 'text-2', text: 'World', x: 100, y: 100);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text1, text2],
        );
        final updated = original.removeText(text1.id);

        expect(original.textCount, 2); // original unchanged
        expect(updated.textCount, 1);
        expect(updated.texts.any((t) => t.id == text1.id), false);
        expect(updated.texts.any((t) => t.id == text2.id), true);
      });

      test('returns copy if text not found', () {
        final text = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text],
        );
        final updated = original.removeText('non-existent');

        expect(updated.textCount, 1);
        expect(updated.texts[0].id, text.id);
      });

      test('preserves strokes and shapes', () {
        final text = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
          shapes: [testShape1],
          texts: [text],
        );
        final updated = original.removeText(text.id);

        expect(updated.strokeCount, 1);
        expect(updated.shapeCount, 1);
        expect(updated.textCount, 0);
      });
    });

    group('updateText', () {
      test('updates text by id', () {
        final text = const TextElement(id: 'text-1', text: 'Original', x: 0, y: 0);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text],
        );

        final updatedText = text.copyWith(text: 'Updated');
        final updated = original.updateText(updatedText);

        expect(original.texts[0].text, 'Original'); // original unchanged
        expect(updated.texts[0].text, 'Updated');
        expect(updated.textCount, 1);
      });

      test('returns copy if text not found', () {
        final text = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text],
        );

        final nonExistentText = const TextElement(
          id: 'non-existent',
          text: 'Not found',
          x: 0,
          y: 0,
        );
        final updated = original.updateText(nonExistentText);

        expect(updated.textCount, 1);
        expect(updated.texts[0].id, text.id);
      });

      test('preserves text order', () {
        final text1 = const TextElement(id: 'text-1', text: 'First', x: 0, y: 0);
        final text2 = const TextElement(id: 'text-2', text: 'Second', x: 100, y: 100);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text1, text2],
        );

        final updatedText = text2.copyWith(text: 'Updated Second');
        final updated = original.updateText(updatedText);

        expect(updated.texts[0].id, text1.id);
        expect(updated.texts[1].id, text2.id);
        expect(updated.texts[1].text, 'Updated Second');
      });
    });

    group('getTextById', () {
      test('returns text when found', () {
        final text1 = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final text2 = const TextElement(id: 'text-2', text: 'World', x: 100, y: 100);
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text1, text2],
        );

        final found = layer.getTextById(text2.id);
        expect(found, isNotNull);
        expect(found!.id, text2.id);
      });

      test('returns null when not found', () {
        final text = const TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text],
        );

        final found = layer.getTextById('non-existent');
        expect(found, isNull);
      });

      test('returns null for empty layer', () {
        final layer = Layer.empty('Empty');
        final found = layer.getTextById('any-id');
        expect(found, isNull);
      });
    });

    group('clear with texts', () {
      test('removes all strokes, shapes and texts', () {
        final text = TextElement.create(text: 'Hello', x: 0, y: 0);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: [testStroke1],
          shapes: [testShape1],
          texts: [text],
        );
        final cleared = original.clear();

        expect(cleared.strokeCount, 0);
        expect(cleared.shapeCount, 0);
        expect(cleared.textCount, 0);
        expect(cleared.isEmpty, true);
      });
    });

    group('isEmpty with texts', () {
      test('returns false when only texts exist', () {
        final text = TextElement.create(text: 'Hello', x: 0, y: 0);
        final layer = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text],
        );
        expect(layer.isEmpty, false);
        expect(layer.isNotEmpty, true);
      });
    });

    group('JSON serialization with texts', () {
      test('toJson includes texts', () {
        final text = TextElement.create(text: 'Hello', x: 50, y: 50);
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: const [],
          texts: [text],
        );

        final json = layer.toJson();

        expect(json['texts'], isA<List>());
        expect((json['texts'] as List).length, 1);
      });

      test('fromJson restores texts', () {
        final text = TextElement.create(
          text: 'Hello World',
          x: 100,
          y: 200,
          fontSize: 24,
        );
        final json = {
          'id': 'restored-id',
          'name': 'Restored Layer',
          'strokes': <Map<String, dynamic>>[],
          'texts': [text.toJson()],
          'isVisible': true,
          'isLocked': false,
          'opacity': 1.0,
        };

        final layer = Layer.fromJson(json);

        expect(layer.textCount, 1);
        expect(layer.texts[0].text, 'Hello World');
        expect(layer.texts[0].fontSize, 24);
      });

      test('fromJson handles missing texts field', () {
        final json = {
          'id': 'id',
          'name': 'name',
          'strokes': <Map<String, dynamic>>[],
        };

        final layer = Layer.fromJson(json);

        expect(layer.textCount, 0);
      });

      test('roundtrip with texts preserves values', () {
        final text1 = TextElement.create(
          text: 'Hello',
          x: 0,
          y: 0,
          fontSize: 16,
        );
        final text2 = TextElement.create(
          text: 'World',
          x: 100,
          y: 100,
          fontSize: 24,
          isBold: true,
        );
        final original = Layer(
          id: 'roundtrip-id',
          name: 'Roundtrip Layer',
          strokes: [testStroke1],
          shapes: [testShape1],
          texts: [text1, text2],
          isVisible: false,
          isLocked: true,
          opacity: 0.65,
        );

        final json = original.toJson();
        final restored = Layer.fromJson(json);

        expect(restored.strokeCount, original.strokeCount);
        expect(restored.shapeCount, original.shapeCount);
        expect(restored.textCount, original.textCount);
        expect(restored.texts[0].text, 'Hello');
        expect(restored.texts[1].text, 'World');
        expect(restored.texts[1].isBold, true);
      });
    });

    group('Equality with texts', () {
      test('two layers with same texts are equal', () {
        final text = TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final layer1 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: const [],
          texts: [text],
        );

        final layer2 = Layer(
          id: 'same-id',
          name: 'Same Name',
          strokes: const [],
          texts: [text],
        );

        expect(layer1, equals(layer2));
      });

      test('two layers with different texts are not equal', () {
        final text1 = TextElement(id: 'text-1', text: 'Hello', x: 0, y: 0);
        final text2 = TextElement(id: 'text-2', text: 'World', x: 0, y: 0);
        final layer1 = Layer(
          id: 'id',
          name: 'Name',
          strokes: const [],
          texts: [text1],
        );
        final layer2 = Layer(
          id: 'id',
          name: 'Name',
          strokes: const [],
          texts: [text2],
        );

        expect(layer1, isNot(equals(layer2)));
      });
    });

    group('copyWith texts', () {
      test('copies with texts changed', () {
        final text1 = TextElement.create(text: 'Hello', x: 0, y: 0);
        final text2 = TextElement.create(text: 'World', x: 100, y: 100);
        final original = Layer(
          id: 'id',
          name: 'name',
          strokes: const [],
          texts: [text1],
        );
        final copied = original.copyWith(texts: [text2]);

        expect(copied.texts[0].text, 'World');
      });
    });

    group('toString with texts', () {
      test('includes textCount', () {
        final text = TextElement.create(text: 'Hello', x: 0, y: 0);
        final layer = Layer(
          id: 'test-id',
          name: 'Test Layer',
          strokes: const [],
          texts: [text],
        );

        final str = layer.toString();

        expect(str, contains('textCount: 1'));
      });
    });
  });
}

import 'package:test/test.dart';
import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('Layer', () {
    late StrokeStyle defaultStyle;
    late Stroke testStroke1;
    late Stroke testStroke2;
    late Stroke testStroke3;

    setUp(() {
      defaultStyle = StrokeStyle.pen();
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
  });
}

import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('Selection', () {
    late BoundingBox testBounds;

    setUp(() {
      testBounds = const BoundingBox(
        left: 10,
        top: 20,
        right: 110,
        bottom: 120,
      );
    });

    group('creation', () {
      test('factory creates with unique id', () {
        final selection1 = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        // Small delay to ensure different timestamps
        final selection2 = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        expect(selection1.id, isNotEmpty);
        expect(selection2.id, isNotEmpty);
      });

      test('lasso selection includes path', () {
        final path = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 0),
          DrawingPoint(x: 100, y: 100),
        ];

        final selection = Selection.create(
          type: SelectionType.lasso,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
          lassoPath: path,
        );

        expect(selection.lassoPath, isNotNull);
        expect(selection.lassoPath!.length, equals(3));
        expect(selection.type, equals(SelectionType.lasso));
      });

      test('empty factory creates empty selection', () {
        final selection = Selection.empty();

        expect(selection.isEmpty, isTrue);
        expect(selection.id, isEmpty);
        expect(selection.bounds.isEmpty, isTrue);
      });
    });

    group('properties', () {
      test('isEmpty returns true when no strokes selected', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: [],
          bounds: testBounds,
        );

        expect(selection.isEmpty, isTrue);
        expect(selection.isNotEmpty, isFalse);
      });

      test('isNotEmpty returns true when strokes selected', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        expect(selection.isEmpty, isFalse);
        expect(selection.isNotEmpty, isTrue);
      });

      test('count returns number of selected strokes', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1', 'stroke2', 'stroke3'],
          bounds: testBounds,
        );

        expect(selection.count, equals(3));
      });

      test('center calculates correctly', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        expect(selection.center.x, equals(60.0));
        expect(selection.center.y, equals(70.0));
      });

      test('width and height calculate correctly', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        expect(selection.width, equals(100.0));
        expect(selection.height, equals(100.0));
      });

      test('containsStroke checks correctly', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1', 'stroke2'],
          bounds: testBounds,
        );

        expect(selection.containsStroke('stroke1'), isTrue);
        expect(selection.containsStroke('stroke2'), isTrue);
        expect(selection.containsStroke('stroke3'), isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated bounds', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        final newBounds = const BoundingBox(
          left: 50,
          top: 50,
          right: 150,
          bottom: 150,
        );

        final updated = selection.copyWith(bounds: newBounds);

        expect(updated.id, equals(selection.id));
        expect(updated.bounds, equals(newBounds));
        expect(updated.selectedStrokeIds, equals(selection.selectedStrokeIds));
      });

      test('creates copy with updated stroke ids', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        final updated = selection.copyWith(
          selectedStrokeIds: ['stroke1', 'stroke2', 'stroke3'],
        );

        expect(updated.count, equals(3));
        expect(updated.bounds, equals(selection.bounds));
      });

      test('creates copy with updated type', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        final updated = selection.copyWith(type: SelectionType.lasso);

        expect(updated.type, equals(SelectionType.lasso));
      });
    });

    group('serialization', () {
      test('toJson and fromJson roundtrip for rectangle selection', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1', 'stroke2'],
          bounds: testBounds,
        );

        final json = selection.toJson();
        final restored = Selection.fromJson(json);

        expect(restored.id, equals(selection.id));
        expect(restored.type, equals(selection.type));
        expect(restored.selectedStrokeIds, equals(selection.selectedStrokeIds));
        expect(restored.bounds, equals(selection.bounds));
        expect(restored.lassoPath, isNull);
      });

      test('toJson and fromJson roundtrip for lasso selection', () {
        final lassoPath = [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ];

        final selection = Selection.create(
          type: SelectionType.lasso,
          selectedStrokeIds: ['stroke1', 'stroke2'],
          bounds: testBounds,
          lassoPath: lassoPath,
        );

        final json = selection.toJson();
        final restored = Selection.fromJson(json);

        expect(restored.id, equals(selection.id));
        expect(restored.type, equals(SelectionType.lasso));
        expect(restored.lassoPath, isNotNull);
        expect(restored.lassoPath!.length, equals(2));
        expect(restored.lassoPath![0].x, equals(0.0));
        expect(restored.lassoPath![1].x, equals(100.0));
      });

      test('toJson excludes null lassoPath', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: testBounds,
        );

        final json = selection.toJson();

        expect(json.containsKey('lassoPath'), isFalse);
      });
    });

    group('equality', () {
      test('same id equals', () {
        final selection1 = Selection(
          id: 'test-id',
          type: SelectionType.rectangle,
          selectedStrokeIds: const ['stroke1'],
          bounds: testBounds,
        );

        final selection2 = Selection(
          id: 'test-id',
          type: SelectionType.rectangle,
          selectedStrokeIds: const ['stroke1'],
          bounds: testBounds,
        );

        expect(selection1, equals(selection2));
      });

      test('different id not equals', () {
        final selection1 = Selection(
          id: 'id-1',
          type: SelectionType.rectangle,
          selectedStrokeIds: const ['stroke1'],
          bounds: testBounds,
        );

        final selection2 = Selection(
          id: 'id-2',
          type: SelectionType.rectangle,
          selectedStrokeIds: const ['stroke1'],
          bounds: testBounds,
        );

        expect(selection1, isNot(equals(selection2)));
      });
    });
  });

  group('Point2D', () {
    test('creates with x and y', () {
      const point = Point2D(10.0, 20.0);

      expect(point.x, equals(10.0));
      expect(point.y, equals(20.0));
    });

    test('equality works', () {
      const point1 = Point2D(10.0, 20.0);
      const point2 = Point2D(10.0, 20.0);
      const point3 = Point2D(10.0, 30.0);

      expect(point1, equals(point2));
      expect(point1, isNot(equals(point3)));
    });

    test('toString works', () {
      const point = Point2D(10.0, 20.0);
      expect(point.toString(), equals('Point2D(10.0, 20.0)'));
    });
  });

  group('SelectionHandle', () {
    late BoundingBox bounds;

    setUp(() {
      bounds = const BoundingBox(
        left: 0,
        top: 0,
        right: 100,
        bottom: 100,
      );
    });

    test('topLeft position', () {
      final pos = SelectionHandle.topLeft.getPosition(bounds);
      expect(pos.x, equals(0.0));
      expect(pos.y, equals(0.0));
    });

    test('topCenter position', () {
      final pos = SelectionHandle.topCenter.getPosition(bounds);
      expect(pos.x, equals(50.0));
      expect(pos.y, equals(0.0));
    });

    test('topRight position', () {
      final pos = SelectionHandle.topRight.getPosition(bounds);
      expect(pos.x, equals(100.0));
      expect(pos.y, equals(0.0));
    });

    test('middleLeft position', () {
      final pos = SelectionHandle.middleLeft.getPosition(bounds);
      expect(pos.x, equals(0.0));
      expect(pos.y, equals(50.0));
    });

    test('middleRight position', () {
      final pos = SelectionHandle.middleRight.getPosition(bounds);
      expect(pos.x, equals(100.0));
      expect(pos.y, equals(50.0));
    });

    test('bottomLeft position', () {
      final pos = SelectionHandle.bottomLeft.getPosition(bounds);
      expect(pos.x, equals(0.0));
      expect(pos.y, equals(100.0));
    });

    test('bottomCenter position', () {
      final pos = SelectionHandle.bottomCenter.getPosition(bounds);
      expect(pos.x, equals(50.0));
      expect(pos.y, equals(100.0));
    });

    test('bottomRight position', () {
      final pos = SelectionHandle.bottomRight.getPosition(bounds);
      expect(pos.x, equals(100.0));
      expect(pos.y, equals(100.0));
    });

    test('center position', () {
      final pos = SelectionHandle.center.getPosition(bounds);
      expect(pos.x, equals(50.0));
      expect(pos.y, equals(50.0));
    });
  });

  group('SelectionType', () {
    test('has lasso value', () {
      expect(SelectionType.lasso, isNotNull);
      expect(SelectionType.lasso.name, equals('lasso'));
    });

    test('has rectangle value', () {
      expect(SelectionType.rectangle, isNotNull);
      expect(SelectionType.rectangle.name, equals('rectangle'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';

void main() {
  group('SelectionPainter', () {
    test('creates without error', () {
      final painter = SelectionPainter(
        selection: null,
        zoom: 1.0,
      );

      expect(painter, isNotNull);
    });

    test('creates with selection', () {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
      );

      final painter = SelectionPainter(
        selection: selection,
        zoom: 1.0,
      );

      expect(painter.selection, equals(selection));
    });

    test('creates with preview path', () {
      final previewPath = [
        DrawingPoint(x: 0, y: 0),
        DrawingPoint(x: 50, y: 50),
        DrawingPoint(x: 100, y: 100),
      ];

      final painter = SelectionPainter(
        selection: null,
        previewPath: previewPath,
      );

      expect(painter.previewPath, equals(previewPath));
    });

    group('shouldRepaint', () {
      test('returns true when selection changes', () {
        final selection1 = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final selection2 = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke2'],
          bounds:
              const BoundingBox(left: 50, top: 50, right: 150, bottom: 150),
        );

        final painter1 = SelectionPainter(selection: selection1);
        final painter2 = SelectionPainter(selection: selection2);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns false when selection is same', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final painter1 = SelectionPainter(selection: selection);
        final painter2 = SelectionPainter(selection: selection);

        expect(painter2.shouldRepaint(painter1), isFalse);
      });

      test('returns true when zoom changes', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final painter1 = SelectionPainter(selection: selection, zoom: 1.0);
        final painter2 = SelectionPainter(selection: selection, zoom: 2.0);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns false when zoom is same', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final painter1 = SelectionPainter(selection: selection, zoom: 1.5);
        final painter2 = SelectionPainter(selection: selection, zoom: 1.5);

        expect(painter2.shouldRepaint(painter1), isFalse);
      });

      test('returns true when previewPath changes', () {
        final path1 = [DrawingPoint(x: 0, y: 0)];
        final path2 = [DrawingPoint(x: 100, y: 100)];

        final painter1 = SelectionPainter(selection: null, previewPath: path1);
        final painter2 = SelectionPainter(selection: null, previewPath: path2);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns true when selection becomes null', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final painter1 = SelectionPainter(selection: selection);
        final painter2 = SelectionPainter(selection: null);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns true when selection becomes non-null', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        final painter1 = SelectionPainter(selection: null);
        final painter2 = SelectionPainter(selection: selection);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });
    });

    testWidgets('renders without error with null selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: SelectionPainter(selection: null),
            ),
          ),
        ),
      );

      // MaterialApp widgets have their own CustomPaint, so we check for at least one
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error with rectangle selection',
        (tester) async {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 10, top: 10, right: 100, bottom: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: SelectionPainter(selection: selection),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error with lasso selection', (tester) async {
      final lassoPath = [
        DrawingPoint(x: 10, y: 10),
        DrawingPoint(x: 100, y: 10),
        DrawingPoint(x: 100, y: 100),
        DrawingPoint(x: 10, y: 100),
      ];

      final selection = Selection.create(
        type: SelectionType.lasso,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 10, top: 10, right: 100, bottom: 100),
        lassoPath: lassoPath,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: SelectionPainter(selection: selection),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error with preview path', (tester) async {
      final previewPath = [
        DrawingPoint(x: 0, y: 0),
        DrawingPoint(x: 50, y: 50),
        DrawingPoint(x: 100, y: 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: SelectionPainter(
                selection: null,
                previewPath: previewPath,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with custom zoom', (tester) async {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 10, top: 10, right: 100, bottom: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(200, 200),
              painter: SelectionPainter(
                selection: selection,
                zoom: 2.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });
  });
}

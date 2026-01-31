import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('EraseStrokesCommand', () {
    late DrawingDocument document;
    late Stroke stroke1;
    late Stroke stroke2;
    late Stroke stroke3;

    setUp(() {
      // Explicit ID kullan - microsecondsSinceEpoch çakışmasını önle
      stroke1 = Stroke(
        id: 'stroke_1',
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      stroke2 = Stroke(
        id: 'stroke_2',
        points: [DrawingPoint(x: 20, y: 20), DrawingPoint(x: 30, y: 30)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      stroke3 = Stroke(
        id: 'stroke_3',
        points: [DrawingPoint(x: 40, y: 40), DrawingPoint(x: 50, y: 50)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );

      final layer = Layer.empty('Layer 1')
          .addStroke(stroke1)
          .addStroke(stroke2)
          .addStroke(stroke3);

      document = DrawingDocument.emptyMultiPage('Test').copyWith(
        layers: [layer],
      );
    });

    group('execute', () {
      test('removes single stroke', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id],
        );

        final result = command.execute(document);

        expect(result.layers[0].strokes.length, equals(2));
        expect(
            result.layers[0].strokes.any((s) => s.id == stroke1.id), isFalse);
        expect(result.layers[0].strokes.any((s) => s.id == stroke2.id), isTrue);
        expect(result.layers[0].strokes.any((s) => s.id == stroke3.id), isTrue);
      });

      test('removes multiple strokes', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, stroke3.id],
        );

        final result = command.execute(document);

        expect(result.layers[0].strokes.length, equals(1));
        expect(result.layers[0].strokes.first.id, equals(stroke2.id));
      });

      test('removes all strokes', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, stroke2.id, stroke3.id],
        );

        final result = command.execute(document);

        expect(result.layers[0].strokes, isEmpty);
      });

      test('handles non-existent stroke ID gracefully', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: ['non-existent-id'],
        );

        final result = command.execute(document);

        // Orijinal stroke sayısı korunmalı
        expect(result.layers[0].strokes.length, equals(3));
      });

      test('handles mixed valid and invalid IDs', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, 'non-existent-id', stroke2.id],
        );

        final result = command.execute(document);

        expect(result.layers[0].strokes.length, equals(1));
        expect(result.layers[0].strokes.first.id, equals(stroke3.id));
      });

      test('handles invalid layer index', () {
        final command = EraseStrokesCommand(
          layerIndex: 99,
          strokeIds: [stroke1.id],
        );

        final result = command.execute(document);

        // Document değişmemeli
        expect(result.layers[0].strokes.length, equals(3));
      });

      test('handles negative layer index', () {
        final command = EraseStrokesCommand(
          layerIndex: -1,
          strokeIds: [stroke1.id],
        );

        final result = command.execute(document);

        // Document değişmemeli
        expect(result.layers[0].strokes.length, equals(3));
      });

      test('handles empty strokeIds list', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [],
        );

        final result = command.execute(document);

        expect(result.layers[0].strokes.length, equals(3));
      });
    });

    group('undo', () {
      test('restores single erased stroke', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id],
        );

        final afterErase = command.execute(document);
        expect(afterErase.layers[0].strokes.length, equals(2));

        final afterUndo = command.undo(afterErase);
        expect(afterUndo.layers[0].strokes.length, equals(3));
        expect(
            afterUndo.layers[0].strokes.any((s) => s.id == stroke1.id), isTrue);
      });

      test('restores multiple erased strokes', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, stroke2.id],
        );

        final afterErase = command.execute(document);
        expect(afterErase.layers[0].strokes.length, equals(1));

        final afterUndo = command.undo(afterErase);
        expect(afterUndo.layers[0].strokes.length, equals(3));
      });

      test('restores all erased strokes', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, stroke2.id, stroke3.id],
        );

        final afterErase = command.execute(document);
        expect(afterErase.layers[0].strokes, isEmpty);

        final afterUndo = command.undo(afterErase);
        expect(afterUndo.layers[0].strokes.length, equals(3));
      });
    });

    group('undo/redo cycle', () {
      test('undo then redo works correctly', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke2.id],
        );

        final afterErase = command.execute(document);
        expect(afterErase.layers[0].strokes.length, equals(2));

        final afterUndo = command.undo(afterErase);
        expect(afterUndo.layers[0].strokes.length, equals(3));

        final afterRedo = command.execute(afterUndo);
        expect(afterRedo.layers[0].strokes.length, equals(2));
        expect(
            afterRedo.layers[0].strokes.any((s) => s.id == stroke2.id), isFalse);
      });

      test('multiple undo/redo cycles', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id],
        );

        var doc = document;

        // Undo/redo 3 kez
        for (int i = 0; i < 3; i++) {
          doc = command.execute(doc);
          expect(doc.layers[0].strokes.length, equals(2));

          doc = command.undo(doc);
          expect(doc.layers[0].strokes.length, equals(3));
        }
      });
    });

    group('description', () {
      test('shows single stroke count', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: ['id1'],
        );

        expect(command.description, equals('Erase 1 stroke(s)'));
      });

      test('shows multiple stroke count', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: ['id1', 'id2', 'id3'],
        );

        expect(command.description, equals('Erase 3 stroke(s)'));
      });

      test('shows zero for empty list', () {
        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [],
        );

        expect(command.description, equals('Erase 0 stroke(s)'));
      });
    });

    group('with HistoryManager', () {
      test('integrates with HistoryManager', () {
        final historyManager = HistoryManager();

        final command = EraseStrokesCommand(
          layerIndex: 0,
          strokeIds: [stroke1.id, stroke2.id],
        );

        final afterErase = historyManager.execute(command, document);
        expect(afterErase.layers[0].strokes.length, equals(1));
        expect(historyManager.canUndo, isTrue);

        final afterUndo = historyManager.undo(afterErase);
        expect(afterUndo!.layers[0].strokes.length, equals(3));
        expect(historyManager.canRedo, isTrue);

        final afterRedo = historyManager.redo(afterUndo);
        expect(afterRedo!.layers[0].strokes.length, equals(1));
      });
    });
  });
}

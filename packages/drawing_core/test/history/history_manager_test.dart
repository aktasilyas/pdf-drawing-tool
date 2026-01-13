import 'package:test/test.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';
import 'package:drawing_core/src/history/add_stroke_command.dart';
import 'package:drawing_core/src/history/history_manager.dart';
import 'package:drawing_core/src/history/remove_stroke_command.dart';

void main() {
  group('HistoryManager', () {
    late HistoryManager manager;
    late DrawingDocument document;

    Stroke createTestStroke(String id) {
      return Stroke(
        id: id,
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: StrokeStyle.pen(),
        createdAt: DateTime.now(),
      );
    }

    setUp(() {
      manager = HistoryManager();
      document = DrawingDocument.empty('Test Document');
    });

    group('Initial state', () {
      test('canUndo is false', () {
        expect(manager.canUndo, false);
      });

      test('canRedo is false', () {
        expect(manager.canRedo, false);
      });

      test('undoCount is 0', () {
        expect(manager.undoCount, 0);
      });

      test('redoCount is 0', () {
        expect(manager.redoCount, 0);
      });

      test('getUndoDescriptions returns empty list', () {
        expect(manager.getUndoDescriptions(), isEmpty);
      });

      test('getRedoDescriptions returns empty list', () {
        expect(manager.getRedoDescriptions(), isEmpty);
      });
    });

    group('execute', () {
      test('executes command and returns new document', () {
        final stroke = createTestStroke('stroke-1');
        final command = AddStrokeCommand(layerIndex: 0, stroke: stroke);

        final result = manager.execute(command, document);

        expect(result.strokeCount, 1);
        expect(document.strokeCount, 0); // original unchanged
      });

      test('sets canUndo to true', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        manager.execute(command, document);

        expect(manager.canUndo, true);
      });

      test('increments undoCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        expect(manager.undoCount, 0);
        manager.execute(command, document);
        expect(manager.undoCount, 1);
      });

      test('clears redo stack', () {
        final command1 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );
        final command2 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-2'),
        );

        // Execute and undo to populate redo stack
        var current = manager.execute(command1, document);
        manager.undo(current);
        expect(manager.canRedo, true);

        // New execute should clear redo stack
        manager.execute(command2, document);
        expect(manager.canRedo, false);
        expect(manager.redoCount, 0);
      });

      test('multiple executes increase undoCount', () {
        for (var i = 0; i < 5; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          document = manager.execute(command, document);
        }

        expect(manager.undoCount, 5);
      });
    });

    group('undo', () {
      test('returns null when nothing to undo', () {
        final result = manager.undo(document);
        expect(result, isNull);
      });

      test('undoes last command', () {
        final stroke = createTestStroke('stroke-1');
        final command = AddStrokeCommand(layerIndex: 0, stroke: stroke);

        var current = manager.execute(command, document);
        expect(current.strokeCount, 1);

        current = manager.undo(current)!;
        expect(current.strokeCount, 0);
      });

      test('sets canRedo to true', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        expect(manager.canRedo, false);

        manager.undo(current);
        expect(manager.canRedo, true);
      });

      test('decrements undoCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        expect(manager.undoCount, 1);

        manager.undo(current);
        expect(manager.undoCount, 0);
      });

      test('increments redoCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        expect(manager.redoCount, 0);

        manager.undo(current);
        expect(manager.redoCount, 1);
      });

      test('multiple undos work correctly', () {
        // Execute 3 commands
        var current = document;
        for (var i = 0; i < 3; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          current = manager.execute(command, current);
        }

        expect(current.strokeCount, 3);
        expect(manager.undoCount, 3);

        // Undo all 3
        current = manager.undo(current)!;
        expect(current.strokeCount, 2);

        current = manager.undo(current)!;
        expect(current.strokeCount, 1);

        current = manager.undo(current)!;
        expect(current.strokeCount, 0);

        expect(manager.undoCount, 0);
        expect(manager.redoCount, 3);
      });
    });

    group('redo', () {
      test('returns null when nothing to redo', () {
        final result = manager.redo(document);
        expect(result, isNull);
      });

      test('redoes last undone command', () {
        final stroke = createTestStroke('stroke-1');
        final command = AddStrokeCommand(layerIndex: 0, stroke: stroke);

        var current = manager.execute(command, document);
        current = manager.undo(current)!;
        expect(current.strokeCount, 0);

        current = manager.redo(current)!;
        expect(current.strokeCount, 1);
      });

      test('sets canUndo to true', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        current = manager.undo(current)!;
        expect(manager.canUndo, false);

        manager.redo(current);
        expect(manager.canUndo, true);
      });

      test('decrements redoCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        manager.undo(current);
        expect(manager.redoCount, 1);

        manager.redo(current);
        expect(manager.redoCount, 0);
      });

      test('increments undoCount', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        current = manager.undo(current)!;
        expect(manager.undoCount, 0);

        manager.redo(current);
        expect(manager.undoCount, 1);
      });

      test('multiple redos work correctly', () {
        // Execute 3 commands
        var current = document;
        for (var i = 0; i < 3; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          current = manager.execute(command, current);
        }

        // Undo all 3
        for (var i = 0; i < 3; i++) {
          current = manager.undo(current)!;
        }

        expect(current.strokeCount, 0);
        expect(manager.redoCount, 3);

        // Redo all 3
        current = manager.redo(current)!;
        expect(current.strokeCount, 1);

        current = manager.redo(current)!;
        expect(current.strokeCount, 2);

        current = manager.redo(current)!;
        expect(current.strokeCount, 3);

        expect(manager.undoCount, 3);
        expect(manager.redoCount, 0);
      });
    });

    group('Max history size', () {
      test('default maxHistorySize is 100', () {
        final manager = HistoryManager();
        expect(manager.maxHistorySize, 100);
      });

      test('custom maxHistorySize is respected', () {
        final manager = HistoryManager(maxHistorySize: 50);
        expect(manager.maxHistorySize, 50);
      });

      test('undoCount does not exceed maxHistorySize', () {
        final manager = HistoryManager(maxHistorySize: 5);
        var current = document;

        for (var i = 0; i < 10; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          current = manager.execute(command, current);
        }

        expect(manager.undoCount, 5);
      });

      test('oldest commands are removed when limit exceeded', () {
        final manager = HistoryManager(maxHistorySize: 3);
        var current = document;

        // Execute 5 commands (stroke-0 through stroke-4)
        for (var i = 0; i < 5; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          current = manager.execute(command, current);
        }

        // Should have last 3 commands
        expect(manager.undoCount, 3);
        final descriptions = manager.getUndoDescriptions();
        expect(descriptions.length, 3);

        // Undo all 3 - should undo stroke-4, stroke-3, stroke-2
        current = manager.undo(current)!;
        expect(current.strokeCount, 4); // stroke-4 removed

        current = manager.undo(current)!;
        expect(current.strokeCount, 3); // stroke-3 removed

        current = manager.undo(current)!;
        expect(current.strokeCount, 2); // stroke-2 removed

        // Cannot undo further (stroke-0, stroke-1 were removed from history)
        expect(manager.canUndo, false);
      });
    });

    group('clear', () {
      test('clears both stacks', () {
        final command = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );

        var current = manager.execute(command, document);
        manager.undo(current);

        expect(manager.undoCount, 0);
        expect(manager.redoCount, 1);

        manager.clear();

        expect(manager.undoCount, 0);
        expect(manager.redoCount, 0);
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
      });

      test('clear on empty manager has no effect', () {
        manager.clear();

        expect(manager.undoCount, 0);
        expect(manager.redoCount, 0);
      });
    });

    group('getUndoDescriptions', () {
      test('returns descriptions in order', () {
        var current = document;

        final command1 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );
        final command2 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-2'),
        );

        current = manager.execute(command1, current);
        current = manager.execute(command2, current);

        final descriptions = manager.getUndoDescriptions();

        expect(descriptions.length, 2);
        expect(descriptions[0], 'Add stroke to layer 0');
        expect(descriptions[1], 'Add stroke to layer 0');
      });

      test('returns empty list when no undo history', () {
        expect(manager.getUndoDescriptions(), isEmpty);
      });
    });

    group('getRedoDescriptions', () {
      test('returns descriptions in order', () {
        var current = document;

        final command1 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );
        final command2 = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-2'),
        );

        current = manager.execute(command1, current);
        current = manager.execute(command2, current);

        // Undo both
        current = manager.undo(current)!;
        current = manager.undo(current)!;

        final descriptions = manager.getRedoDescriptions();

        expect(descriptions.length, 2);
      });

      test('returns empty list when no redo history', () {
        expect(manager.getRedoDescriptions(), isEmpty);
      });
    });

    group('Integration tests', () {
      test('execute → undo → redo cycle', () {
        final stroke = createTestStroke('stroke-1');
        final command = AddStrokeCommand(layerIndex: 0, stroke: stroke);

        // Execute
        var current = manager.execute(command, document);
        expect(current.strokeCount, 1);
        expect(manager.canUndo, true);
        expect(manager.canRedo, false);

        // Undo
        current = manager.undo(current)!;
        expect(current.strokeCount, 0);
        expect(manager.canUndo, false);
        expect(manager.canRedo, true);

        // Redo
        current = manager.redo(current)!;
        expect(current.strokeCount, 1);
        expect(manager.canUndo, true);
        expect(manager.canRedo, false);
      });

      test('complex multi-step workflow', () {
        var current = document;

        // Add 3 strokes
        for (var i = 1; i <= 3; i++) {
          final command = AddStrokeCommand(
            layerIndex: 0,
            stroke: createTestStroke('stroke-$i'),
          );
          current = manager.execute(command, current);
        }
        expect(current.strokeCount, 3);

        // Undo 2
        current = manager.undo(current)!;
        current = manager.undo(current)!;
        expect(current.strokeCount, 1);

        // Add new stroke (clears redo)
        final newCommand = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('new-stroke'),
        );
        current = manager.execute(newCommand, current);
        expect(current.strokeCount, 2);
        expect(manager.canRedo, false);

        // Undo all
        current = manager.undo(current)!;
        current = manager.undo(current)!;
        expect(current.strokeCount, 0);
        expect(manager.canUndo, false);
      });

      test('mixed add and remove commands', () {
        var current = document;

        // Add stroke
        final addCommand = AddStrokeCommand(
          layerIndex: 0,
          stroke: createTestStroke('stroke-1'),
        );
        current = manager.execute(addCommand, current);
        expect(current.strokeCount, 1);

        // Remove stroke
        final removeCommand = RemoveStrokeCommand(
          layerIndex: 0,
          strokeId: 'stroke-1',
        );
        current = manager.execute(removeCommand, current);
        expect(current.strokeCount, 0);

        // Undo remove (stroke comes back)
        current = manager.undo(current)!;
        expect(current.strokeCount, 1);

        // Undo add (stroke gone)
        current = manager.undo(current)!;
        expect(current.strokeCount, 0);

        // Redo add
        current = manager.redo(current)!;
        expect(current.strokeCount, 1);

        // Redo remove
        current = manager.redo(current)!;
        expect(current.strokeCount, 0);
      });
    });
  });
}

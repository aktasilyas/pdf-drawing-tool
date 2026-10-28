// The selected sticky note is read from the document (#430): erasing inside
// it, undo/redo and minimize all work on the document's current note, and a
// page change deselects it.
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawingCanvasState state;
  late ProviderContainer container;
  var clock = Duration.zero;

  Future<void> pump(WidgetTester tester) async {
    clock = Duration.zero;
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  Offset toCanvas(Offset screenPoint) =>
      container.read(canvasTransformProvider).screenToCanvas(screenPoint);

  void gesture(List<Offset> points) {
    state.handlePointerDown(
      PointerDownEvent(position: points.first, timeStamp: clock),
    );
    for (final p in points.skip(1)) {
      clock += const Duration(milliseconds: 8);
      state.handlePointerMove(PointerMoveEvent(position: p, timeStamp: clock));
    }
    state.handlePointerUp(
      PointerUpEvent(position: points.last, timeStamp: clock),
    );
  }

  final line = [for (var x = 110.0; x <= 170; x += 4) Offset(x, 130)];

  core.StickyNote documentNote(String id) => container
      .read(activeLayerStickyNotesProvider)
      .firstWhere((n) => n.id == id);

  core.StickyNote? selected() => container.read(selectedStickyNoteProvider);

  /// Adds an open note under screen (100, 100), selects it and draws one
  /// stroke inside it with the pen.
  core.StickyNote addSelectedNoteWithInk() {
    final origin = toCanvas(const Offset(100, 100));
    final note = core.StickyNote.create(x: origin.dx, y: origin.dy);
    container.read(historyManagerProvider.notifier).execute(
          core.AddStickyNoteCommand(
            layerIndex: container.read(documentProvider).activeLayerIndex,
            stickyNote: note,
          ),
        );
    container.read(stickyNotePlacementProvider.notifier).selectNote(note);
    container
        .read(currentToolProvider.notifier)
        .selectTool(ToolType.ballpointPen);
    gesture(line);
    expect(documentNote(note.id).strokes, hasLength(1));
    return note;
  }

  void eraseLine() {
    container.read(eraserSettingsProvider.notifier).setMode(EraserMode.stroke);
    container
        .read(currentToolProvider.notifier)
        .selectTool(ToolType.strokeEraser);
    gesture(line);
  }

  testWidgets('erase inside a selected note → tap outside keeps the erase',
      (tester) async {
    await pump(tester);
    final note = addSelectedNoteWithInk();

    eraseLine();
    expect(documentNote(note.id).strokes, isEmpty);
    expect(selected()!.strokes, isEmpty, reason: 'drawn note is live');

    // Tap far outside the note with the pen → minimize and deselect.
    container
        .read(currentToolProvider.notifier)
        .selectTool(ToolType.ballpointPen);
    gesture(const [Offset(700, 500), Offset(704, 504)]);

    final saved = documentNote(note.id);
    expect(saved.minimized, isTrue);
    expect(saved.strokes, isEmpty);
    expect(selected(), isNull);
  });

  testWidgets('undo/redo while selected update the selected note at once',
      (tester) async {
    await pump(tester);
    final note = addSelectedNoteWithInk();
    eraseLine();
    expect(selected()!.strokes, isEmpty);

    final history = container.read(historyManagerProvider.notifier);
    history.undo();
    expect(selected()!.id, note.id);
    expect(selected()!.strokes, hasLength(1));

    history.redo();
    expect(selected()!.strokes, isEmpty);
  });

  testWidgets('color change starts from the document note', (tester) async {
    await pump(tester);
    final note = addSelectedNoteWithInk();
    eraseLine();

    // The context menu's color handler starts from selectedStickyNoteProvider,
    // which already reflects the erase.
    final current = selected()!;
    expect(current.strokes, isEmpty);
    container.read(historyManagerProvider.notifier).execute(
          core.UpdateStickyNoteCommand(
            layerIndex: container.read(documentProvider).activeLayerIndex,
            newNote: current.copyWith(color: 0xFFD1ECF1),
          ),
        );
    final saved = documentNote(note.id);
    expect(saved.color, 0xFFD1ECF1);
    expect(saved.strokes, isEmpty);
  });

  testWidgets('drag preview overrides the document note until cleared',
      (tester) async {
    await pump(tester);
    final note = addSelectedNoteWithInk();
    final notifier = container.read(stickyNotePlacementProvider.notifier);

    notifier.updateDragPreview(documentNote(note.id).copyWith(width: 300));
    expect(selected()!.width, 300);
    notifier.clearDragPreview();
    expect(selected()!.width, documentNote(note.id).width);
  });

  testWidgets('a page change deselects the note', (tester) async {
    await pump(tester);
    addSelectedNoteWithInk();
    expect(selected(), isNotNull);

    final pages = container.read(pageManagerProvider.notifier);
    pages.addPage();
    pages.goToPage(container.read(pageCountProvider) - 1);

    expect(container.read(stickyNotePlacementProvider).selectedNoteId, isNull);
    expect(selected(), isNull);
  });
}

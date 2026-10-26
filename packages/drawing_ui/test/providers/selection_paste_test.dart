import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_paste.dart';
import 'package:flutter_test/flutter_test.dart';

Shape _shape(String id) => Shape(
      id: id,
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 0, y: 0),
      endPoint: DrawingPoint(x: 10, y: 10),
      style: StrokeStyle.pen(),
    );

Stroke _stroke(String id) => Stroke(
      id: id,
      points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2026),
    );

void main() {
  final clipboard = SelectionClipboardData(
    strokes: [for (var i = 0; i < 20; i++) _stroke('s$i')],
    shapes: [for (var i = 0; i < 20; i++) _shape('r$i')],
    texts: [TextElement.create(text: 'a', x: 0, y: 0)],
    originalBounds: const BoundingBox(left: 0, top: 0, right: 10, bottom: 10),
  );

  test('pasting many elements is one undo step', () {
    final history = HistoryManager();
    var doc = DrawingDocument.emptyMultiPage('Test');
    final command = buildPasteCommand(clipboard, 0, 40, 40)!;

    doc = history.execute(command, doc);
    expect(history.undoCount, 1);
    expect(doc.layers[0].strokes, hasLength(20));
    expect(doc.layers[0].shapes, hasLength(20));
    expect(doc.layers[0].texts, hasLength(1));

    doc = history.undo(doc)!;
    expect(doc.layers[0].strokes, isEmpty);
    expect(doc.layers[0].shapes, isEmpty);
    expect(doc.layers[0].texts, isEmpty);
  });

  test('pasted elements get unique ids, distinct from the originals', () {
    final command = buildPasteCommand(clipboard, 0, 40, 40)!;
    final doc = command.execute(DrawingDocument.emptyMultiPage('Test'));
    final layer = doc.layers[0];
    final ids = [
      ...layer.strokes.map((s) => s.id),
      ...layer.shapes.map((s) => s.id),
      ...layer.texts.map((t) => t.id),
    ];
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.toSet().intersection({'s0', 'r0'}), isEmpty);
  });

  test('pasted elements are moved by the offset', () {
    final command = buildPasteCommand(clipboard, 0, 40, 25)!;
    final doc = command.execute(DrawingDocument.emptyMultiPage('Test'));
    final shape = doc.layers[0].shapes.first;
    expect(shape.startPoint.x, 40);
    expect(shape.startPoint.y, 25);
    expect(doc.layers[0].strokes.first.points.last.x, 50);
  });

  test('an empty clipboard builds no command', () {
    final empty = SelectionClipboardData(
      strokes: const [],
      shapes: const [],
      originalBounds: const BoundingBox(left: 0, top: 0, right: 1, bottom: 1),
    );
    expect(buildPasteCommand(empty, 0, 40, 40), isNull);
  });
}

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

import '../helpers/document_helpers.dart';

Layer layer(String id, {List<Stroke> strokes = const []}) =>
    Layer.empty(id).copyWith(id: id, strokes: strokes);

Stroke stroke(String id) => Stroke(
      id: id,
      points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
      style: StrokeStyle.pen(),
      createdAt: DateTime(2024),
    );

DrawingDocument v1(List<Layer> layers, {int active = 0}) => DrawingDocument(
      id: 'd',
      title: 't',
      layers: layers,
      activeLayerIndex: active,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

DrawingDocument v2(List<Layer> layers, {int active = 0}) =>
    multiPageDocWithLayers('t', layers).setActiveLayer(active);

List<String> ids(DrawingDocument d) => d.layers.map((l) => l.id).toList();

void main() {
  final builders = <String, DrawingDocument Function(List<Layer>, {int active})>{
    'V1': v1,
    'multi-page': v2,
  };

  for (final entry in builders.entries) {
    final build = entry.value;
    group('layer commands (${entry.key})', () {
      group('AddLayerCommand', () {
        test('appends on top, activates it; undo/redo restore exactly', () {
          final doc = build([layer('a'), layer('b')], active: 0);
          final cmd = AddLayerCommand(layer: layer('n'));

          final added = cmd.execute(doc);
          expect(ids(added), ['a', 'b', 'n']);
          expect(added.activeLayerIndex, 2);

          final undone = cmd.undo(added);
          expect(ids(undone), ['a', 'b']);
          expect(undone.activeLayerIndex, 0);

          final redone = cmd.execute(undone);
          expect(ids(redone), ['a', 'b', 'n']);
          expect(redone.activeLayerIndex, 2);
        });

        test('inserts at index and activates it', () {
          final doc = build([layer('a'), layer('b')], active: 1);
          final cmd = AddLayerCommand(
              layer: layer('n'), index: 1, description: 'Duplicate layer');

          final added = cmd.execute(doc);
          expect(ids(added), ['a', 'n', 'b']);
          expect(added.activeLayerIndex, 1);
          expect(cmd.description, 'Duplicate layer');

          final undone = cmd.undo(added);
          expect(ids(undone), ['a', 'b']);
          expect(undone.activeLayerIndex, 1);
        });
      });

      group('RemoveLayerCommand', () {
        test('undo restores layer content, order and active index', () {
          final doc = build([
            layer('a'),
            layer('b', strokes: [stroke('s1'), stroke('s2')]),
            layer('c'),
          ], active: 1);
          final cmd = RemoveLayerCommand(layerIndex: 1);

          final removed = cmd.execute(doc);
          expect(ids(removed), ['a', 'c']);
          expect(removed.activeLayerIndex, 1);

          final undone = cmd.undo(removed);
          expect(ids(undone), ['a', 'b', 'c']);
          expect(undone.activeLayerIndex, 1);
          expect(undone.layers[1].strokes.map((s) => s.id), ['s1', 's2']);

          final redone = cmd.execute(undone);
          expect(ids(redone), ['a', 'c']);
          expect(redone.activeLayerIndex, 1);
        });

        test('active index adjusts like DrawingDocument.removeLayer', () {
          for (var active = 0; active < 3; active++) {
            for (var index = 0; index < 3; index++) {
              final doc = build([layer('a'), layer('b'), layer('c')],
                  active: active);
              final result = RemoveLayerCommand(layerIndex: index).execute(doc);
              expect(result.activeLayerIndex,
                  doc.removeLayer(index).activeLayerIndex,
                  reason: 'active=$active index=$index');
            }
          }
        });

        test('last layer cannot be removed', () {
          final doc = build([layer('a')]);
          final cmd = RemoveLayerCommand(layerIndex: 0);
          expect(ids(cmd.execute(doc)), ['a']);
          expect(ids(cmd.undo(doc)), ['a']);
        });

        test('bad index is a no-op', () {
          final doc = build([layer('a'), layer('b')]);
          expect(ids(RemoveLayerCommand(layerIndex: 5).execute(doc)),
              ['a', 'b']);
          expect(ids(RemoveLayerCommand(layerIndex: -1).execute(doc)),
              ['a', 'b']);
        });
      });

      group('ReorderLayersCommand', () {
        test('moves with remove-then-insert; active follows its layer', () {
          final doc = build([layer('a'), layer('b'), layer('c')], active: 0);
          final cmd = ReorderLayersCommand(oldIndex: 0, newIndex: 2);

          final moved = cmd.execute(doc);
          expect(ids(moved), ['b', 'c', 'a']);
          expect(moved.activeLayerIndex, 2);

          final undone = cmd.undo(moved);
          expect(ids(undone), ['a', 'b', 'c']);
          expect(undone.activeLayerIndex, 0);

          final redone = cmd.execute(undone);
          expect(ids(redone), ['b', 'c', 'a']);
          expect(redone.activeLayerIndex, 2);
        });

        test('active layer other than the moved one keeps following its id',
            () {
          final doc = build([layer('a'), layer('b'), layer('c')], active: 1);
          final moved =
              ReorderLayersCommand(oldIndex: 2, newIndex: 0).execute(doc);
          expect(ids(moved), ['c', 'a', 'b']);
          expect(moved.activeLayerIndex, 2);
        });

        test('invalid or identical indexes are no-ops', () {
          final doc = build([layer('a'), layer('b')]);
          expect(
              ids(ReorderLayersCommand(oldIndex: 1, newIndex: 1)
                  .execute(doc)),
              ['a', 'b']);
          expect(
              ids(ReorderLayersCommand(oldIndex: 0, newIndex: 2)
                  .execute(doc)),
              ['a', 'b']);
        });
      });
    });
  }

  group('via HistoryManager', () {
    test('undo/redo after a page change restore layers and active index', () {
      final manager = HistoryManager();
      var doc = v2([layer('a'), layer('b', strokes: [stroke('s')]), layer('c')],
          active: 1);
      doc = doc.addPage(Page.create(index: 1));
      final pageId = doc.pages[0].id;

      doc = manager.execute(RemoveLayerCommand(layerIndex: 1), doc);
      expect(ids(doc), ['a', 'c']);

      doc = doc.setCurrentPage(1);
      doc = manager.undo(doc)!;
      expect(doc.pages[doc.currentPageIndex].id, pageId);
      expect(ids(doc), ['a', 'b', 'c']);
      expect(doc.activeLayerIndex, 1);
      expect(doc.layers[1].strokes, hasLength(1));

      doc = doc.setCurrentPage(1);
      doc = manager.redo(doc)!;
      expect(ids(doc), ['a', 'c']);
      expect(doc.activeLayerIndex, 1);
    });

    test('reorder redo after page change keeps the active layer', () {
      final manager = HistoryManager();
      var doc = v2([layer('a'), layer('b'), layer('c')], active: 0);
      doc = doc.addPage(Page.create(index: 1));

      doc = manager.execute(
          ReorderLayersCommand(oldIndex: 0, newIndex: 2), doc);
      doc = doc.setCurrentPage(1);
      doc = manager.undo(doc)!;
      expect(ids(doc), ['a', 'b', 'c']);
      expect(doc.activeLayerIndex, 0);

      doc = doc.setCurrentPage(1);
      doc = manager.redo(doc)!;
      expect(ids(doc), ['b', 'c', 'a']);
      expect(doc.activeLayerIndex, 2);
    });
  });
}

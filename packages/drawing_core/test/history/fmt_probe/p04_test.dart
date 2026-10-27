void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('undo restores layer content, order and active index', () {
          final strokes = [stroke('s1'), stroke('s2')];
          final start = [layer('a'), layer('b', strokes: strokes), layer('c')];
          final doc = build(start, active: 1);
          final cmd = RemoveLayerCommand(layerIndex: 1);

          final removed = cmd.execute(doc);
          expect(ids(removed), ['a', 'c']);
          expect(removed.activeLayerIndex, 1);

          final undone = cmd.undo(removed);
          expect(ids(undone), ['a', 'b', 'c']);
          expect(undone.activeLayerIndex, 1);
          final restored = undone.layers[1].strokes.map((s) => s.id);
          expect(restored, ['s1', 's2']);

          final redone = cmd.execute(undone);
          expect(ids(redone), ['a', 'c']);
          expect(redone.activeLayerIndex, 1);
        });
      });
    });
  }
}

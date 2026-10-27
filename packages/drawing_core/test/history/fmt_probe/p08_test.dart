void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
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
      });
    });
  }
}

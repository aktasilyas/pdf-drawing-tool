void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('appends on top and activates it; undo/redo restore', () {
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
      });
    });
  }
}

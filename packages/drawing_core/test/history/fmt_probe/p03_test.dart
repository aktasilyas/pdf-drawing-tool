void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('inserts at index and activates it', () {
          final doc = build([layer('a'), layer('b')], active: 1);
          final cmd = AddLayerCommand(
            layer: layer('n'),
            index: 1,
            description: 'Duplicate layer',
          );

          final added = cmd.execute(doc);
          expect(ids(added), ['a', 'n', 'b']);
          expect(added.activeLayerIndex, 1);
          expect(cmd.description, 'Duplicate layer');

          final undone = cmd.undo(added);
          expect(ids(undone), ['a', 'b']);
          expect(undone.activeLayerIndex, 1);
        });
      });
    });
  }
}

void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('last layer cannot be removed', () {
          final doc = build([layer('a')]);
          final cmd = RemoveLayerCommand(layerIndex: 0);
          expect(ids(cmd.execute(doc)), ['a']);
          expect(ids(cmd.undo(doc)), ['a']);
        });
      });
    });
  }
}

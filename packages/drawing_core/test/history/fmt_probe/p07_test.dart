void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('bad index is a no-op', () {
          final doc = build([layer('a'), layer('b')]);
          final above = RemoveLayerCommand(layerIndex: 5).execute(doc);
          final below = RemoveLayerCommand(layerIndex: -1).execute(doc);
          expect(ids(above), ['a', 'b']);
          expect(ids(below), ['a', 'b']);
        });
      });
    });
  }
}

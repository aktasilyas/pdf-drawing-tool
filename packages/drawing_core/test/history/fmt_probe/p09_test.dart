void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('an unmoved active layer keeps following its id', () {
          final doc = build([layer('a'), layer('b'), layer('c')], active: 1);
          final cmd = ReorderLayersCommand(oldIndex: 2, newIndex: 0);
          final moved = cmd.execute(doc);
          expect(ids(moved), ['c', 'a', 'b']);
          expect(moved.activeLayerIndex, 2);
        });
      });
    });
  }
}

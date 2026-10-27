void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('invalid or identical indexes are no-ops', () {
          final doc = build([layer('a'), layer('b')]);
          final same = ReorderLayersCommand(oldIndex: 1, newIndex: 1);
          final outOfRange = ReorderLayersCommand(oldIndex: 0, newIndex: 2);
          expect(ids(same.execute(doc)), ['a', 'b']);
          expect(ids(outOfRange.execute(doc)), ['a', 'b']);
        });
      });
    });
  }
}

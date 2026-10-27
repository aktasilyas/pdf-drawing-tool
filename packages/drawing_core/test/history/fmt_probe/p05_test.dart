void main() {
  for (final entry in builders.entries) {
    final build = entry.value;
    group('x', () {
      group('y', () {
        test('active index adjusts like DrawingDocument.removeLayer', () {
          final start = [layer('a'), layer('b'), layer('c')];
          for (var active = 0; active < 3; active++) {
            for (var index = 0; index < 3; index++) {
              final doc = build(start, active: active);
              final cmd = RemoveLayerCommand(layerIndex: index);
              final actual = cmd.execute(doc).activeLayerIndex;
              final expected = doc.removeLayer(index).activeLayerIndex;
              final reason = 'active=$active index=$index';
              expect(actual, expected, reason: reason);
            }
          }
        });
      });
    });
  }
}

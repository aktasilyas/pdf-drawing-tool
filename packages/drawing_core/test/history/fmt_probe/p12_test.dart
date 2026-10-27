void main() {
  group('via HistoryManager', () {
    test('reorder redo after a page change keeps the active layer', () {
      final manager = HistoryManager();
      var doc = v2([layer('a'), layer('b'), layer('c')], active: 0);
      doc = doc.addPage(Page.create(index: 1));

      final cmd = ReorderLayersCommand(oldIndex: 0, newIndex: 2);
      doc = manager.execute(cmd, doc);
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

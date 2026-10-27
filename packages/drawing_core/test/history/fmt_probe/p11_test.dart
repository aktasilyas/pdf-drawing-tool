void main() {
  group('via HistoryManager', () {
    test('undo/redo after a page change restore layers and active', () {
      final manager = HistoryManager();
      final start = [layer('a'), layer('b', strokes: [stroke('s')])];
      var doc = v2([...start, layer('c')], active: 1);
      doc = doc.addPage(Page.create(index: 1));
      final pageId = doc.pages[0].id;

      doc = manager.execute(RemoveLayerCommand(layerIndex: 1), doc);
      expect(ids(doc), ['a', 'c']);

      doc = doc.setCurrentPage(1);
      doc = manager.undo(doc)!;
      expect(doc.pages[doc.currentPageIndex].id, pageId);
      expect(ids(doc), ['a', 'b', 'c']);
      expect(doc.activeLayerIndex, 1);
      expect(doc.layers[1].strokes, hasLength(1));

      doc = doc.setCurrentPage(1);
      doc = manager.redo(doc)!;
      expect(ids(doc), ['a', 'c']);
      expect(doc.activeLayerIndex, 1);
    });
  });
}

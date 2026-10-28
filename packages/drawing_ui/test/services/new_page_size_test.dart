import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/new_page_size.dart';
import 'package:flutter_test/flutter_test.dart';

const _landscape = PageSize(width: 1448, height: 1024);
const _a5 = PageSize(width: 724, height: 1024);

Page _page(String id, PageSize size,
        {BackgroundType type = BackgroundType.blank, bool cover = false}) =>
    Page(
      id: id,
      index: 0,
      size: size,
      background: PageBackground(type: type),
      layers: [Layer.empty('L')],
      isCover: cover,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

DrawingDocument _doc(List<Page> pages, {DocumentSettings? settings}) =>
    DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: pages,
      settings: settings,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('resolveNewPageSize', () {
    test('uses settings.defaultPageSize when it is not the A4 fallback', () {
      final doc = _doc(
        [_page('p', _a5)],
        settings: DocumentSettings.defaults()
            .copyWith(defaultPageSize: _landscape),
      );
      expect(resolveNewPageSize(doc, 0), _landscape);
    });

    test('legacy A4 settings: takes the size of the current template page',
        () {
      final doc = _doc([_page('a', _landscape), _page('b', _a5)]);
      expect(resolveNewPageSize(doc, 0), _landscape);
      expect(resolveNewPageSize(doc, 1), _a5);
    });

    test('legacy A4 settings: current cover or PDF page → last template page',
        () {
      final doc = _doc([
        _page('c', _landscape, type: BackgroundType.cover, cover: true),
        _page('t', _a5, type: BackgroundType.grid),
        _page('pdf', const PageSize(width: 600, height: 400),
            type: BackgroundType.pdf),
      ]);
      expect(resolveNewPageSize(doc, 0), _a5);
      expect(resolveNewPageSize(doc, 2), _a5);
    });

    test('imported PDF notebook keeps the A4 default for new pages', () {
      final doc = _doc([
        _page('p1', const PageSize(width: 600, height: 400),
            type: BackgroundType.pdf),
        _page('p2', const PageSize(width: 612, height: 792),
            type: BackgroundType.pdf),
      ]);
      expect(resolveNewPageSize(doc, 0), PageSize.a4Portrait);
    });

    test('out-of-range current index falls back to the last template page',
        () {
      final doc = _doc([_page('a', _landscape)]);
      expect(resolveNewPageSize(doc, 5), _landscape);
      expect(resolveNewPageSize(doc, -1), _landscape);
    });
  });
}

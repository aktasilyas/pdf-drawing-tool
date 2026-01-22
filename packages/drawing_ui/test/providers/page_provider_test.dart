import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';

void main() {
  group('PageProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default page', () {
      final manager = container.read(pageManagerProvider);

      expect(manager.pageCount, 1);
      expect(manager.currentIndex, 0);
    });

    test('should add new page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();

      final manager = container.read(pageManagerProvider);
      expect(manager.pageCount, 2);
    });

    test('should delete page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.addPage();
      notifier.deletePage(1);

      final manager = container.read(pageManagerProvider);
      expect(manager.pageCount, 2);
    });

    test('should navigate to page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.goToPage(1);

      final manager = container.read(pageManagerProvider);
      expect(manager.currentIndex, 1);
    });

    test('should navigate to next page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.nextPage();

      final manager = container.read(pageManagerProvider);
      expect(manager.currentIndex, 1);
    });

    test('should navigate to previous page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.goToPage(1);
      notifier.previousPage();

      final manager = container.read(pageManagerProvider);
      expect(manager.currentIndex, 0);
    });

    test('should duplicate page', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.duplicatePage(0);

      final manager = container.read(pageManagerProvider);
      expect(manager.pageCount, 2);
    });

    test('should reorder pages', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.addPage();

      final page0IdBefore = container.read(pageManagerProvider).pages[0].id;
      notifier.reorderPage(0, 2);

      final manager = container.read(pageManagerProvider);
      expect(manager.pages[2].id, page0IdBefore);
    });

    test('should get current page', () {
      final currentPage = container.read(currentPageProvider);

      expect(currentPage, isNotNull);
      expect(currentPage.index, 0);
    });

    test('should get current page index', () {
      final currentIndex = container.read(currentPageIndexProvider);

      expect(currentIndex, 0);
    });

    test('should get page count', () {
      final pageCount = container.read(pageCountProvider);

      expect(pageCount, 1);
    });

    test('should check if can go next', () {
      final notifier = container.read(pageManagerProvider.notifier);

      expect(container.read(canGoNextProvider), false);

      notifier.addPage();

      expect(container.read(canGoNextProvider), true);
    });

    test('should check if can go previous', () {
      final notifier = container.read(pageManagerProvider.notifier);

      expect(container.read(canGoPreviousProvider), false);

      notifier.addPage();
      notifier.nextPage();

      expect(container.read(canGoPreviousProvider), true);
    });

    test('should notify listeners on page change', () {
      var notificationCount = 0;

      container.listen(
        pageManagerProvider,
        (previous, next) {
          notificationCount++;
        },
      );

      final notifier = container.read(pageManagerProvider.notifier);
      notifier.addPage();

      expect(notificationCount, 1);
    });

    test('should load pages from document', () {
      final doc = DrawingDocument.multiPage(
        id: 'd1',
        title: 'Test',
        pages: [
          Page.create(index: 0),
          Page.create(index: 1),
          Page.create(index: 2),
        ],
      );

      final notifier = container.read(pageManagerProvider.notifier);
      notifier.loadFromDocument(doc);

      final manager = container.read(pageManagerProvider);
      expect(manager.pageCount, 3);
      expect(manager.currentIndex, doc.currentPageIndex);
    });

    test('should export to document', () {
      final notifier = container.read(pageManagerProvider.notifier);

      notifier.addPage();
      notifier.addPage();

      final doc = notifier.toDocument(
        id: 'd1',
        title: 'Test Document',
      );

      expect(doc.pages.length, 3);
      expect(doc.title, 'Test Document');
    });

    test('should update page content', () {
      final notifier = container.read(pageManagerProvider.notifier);

      final stroke = Stroke(
        id: 's1',
        points: [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ],
        style: StrokeStyle.ballpoint(),
      );

      final updatedPage = container.read(currentPageProvider).addStroke(stroke);
      notifier.updatePage(0, updatedPage);

      final manager = container.read(pageManagerProvider);
      expect(manager.pages[0].layers.first.strokes.length, 1);
    });

    test('should dispose properly', () {
      final notifier = container.read(pageManagerProvider.notifier);

      expect(() => notifier.dispose(), returnsNormally);
    });
  });
}

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _blank = core.TemplateRegistry.blank;
final _grid = core.TemplateRegistry.basicTemplates
    .firstWhere((t) => t.name == 'Kareli');
final _dotted = core.TemplateRegistry.basicTemplates
    .firstWhere((t) => t.name == 'Noktalı');

const _oddSize = core.PageSize(width: 700, height: 900);
final _pdfBg = core.PageBackground(
  type: core.BackgroundType.pdf,
  pdfFilePath: '/docs/source.pdf',
  pdfPageIndex: 3,
);
final _coverBg = core.PageBackground(
  type: core.BackgroundType.cover,
  coverId: core.CoverRegistry.defaultCover.id,
  color: core.CoverRegistry.defaultCover.primaryColor,
);

/// Cover, then four pages: blank, blank, PDF (odd size), grid template.
/// Page index 1 (the first blank page) is current in the page manager; the
/// document's own index is stale (3), as it is after navigating in the app.
core.DrawingDocument _doc() {
  final pages = <core.Page>[
    core.Page.createCover(
      index: 0,
      size: core.PageSize.a4Portrait,
      background: _coverBg,
    ),
    core.Page.create(
        index: 1, background: core.PageBackground.fromTemplate(_blank)),
    core.Page.create(
        index: 2, background: core.PageBackground.fromTemplate(_blank)),
    core.Page.create(index: 3, size: _oddSize, background: _pdfBg),
    core.Page.create(
        index: 4, background: core.PageBackground.fromTemplate(_grid)),
  ];
  return core.DrawingDocument.emptyMultiPage('Test')
      .copyWith(pages: pages, currentPageIndex: 3);
}

Future<ProviderContainer> _pump(WidgetTester tester, int pageIndex) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1400);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final doc = _doc();
  container.read(documentProvider.notifier).updateDocument(doc);
  container
      .read(pageManagerProvider.notifier)
      .initializeFromDocument(doc.pages, currentIndex: 1);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: PageOptionsPanel(onClose: () {}, pageIndex: pageIndex),
        ),
      ),
    ),
  );
  return container;
}

Future<void> _openPicker(WidgetTester tester) async {
  final item = find.text('Şablonu değiştir');
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
  expect(find.byType(TemplatePicker), findsOneWidget);
}

Future<void> _selectTemplate(WidgetTester tester, String name) async {
  final card = find.widgetWithText(TemplateCard, name);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text('Uygula'));
  await tester.pumpAndSettle();
}

core.Page _page(ProviderContainer c, int index) =>
    c.read(documentProvider).pages[index];

void main() {
  testWidgets('template change from another page menu changes only that page',
      (tester) async {
    final container = await _pump(tester, 4);
    await _openPicker(tester);

    // The picker opens with page 4's template, not the current page's.
    final selected = tester
        .widgetList<TemplateCard>(find.byType(TemplateCard))
        .where((c) => c.isSelected)
        .map((c) => c.template.id);
    expect(selected, [_grid.id]);

    await _selectTemplate(tester, 'Noktalı');
    await _apply(tester);

    expect(_page(container, 4).background.templatePattern, _dotted.pattern);
    expect(_page(container, 1).background.templatePattern, _blank.pattern);
    expect(container.read(currentPageIndexProvider), 1);
    expect(container.read(currentPageProvider).background.templatePattern,
        _blank.pattern);
  });

  testWidgets('paper size change from another page menu resizes only that page',
      (tester) async {
    final container = await _pump(tester, 4);
    final before = _page(container, 1).size;
    await _openPicker(tester);

    // The panel below the dialog also shows 'Dikey' (scroll direction).
    final orientation = find.descendant(
        of: find.byType(TemplatePicker), matching: find.text('Dikey'));
    await tester.ensureVisible(orientation);
    await tester.tap(orientation);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yatay').last);
    await tester.pumpAndSettle();
    await _apply(tester);

    final target = _page(container, 4).size;
    expect(target.width, greaterThan(target.height));
    expect(_page(container, 1).size.width, before.width);
    expect(_page(container, 1).size.height, before.height);
    expect(_page(container, 4).background.templatePattern, _grid.pattern);
    expect(container.read(currentPageIndexProvider), 1);
  });

  testWidgets('undo restores the PDF page size and the cover size',
      (tester) async {
    final container = await _pump(tester, 3);
    final coverBefore = _page(container, 0).size;
    await _openPicker(tester);
    await _selectTemplate(tester, 'Noktalı');
    final orientation = find.descendant(
        of: find.byType(TemplatePicker), matching: find.text('Dikey'));
    await tester.ensureVisible(orientation);
    await tester.tap(orientation);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yatay').last);
    await tester.pumpAndSettle();
    await _apply(tester);

    final cover = _page(container, 0).size;
    expect(cover.width, greaterThan(cover.height));
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    final page = _page(container, 3);
    expect(page.background.type, core.BackgroundType.pdf);
    expect(page.size.width, _oddSize.width);
    expect(page.size.height, _oddSize.height);
    expect(_page(container, 0).size.width, coverBefore.width);
    expect(_page(container, 0).size.height, coverBefore.height);
    expect(container.read(currentPageIndexProvider), 1);
  });

  testWidgets('confirming the picker unchanged keeps a PDF page as is',
      (tester) async {
    final container = await _pump(tester, 3);
    await _openPicker(tester);
    await _apply(tester);

    final page = _page(container, 3);
    expect(page.background.type, core.BackgroundType.pdf);
    expect(page.background.pdfFilePath, '/docs/source.pdf');
    expect(page.background.pdfPageIndex, 3);
    expect(page.size.width, _oddSize.width);
    expect(page.size.height, _oddSize.height);
    expect(find.text('Sayfa arka planı değiştirildi'), findsNothing);
  });

  testWidgets('confirming the picker unchanged keeps the cover',
      (tester) async {
    final container = await _pump(tester, 0);
    await _openPicker(tester);
    await _apply(tester);

    final page = _page(container, 0);
    expect(page.background.type, core.BackgroundType.cover);
    expect(page.background.coverId, core.CoverRegistry.defaultCover.id);
  });

  testWidgets('a new template on a PDF page can be undone from the SnackBar',
      (tester) async {
    final container = await _pump(tester, 3);
    await _openPicker(tester);
    await _selectTemplate(tester, 'Noktalı');
    await _apply(tester);

    expect(_page(container, 3).background.templatePattern, _dotted.pattern);
    expect(find.text('Sayfa arka planı değiştirildi'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    final page = _page(container, 3);
    expect(page.background.type, core.BackgroundType.pdf);
    expect(page.background.pdfFilePath, '/docs/source.pdf');
    expect(page.background.pdfPageIndex, 3);
    expect(container.read(currentPageIndexProvider), 1);
  });

  testWidgets('a new template on the cover can be undone from the SnackBar',
      (tester) async {
    final container = await _pump(tester, 0);
    await _openPicker(tester);
    await _selectTemplate(tester, 'Noktalı');
    await _apply(tester);

    expect(_page(container, 0).background.templatePattern, _dotted.pattern);
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    final page = _page(container, 0);
    expect(page.background.type, core.BackgroundType.cover);
    expect(page.background.coverId, core.CoverRegistry.defaultCover.id);
  });
}

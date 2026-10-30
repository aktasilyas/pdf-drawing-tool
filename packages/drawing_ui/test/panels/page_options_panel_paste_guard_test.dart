import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

core.Page _page(String id, int index, {core.PageBackground? background}) =>
    core.Page(
      id: id,
      index: index,
      size: core.PageSize.a4Portrait,
      background: background ?? core.PageBackground.blank,
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  testWidgets('paste of a page whose files are gone shows a SnackBar only',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final doc = core.DrawingDocument.multiPage(
      id: 'd',
      title: 't',
      pages: [_page('p0', 0)],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    container.read(documentProvider.notifier).updateDocument(doc);
    container
        .read(pageManagerProvider.notifier)
        .initializeFromDocument(doc.pages, currentIndex: 0);
    final copied = _page(
      'src',
      0,
      background: const core.PageBackground(
        type: core.BackgroundType.pdf,
        pdfFilePath: 'pdfs/definitely_missing_475.pdf',
      ),
    );
    container.read(copiedPageProvider.notifier).state = copied;
    final visible = ValueNotifier(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (_, v, __) => v
                  ? PageOptionsPanel(
                      onClose: () => visible.value = false,
                      pageIndex: 0,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    final item = find.text('Sayfayı yapıştır');
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(container.read(documentProvider).pages, hasLength(1));
    expect(find.text('Yapıştırılamadı: kopyalanan dosyalar artık yok'),
        findsOneWidget);
    // Nothing is cleared.
    expect(container.read(copiedPageProvider), copied);
  });
}

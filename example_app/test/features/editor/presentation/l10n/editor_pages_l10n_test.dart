import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

const _sizes = [Size(390, 844), Size(1280, 800)];
const _locales = [Locale('en'), Locale('tr')];

Widget _scaled(BuildContext context, Widget? child) {
  final data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: const TextScaler.linear(1.3)),
    child: AppDrawingStringsScope(child: child!),
  );
}

core.Page _page(String id, int index) => core.Page(
      id: id,
      index: index,
      size: core.PageSize.a4Portrait,
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// A two-page document, as the editor holds it.
void _twoPages(ProviderContainer container) {
  final doc = core.DrawingDocument.multiPage(
    id: 'd',
    title: 't',
    pages: [_page('p0', 0), _page('p1', 1)],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  container.read(documentProvider.notifier).updateDocument(doc);
  container
      .read(pageManagerProvider.notifier)
      .initializeFromDocument(doc.pages, currentIndex: 0);
}

/// One widget under test: the string it must show and its Turkish default,
/// which must not leak into the English locale.
class _Case {
  const _Case(
    this.name,
    this.build,
    this.expected,
    this.turkish, {
    this.setUp,
    this.scrollable = true,
  });

  final String name;
  final Widget Function() build;
  final String Function(DrawingStrings s) expected;
  final String turkish;
  final void Function(ProviderContainer container)? setUp;
  final bool scrollable;
}

final _cases = <_Case>[
  _Case(
    'PageOptionsPanel',
    () => PageOptionsPanel(onClose: () {}, pageIndex: 1, onAddPage: () {}),
    (s) => s.pages.copyPage,
    'Sayfayı kopyala',
    setUp: _twoPages,
  ),
  _Case(
    'ExportPanel',
    () => ExportPanel(onClose: () {}, embedded: true),
    (s) => s.export.scopeCurrent,
    'Bu sayfa',
    setUp: (c) {
      _twoPages(c);
      c.read(isInfiniteCanvasProvider.notifier).state = false;
    },
  ),
  _Case(
    'TemplatePicker',
    () => const TemplatePicker(),
    (s) => s.templates.paperTab,
    'Kâğıt',
    scrollable: false,
  ),
  _Case(
    'FloatingExportProgress',
    () => const Stack(children: [FloatingExportProgress()]),
    (s) => s.errors.exportStorageFull,
    'Dışa aktarma için yeterli depolama alanı yok. '
        'Yer açıp tekrar deneyin.',
    setUp: (c) => c
        .read(exportProgressProvider.notifier)
        .setError(ExportFailure.storageFull),
    scrollable: false,
  ),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  Future<DrawingStrings> pump(
    WidgetTester tester,
    Locale locale,
    Size size,
    _Case c,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    c.setUp?.call(container);
    final body = c.build();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          builder: _scaled,
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: c.scrollable ? SingleChildScrollView(child: body) : body,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    return AppDrawingStrings(
      AppLocalizations.of(tester.element(find.byType(Scaffold).first)),
    );
  }

  for (final locale in _locales) {
    for (final size in _sizes) {
      for (final c in _cases) {
        final dims = '${size.width.toInt()}x${size.height.toInt()}';
        final tag = '${locale.languageCode} $dims ${c.name}';

        testWidgets('$tag: localized copy, no overflow', (t) async {
          final s = await pump(t, locale, size, c);
          expect(find.text(c.expected(s)), findsWidgets);
          if (locale.languageCode == 'en') {
            expect(find.text(c.turkish), findsNothing);
          }
          expectNoOverflow(t, tag);
        });
      }
    }
  }
}

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

const _phone = Size(390, 844);
const _locales = [Locale('en'), Locale('tr')];

Widget _scaled(BuildContext context, Widget? child) {
  final data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: const TextScaler.linear(1.3)),
    child: AppDrawingStringsScope(child: child!),
  );
}

/// One panel under test: the string it must show and its Turkish default,
/// which must not leak into the English locale.
class _Case {
  const _Case(
    this.name,
    this.panel,
    this.expected,
    this.turkish, {
    this.tool,
    this.hasClose = true,
  });

  final String name;
  final Widget panel;
  final String Function(DrawingStrings s) expected;
  final String turkish;
  final ToolType? tool;
  final bool hasClose;
}

final _cases = <_Case>[
  _Case(
    'PenSettingsPanel',
    const PenSettingsPanel(toolType: ToolType.ballpointPen),
    (s) => s.panels.thickness,
    'Kalınlık',
  ),
  _Case(
    'HighlighterSettingsPanel',
    const HighlighterSettingsPanel(),
    (s) => s.panels.glow,
    'Parlaklık',
    tool: ToolType.neonHighlighter,
  ),
  _Case(
    'EraserSettingsPanel',
    const EraserSettingsPanel(),
    (s) => s.panels.clearPage,
    'Sayfayı Temizle',
  ),
  _Case(
    'ShapesSettingsPanel',
    const ShapesSettingsPanel(),
    (s) => s.catalog.strokeColor,
    'Kontur Rengi',
  ),
  _Case(
    'LassoSelectionPanel',
    const LassoSelectionPanel(),
    (s) => s.selection.lassoSelectable,
    'Seçilebilir',
  ),
  _Case(
    'LaserPointerPanel',
    const LaserPointerPanel(),
    (s) => s.panels.laserDuration,
    'Süre',
  ),
  _Case(
    'TextSettingsPanel',
    const TextSettingsPanel(),
    (s) => s.panels.textHint,
    'Tuvale dokunarak metin kutusu ekleyin.',
  ),
  _Case(
    'StickyNotePanel',
    const StickyNotePanel(),
    (s) => s.panels.addNote,
    'Not Ekle',
  ),
  _Case(
    'StickerPanel',
    const StickerPanel(),
    (s) => s.catalog.stickerAnimals,
    'Hayvanlar',
    hasClose: false,
  ),
  _Case(
    'CompactColorPicker',
    CompactColorPicker(selectedColor: Colors.red, onColorSelected: (_) {}),
    (s) => s.panels.colorDone,
    'Bitti',
    hasClose: false,
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
    _Case c,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          builder: _scaled,
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: SingleChildScrollView(child: c.panel),
            ),
          ),
        ),
      ),
    );
    final tool = c.tool;
    if (tool != null) {
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(currentToolProvider.notifier)
          .selectTool(tool);
    }
    await tester.pump();
    return AppDrawingStrings(
      AppLocalizations.of(tester.element(find.byType(Scaffold).first)),
    );
  }

  for (final locale in _locales) {
    for (final c in _cases) {
      final tag = '${locale.languageCode} ${c.name}';

      testWidgets('$tag: localized copy, no overflow', (t) async {
        final s = await pump(t, locale, c);
        expect(find.text(c.expected(s)), findsWidgets);
        if (c.hasClose) {
          expect(find.byTooltip(s.panels.close), findsWidgets);
        }
        if (locale.languageCode == 'en') {
          expect(find.text(c.turkish), findsNothing);
          if (c.hasClose) expect(find.byTooltip('Kapat'), findsNothing);
        }
        expectNoOverflow(t, '${c.name} ${locale.languageCode}');
      });
    }
  }
}

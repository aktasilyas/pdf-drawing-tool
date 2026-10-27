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
const _tablet = Size(1280, 800);
const _locales = [Locale('en'), Locale('tr')];

Widget _scaled(BuildContext context, Widget? child) {
  final data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: const TextScaler.linear(1.3)),
    child: AppDrawingStringsScope(child: child!),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  Future<DrawingStrings> pump(
    WidgetTester tester,
    Locale locale,
    Size size, {
    required bool readerMode,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // v1.0 configuration: audio recording is frozen.
          audioRecordingEnabledProvider.overrideWithValue(false),
          readerModeProvider.overrideWith((ref) => readerMode),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          builder: _scaled,
          home: const Scaffold(
            body: DrawingThemeProvider(
              theme: DrawingTheme(),
              child: Align(
                alignment: Alignment.topCenter,
                child: AdaptiveToolbar(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return AppDrawingStrings(
      AppLocalizations.of(tester.element(find.byType(Scaffold).first)),
    );
  }

  const sizes = {'390x844': _phone, '1280x800': _tablet};

  for (final locale in _locales) {
    for (final entry in sizes.entries) {
      final tag = '${locale.languageCode} ${entry.key}';
      final wide = entry.value == _tablet;

      testWidgets('$tag: localized tooltips, no overflow', (t) async {
        final s = await pump(t, locale, entry.value, readerMode: false);
        expect(find.byTooltip(s.toolbar.home), findsWidgets);
        expect(find.byTooltip(s.toolbar.undo), findsWidgets);
        expect(find.byTooltip(s.toolbar.readerMode), findsWidgets);
        if (wide) {
          expect(
            find.byTooltip(ToolType.ballpointPen.label(s)),
            findsWidgets,
          );
        }
        if (locale.languageCode == 'en') {
          expect(find.byTooltip('Ana Sayfa'), findsNothing);
          expect(find.byTooltip('Geri al'), findsNothing);
        }
        expectNoOverflow(t, 'toolbar $tag');
      });

      testWidgets('$tag reader mode: localized tooltips, no overflow',
          (t) async {
        final s = await pump(t, locale, entry.value, readerMode: true);
        expect(find.byTooltip(s.toolbar.home), findsWidgets);
        expect(find.byTooltip(s.toolbar.editMode), findsWidgets);
        if (wide) {
          expect(find.text(s.toolbar.readOnly), findsWidgets);
        }
        if (locale.languageCode == 'en') {
          expect(find.byTooltip('Ana Sayfa'), findsNothing);
        }
        expectNoOverflow(t, 'reader toolbar $tag');
      });
    }
  }
}

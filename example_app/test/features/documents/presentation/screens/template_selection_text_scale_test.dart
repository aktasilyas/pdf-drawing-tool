import 'package:drawing_ui/drawing_ui.dart' show CoverTextureStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/screens/template_selection_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_card.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

const _phone = Size(390, 844);
const _locales = [Locale('tr'), Locale('en')];

/// Template screen at 1.3x text scale on a phone, in Turkish and English
/// (#332): the app bar, section header and both tabs must fit.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  Future<AppLocalizations> pump(WidgetTester tester, Locale locale) async {
    useTextScale(tester, 1.3);
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          home: const TemplateSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(TemplateSelectionScreen)),
    );
  }

  for (final locale in _locales) {
    final tag = locale.languageCode;

    testWidgets('$tag: paper tab', (t) async {
      final l10n = await pump(t, locale);
      expect(find.text(l10n.libraryCreateNoteTitle), findsOneWidget);
      expect(find.text(l10n.commonCancel), findsOneWidget);
      expect(find.text(l10n.commonCreate), findsOneWidget);
      expect(find.text(l10n.libraryTemplate), findsOneWidget);
      expectNoOverflow(t, 'template screen, paper tab');
    });

    testWidgets('$tag: cover tab', (t) async {
      final l10n = await pump(t, locale);
      await t.tap(find.byType(TemplatePreviewCard).first);
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryCover), findsWidgets);
      expectNoOverflow(t, 'template screen, cover tab');
    });
  }
}

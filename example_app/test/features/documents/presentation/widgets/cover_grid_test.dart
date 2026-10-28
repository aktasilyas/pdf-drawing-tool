import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';
import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

const _phone = Size(390, 844);

Widget _host(
  ValueChanged<Cover> onSelected, {
  ThemeData? theme,
  Locale locale = testLocale,
  double textScale = 1,
  Size size = const Size(1200, 1600),
}) {
  return localizedApp(
    theme: theme ?? AppTheme.light,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: AppDrawingStringsScope(child: child!),
    ),
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: CoverGridView(
          selectedCover: CoverRegistry.defaultCover,
          title: 'Biology',
          onCoverSelected: onSelected,
        ),
      ),
    ),
  );
}

String _coverName(Locale locale, Cover cover) =>
    AppDrawingStrings(lookupAppLocalizations(locale))
        .templates
        .coverName(cover);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  void setView(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('lists only the pickable family', (tester) async {
    setView(tester, const Size(1200, 1600));
    await tester.pumpWidget(_host((_) {}));
    for (final c in CoverRegistry.pickable) {
      expect(find.text(_coverName(testLocale, c)), findsOneWidget,
          reason: c.id);
    }
    expect(find.byType(CoverPreviewWidget), findsNWidgets(10));
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    final code = locale.languageCode;

    testWidgets('cover names are localized in $code', (tester) async {
      setView(tester, const Size(1200, 1600));
      await tester.pumpWidget(_host((_) {}, locale: locale));
      final sage = code == 'tr' ? 'Adaçayı Keten' : 'Sage Linen';
      expect(find.text(sage), findsOneWidget);
      final mustard = code == 'tr' ? 'Hardal Keçe' : 'Mustard Felt';
      expect(find.text(mustard), findsOneWidget);
    });

    testWidgets('no overflow on a phone at text scale 1.3 in $code',
        (tester) async {
      setView(tester, _phone);
      await tester.pumpWidget(_host(
        (_) {},
        locale: locale,
        textScale: 1.3,
        size: _phone,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final c in CoverRegistry.pickable) {
        expect(find.text(_coverName(locale, c)), findsOneWidget,
            reason: '${c.id} ($code)');
      }
    });
  }

  testWidgets('tapping felt_mustard reports that cover', (tester) async {
    setView(tester, const Size(1200, 1600));
    Cover? picked;
    await tester.pumpWidget(_host((c) => picked = c));
    await tester
        .tap(find.text(_coverName(testLocale, CoverFamily.feltMustard)));
    expect(picked?.id, 'felt_mustard');
  });

  testWidgets('item hit area is at least 48dp', (tester) async {
    setView(tester, const Size(1200, 1600));
    await tester.pumpWidget(_host((_) {}));
    final size = tester.getSize(find.byType(GestureDetector).first);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  test('label plate tokens mirror AppPalette.light', () {
    expect(CoverFamily.labelPlateColor, AppPalette.light.surface.toARGB32());
    expect(CoverFamily.labelInkColor, AppPalette.light.textPrimary.toARGB32());
  });
}

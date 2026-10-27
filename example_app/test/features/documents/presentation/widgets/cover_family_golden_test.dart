import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';

Widget _sheet(ThemeData theme, double width) {
  const gap = 16.0;
  final height = width * 4 / 3;
  return localizedApp(
    theme: theme,
    debugShowCheckedModeBanner: false,
    home: Builder(builder: (context) {
      return Scaffold(
        backgroundColor: context.palette.background,
        body: Padding(
          padding: const EdgeInsets.all(gap),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final c in CoverRegistry.pickable)
                SizedBox(
                  width: width,
                  height: height,
                  child: CoverPreviewWidget(
                    cover: c,
                    title: 'Biology',
                    showBorder: false,
                  ),
                ),
            ],
          ),
        ),
      );
    }),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  for (final cover in [CoverFamily.leatherOxblood, CoverFamily.linenSage]) {
    testWidgets('cover close-up 480dp ${cover.id}', (tester) async {
      tester.view.physicalSize = const Size(512, 704);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.palette.background,
            body: Center(
              child: SizedBox(
                width: 480,
                height: 640,
                child: CoverPreviewWidget(
                    cover: cover, title: 'Biology', showBorder: false),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/cover_closeup_480_${cover.id}.png'));
    });
  }

  for (final width in [120, 240]) {
    for (final mode in ['light', 'dark']) {
      testWidgets('cover family ${width}dp $mode', (tester) async {
        const gap = 16.0;
        final w = width.toDouble();
        tester.view.physicalSize =
            Size(5 * w + 6 * gap, 2 * (w * 4 / 3) + 3 * gap);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
            _sheet(mode == 'light' ? AppTheme.light : AppTheme.dark, w));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/cover_family_${width}_$mode.png'));
      });
    }
  }
}

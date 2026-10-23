import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';

Widget _sheet(ThemeData theme) {
  return MaterialApp(
    theme: theme,
    debugShowCheckedModeBanner: false,
    home: Builder(builder: (context) {
      final p = context.palette;
      final roles = <String, Color>{
        'background': p.background,
        'surface': p.surface,
        'surfaceElevated': p.surfaceElevated,
        'border': p.border,
        'textPrimary': p.textPrimary,
        'textMuted': p.textMuted,
        'accent': p.accent,
        'accentContainer': p.accentContainer,
        'danger': p.danger,
        'paper': p.paper,
      };
      return Scaffold(
        backgroundColor: p.background,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elyanotes',
                  style: Theme.of(context).textTheme.headlineLarge),
              Text('Notebook title in serif',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('UI label in Inter',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final e in roles.entries)
                      Container(
                        width: 120,
                        height: 64,
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: e.value,
                          border: Border.all(color: p.border),
                        ),
                        child: Text(e.key,
                            style: TextStyle(
                                fontFamily: AppTypography.bodyFontFamily,
                                fontSize: 11,
                                color: ThemeData.estimateBrightnessForColor(
                                            e.value) ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF000000))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('SourceSerif4', [
      'SourceSerif4-Regular.otf',
      'SourceSerif4-Semibold.otf',
      'SourceSerif4-Bold.otf',
    ]);
    await _loadFont('Inter', [
      'Inter-Regular.ttf',
      'Inter-Medium.ttf',
      'Inter-SemiBold.ttf',
    ]);
  });

  group('AppPalette', () {
    test('brief values', () {
      expect(AppPalette.light.accent, const Color(0xFF2B4C7E));
      expect(AppPalette.dark.background, const Color(0xFF1B1A18));
      expect(AppPalette.dark.paper, const Color(0xFFF3EFE6));
    });

    test('lerp endpoints', () {
      expect(AppPalette.light.lerp(AppPalette.dark, 1).surface,
          AppPalette.dark.surface);
      expect(AppPalette.light.lerp(AppPalette.dark, 0).surface,
          AppPalette.light.surface);
    });

    testWidgets('registered on both themes', (tester) async {
      await tester.pumpWidget(_sheet(AppTheme.light));
      expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
      expect(AppTheme.dark.extension<AppPalette>(), AppPalette.dark);
    });

    test('bundled fonts, not google_fonts', () {
      expect(AppTypography.headingFontFamily, 'SourceSerif4');
      expect(AppTypography.titleLarge.fontFamily, 'SourceSerif4');
      expect(AppTypography.bodyMedium.fontFamily, 'Inter');
    });
  });

  group('token sheet goldens', () {
    for (final mode in ['light', 'dark']) {
      testWidgets(mode, (tester) async {
        tester.view.physicalSize = const Size(720, 420);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
            _sheet(mode == 'light' ? AppTheme.light : AppTheme.dark));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/token_sheet_$mode.png'));
      });
    }
  });
}

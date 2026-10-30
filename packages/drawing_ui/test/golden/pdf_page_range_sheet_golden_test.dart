import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/chrome_theme.dart';

const _tabletWidth = 420.0;
const _phoneWidth = 390.0;

/// The sheet body as shown inside the modal bottom sheet.
Widget _scenario(
  Brightness brightness,
  double width, {
  bool choosing = false,
  int? start,
  int? end,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: chromeTheme(brightness),
    home: Builder(
      builder: (context) => SizedBox(
        width: width,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Material(
            type: MaterialType.transparency,
            child: PdfPageRangeSheet(
              pageCount: 640,
              maxPages: 500,
              initiallyChoosing: choosing,
              initialStart: start,
              initialEnd: end,
            ),
          ),
        ),
      ),
    ),
  );
}

// Only the CI variant has committed baselines; platform goldens stay off.
Future<void> main() => AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: _tests,
    );

Future<void> _tests() async {
  for (final brightness in Brightness.values) {
    final name = brightness.name;
    goldenTest(
      'pdf page range sheet $name',
      fileName: 'pdf_page_range_sheet_$name',
      builder: () => GoldenTestGroup(
        columns: 1,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: _scenario(brightness, _tabletWidth),
          ),
          GoldenTestScenario(
            name: 'range valid',
            child: _scenario(brightness, _tabletWidth,
                choosing: true, start: 141, end: 640),
          ),
        ],
      ),
    );
    goldenTest(
      'pdf page range sheet ${name}_range_invalid',
      fileName: 'pdf_page_range_sheet_${name}_range_invalid',
      builder: () => GoldenTestGroup(
        columns: 1,
        children: [
          GoldenTestScenario(
            name: 'start after end',
            child: _scenario(brightness, _tabletWidth,
                choosing: true, start: 10, end: 5),
          ),
          GoldenTestScenario(
            name: 'too long',
            child: _scenario(brightness, _tabletWidth,
                choosing: true, start: 1, end: 600),
          ),
        ],
      ),
    );
  }
  goldenTest(
    'pdf page range sheet phone_light',
    fileName: 'pdf_page_range_sheet_phone_light',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'default',
          child: _scenario(Brightness.light, _phoneWidth),
        ),
        GoldenTestScenario(
          name: 'range invalid',
          child: _scenario(Brightness.light, _phoneWidth,
              choosing: true, start: 1, end: 641),
        ),
      ],
    ),
  );
}

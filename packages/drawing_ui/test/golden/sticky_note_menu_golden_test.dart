import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/chrome_theme.dart';

Widget _onDesk(Brightness brightness, Widget child) {
  return Theme(
    data: chromeTheme(brightness),
    child: Builder(
      builder: (context) => ColoredBox(
        color: ChromePalette.of(context).background,
        child: Padding(
          padding: const EdgeInsets.all(ChromeSpacing.lg),
          child: child,
        ),
      ),
    ),
  );
}

Widget _card(StickyNoteColor selected) => StickyNoteMenuCard(
      selectedColor: selected.argb,
      onColorChange: (_) {},
      onDelete: () {},
    );

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
      'sticky note menu $name',
      fileName: 'sticky_note_menu_$name',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'yellow selected',
            child: _onDesk(brightness, _card(StickyNoteColor.yellow)),
          ),
          GoldenTestScenario(
            name: 'purple selected',
            child: _onDesk(brightness, _card(StickyNoteColor.purple)),
          ),
        ],
      ),
    );
  }
}

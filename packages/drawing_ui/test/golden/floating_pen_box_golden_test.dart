import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/chrome_theme.dart';

const _presets = [
  PenPreset(id: 'ballpoint', color: Color(0xFF1E1E1E)),
  PenPreset(
    id: 'highlighter',
    toolType: ToolType.highlighter,
    color: Color(0xFFFFD54F),
    thickness: 12,
  ),
  PenPreset(
    id: 'fountain',
    toolType: ToolType.fountainPen,
    color: Color(0xFF1565C0),
  ),
];

Widget _scenario(Brightness brightness, {required Offset position}) {
  final container = ProviderContainer(
    overrides: [
      penBoxPresetsProvider
          .overrideWith((ref) => PenBoxPresetsNotifier(_presets)),
    ],
  );
  container.read(selectedPresetIndexProvider.notifier).state = 1;
  return UncontrolledProviderScope(
    container: container,
    child: Theme(
      data: chromeTheme(brightness),
      child: Builder(
        builder: (context) => ColoredBox(
          color: ChromePalette.of(context).background,
          child: Padding(
            padding: const EdgeInsets.all(ChromeSpacing.sm),
            child: FloatingPenBox(position: position),
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
      'floating pen box $name',
      fileName: 'floating_pen_box_$name',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'vertical (left edge)',
            child: _scenario(brightness, position: const Offset(12, 12)),
          ),
          GoldenTestScenario(
            name: 'horizontal (top)',
            child: _scenario(brightness, position: const Offset(200, 12)),
          ),
        ],
      ),
    );
  }
}

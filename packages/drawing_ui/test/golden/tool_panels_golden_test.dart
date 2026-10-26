import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/chrome_theme.dart';

/// The seven tool panels migrated to the pen-panel layout (#146), each with
/// the tool that opens it.
const _panels = <String, (ToolType, Widget)>{
  'highlighter': (ToolType.highlighter, HighlighterSettingsPanel()),
  'eraser': (ToolType.pixelEraser, EraserSettingsPanel()),
  'shapes': (ToolType.shapes, ShapesSettingsPanel()),
  'text': (ToolType.text, TextSettingsPanel()),
  'laser': (ToolType.laserPointer, LaserPointerPanel()),
  'lasso': (ToolType.selection, LassoSelectionPanel()),
  'sticky_note': (ToolType.stickyNote, StickyNotePanel()),
};

Widget _scenario({
  required Brightness brightness,
  required SharedPreferences prefs,
  required ToolType tool,
  required Widget panel,
}) {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  container.read(currentToolProvider.notifier).selectTool(tool);
  return UncontrolledProviderScope(
    container: container,
    child: Theme(
      data: chromeTheme(brightness),
      child: Builder(
        builder: (context) => Material(
          color: ChromePalette.of(context).surfaceElevated,
          child: SizedBox(width: 380, child: panel),
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
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  // Settings persist in prefs; start each scenario from defaults.
  setUp(() => prefs.clear());

  _panels.forEach((name, entry) {
    final (tool, panel) = entry;
    for (final brightness in Brightness.values) {
      goldenTest(
        'tool panel $name ${brightness.name}',
        fileName: 'tool_panel_${name}_${brightness.name}',
        builder: () => GoldenTestScenario(
          name: '$name ${brightness.name}',
          child: _scenario(
            brightness: brightness,
            prefs: prefs,
            tool: tool,
            panel: panel,
          ),
        ),
      );
    }
  });
}

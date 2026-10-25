import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/chrome_theme.dart';

const _inkRed = Color(0xFFD32F2F);

Widget _onBand(Brightness brightness, Widget child) {
  return Theme(
    data: chromeTheme(brightness),
    child: Builder(
      builder: (context) => ColoredBox(
        color: ChromePalette.of(context).background,
        child: Padding(
          padding: const EdgeInsets.all(ChromeSpacing.sm),
          child: child,
        ),
      ),
    ),
  );
}

Widget _button({
  bool selected = false,
  bool enabled = true,
  Color? inkDotColor,
}) {
  return ChromeIconButton(
    icon: ElyanotesIcons.iconForTool(ToolType.ballpointPen),
    selectedIcon: ElyanotesIcons.iconForTool(
      ToolType.ballpointPen,
      active: true,
    ),
    tooltip: 'Pen',
    onPressed: () {},
    selected: selected,
    enabled: enabled,
    inkDotColor: inkDotColor,
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
      'chrome icon button states $name',
      fileName: 'chrome_icon_button_states_$name',
      builder: () => GoldenTestGroup(
        columns: 4,
        children: [
          GoldenTestScenario(
            name: 'idle',
            child: _onBand(brightness, _button()),
          ),
          GoldenTestScenario(
            name: 'selected',
            child: _onBand(brightness, _button(selected: true)),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: _onBand(brightness, _button(enabled: false)),
          ),
          GoldenTestScenario(
            name: 'pen dot',
            child: _onBand(
              brightness,
              _button(selected: true, inkDotColor: _inkRed),
            ),
          ),
        ],
      ),
    );
  }
}

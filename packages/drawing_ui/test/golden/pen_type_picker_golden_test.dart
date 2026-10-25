import 'package:alchemist/alchemist.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _penTools = [
  ToolType.fountainPen,
  ToolType.ballpointPen,
  ToolType.brushPen,
  ToolType.pencil,
];
const _colors = [
  Color(0xFFD32F2F),
  Color(0xFF1976D2),
  Color(0xFF388E3C),
  Color(0xFF7B1FA2),
];

Widget _scenario({
  required Brightness brightness,
  required double width,
  required SharedPreferences prefs,
  ToolType tool = ToolType.ballpointPen,
  double textScale = 1,
  void Function(ProviderContainer)? setup,
}) {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  container.read(currentToolProvider.notifier).selectTool(tool);
  setup?.call(container);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: brightness,
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 400),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(width: width, child: const PenTypePicker()),
          ),
        ),
      ),
    ),
  );
}

void _extremes(ProviderContainer c, {required bool max}) {
  for (final (i, t) in _penTools.indexed) {
    final cfg = t.penType!.config;
    c.read(penSettingsProvider(t).notifier)
      ..setThickness(max ? cfg.maxThickness : cfg.minThickness)
      ..setColor(max ? _colors[i] : const Color(0xFF212121));
  }
  final cfg = PenType.highlighter.config;
  c.read(highlighterSettingsProvider.notifier)
    ..setThickness(max ? cfg.maxThickness : cfg.minThickness)
    ..setColor(max ? const Color(0xFFFFEB3B) : const Color(0xFF80DEEA));
}

void main() {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  // Settings persist in prefs; start each scenario from defaults.
  setUp(() => prefs.clear());

  const lightHl = ToolType.highlighter;
  final scenarios = <String, Widget Function()>{
    'tablet_light': () =>
        _scenario(brightness: Brightness.light, width: 376, prefs: prefs),
    'tablet_dark': () =>
        _scenario(brightness: Brightness.dark, width: 376, prefs: prefs),
    'phone_light': () =>
        _scenario(brightness: Brightness.light, width: 390, prefs: prefs),
    'phone_dark': () =>
        _scenario(brightness: Brightness.dark, width: 390, prefs: prefs),
    'tablet_light_highlighter': () => _scenario(
        brightness: Brightness.light, width: 376, prefs: prefs, tool: lightHl),
    'tablet_light_max': () => _scenario(
        brightness: Brightness.light,
        width: 376,
        prefs: prefs,
        setup: (c) => _extremes(c, max: true)),
    'tablet_dark_min': () => _scenario(
        brightness: Brightness.dark,
        width: 376,
        prefs: prefs,
        setup: (c) => _extremes(c, max: false)),
    'phone_light_text130': () => _scenario(
        brightness: Brightness.light,
        width: 390,
        prefs: prefs,
        tool: ToolType.fountainPen,
        textScale: 1.3),
  };

  scenarios.forEach((name, build) {
    goldenTest(
      'pen type picker $name',
      fileName: 'pen_type_picker_$name',
      constraints: BoxConstraints.tightFor(
        width: name.startsWith('phone') ? 390 : 376,
        height: name.contains('text130') ? 220 : 200,
      ),
      builder: () => GoldenTestScenario(
        name: name,
        child: build(),
      ),
    );
  });
}

import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFD32F2F);

const _presets = [
  PenPreset(id: 'ballpoint'),
  PenPreset(id: 'empty', isEmpty: true),
  PenPreset(
    id: 'fountain',
    toolType: ToolType.fountainPen,
    color: _red,
    thickness: 4.5,
    nibShape: NibShapeType.ellipse,
  ),
];

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      penBoxPresetsProvider
          .overrideWith((ref) => PenBoxPresetsNotifier(_presets)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('penBoxEditorPanelFor', () {
    test('both highlighter kinds open the highlighter panel', () {
      expect(penBoxEditorPanelFor(ToolType.highlighter), ToolType.highlighter);
      expect(
        penBoxEditorPanelFor(ToolType.neonHighlighter),
        ToolType.highlighter,
      );
    });

    test('pens open their own panel', () {
      expect(penBoxEditorPanelFor(ToolType.pencil), ToolType.pencil);
      expect(penBoxEditorPanelFor(ToolType.fountainPen), ToolType.fountainPen);
    });
  });

  group('penBoxOpensHorizontally', () {
    bool opens(double x, double y) => penBoxOpensHorizontally(
          position: Offset(x, y),
          screenWidth: 800,
        );

    test('opens as a row near the top, away from the edges', () {
      expect(opens(200, 12), isTrue);
      expect(opens(80, 199), isTrue);
      expect(opens(650, 0), isTrue);
    });

    test('opens as a column near either side edge', () {
      expect(opens(79, 12), isFalse);
      expect(opens(651, 12), isFalse);
    });

    test('opens as a column below the top band', () {
      expect(opens(200, 200), isFalse);
    });
  });

  group('PenBoxActions', () {
    test('selectPreset activates the preset tool and style', () {
      final container = _container();
      container.read(activePanelProvider.notifier).state = ToolType.pencil;

      container.read(penBoxActionsProvider).selectPreset(2);

      expect(container.read(selectedPresetIndexProvider), 2);
      expect(container.read(currentToolProvider), ToolType.fountainPen);
      final settings =
          container.read(penSettingsProvider(ToolType.fountainPen));
      expect(settings.color, _red);
      expect(settings.thickness, 4.5);
      expect(settings.nibShape, NibShapeType.ellipse);
      expect(container.read(activePanelProvider), isNull);
    });

    test('selectPreset ignores empty and out-of-range slots', () {
      final container = _container();
      final actions = container.read(penBoxActionsProvider);

      actions.selectPreset(1);
      actions.selectPreset(-1);
      actions.selectPreset(3);

      expect(container.read(selectedPresetIndexProvider), 0);
    });

    test('openEditor opens the panel for the preset tool', () {
      final container = _container();
      final actions = container.read(penBoxActionsProvider);

      actions.openEditor(_presets[2]);
      expect(container.read(activePanelProvider), ToolType.fountainPen);

      actions.openEditor(
        const PenPreset(id: 'neon', toolType: ToolType.neonHighlighter),
      );
      expect(container.read(activePanelProvider), ToolType.highlighter);
    });

    test('deletePreset removes the preset at the index', () {
      final container = _container();

      container.read(penBoxActionsProvider).deletePreset(0);

      expect(
        container.read(penBoxPresetsProvider).map((p) => p.id),
        ['empty', 'fountain'],
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('Current Tool Provider', () {
    test('default tool is ballpoint pen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tool = container.read(currentToolProvider);
      expect(tool, ToolType.ballpointPen);
    });

    test('can change current tool', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentToolProvider.notifier).state = ToolType.highlighter;
      expect(container.read(currentToolProvider), ToolType.highlighter);
    });
  });

  group('Active Panel Provider', () {
    test('no panel is open by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final activePanel = container.read(activePanelProvider);
      expect(activePanel, isNull);
    });

    test('can open a panel', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activePanelProvider.notifier).state = ToolType.brushPen;
      expect(container.read(activePanelProvider), ToolType.brushPen);
    });

    test('can close panel by setting to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activePanelProvider.notifier).state = ToolType.brushPen;
      container.read(activePanelProvider.notifier).state = null;
      expect(container.read(activePanelProvider), isNull);
    });
  });

  group('Pen Settings Provider', () {
    test('has default settings for ballpoint pen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings =
          container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.color, const Color(0xFF000000));
      expect(settings.thickness, 1.5); // Updated from 2.0 to 1.5
      expect(settings.nibShape, NibShapeType.circle);
    });

    test('can update color', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setColor(Colors.blue);

      final settings =
          container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.color, Colors.blue);
    });

    test('can update thickness', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setThickness(5.0);

      final settings =
          container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.thickness, 5.0);
    });

    test('gel pen has circle nib by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(penSettingsProvider(ToolType.gelPen));
      expect(settings.nibShape, NibShapeType.circle);
      expect(settings.thickness, 2.0);
    });
  });

  group('Highlighter Settings Provider', () {
    test('has semi-transparent yellow by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(highlighterSettingsProvider);
      expect((settings.color.a * 255.0).round().clamp(0, 255), 0x80);
      expect(settings.thickness, 20.0);
      expect(settings.straightLineMode, false);
    });

    test('can toggle straight line mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(highlighterSettingsProvider.notifier)
          .setStraightLineMode(true);

      final settings = container.read(highlighterSettingsProvider);
      expect(settings.straightLineMode, true);
    });
  });

  group('Eraser Settings Provider', () {
    test('stroke mode is default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(eraserSettingsProvider);
      expect(settings.mode, EraserMode.stroke);
    });

    test('can change eraser mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(eraserSettingsProvider.notifier)
          .setMode(EraserMode.stroke);

      final settings = container.read(eraserSettingsProvider);
      expect(settings.mode, EraserMode.stroke);
    });

    test('can toggle options', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(eraserSettingsProvider.notifier)
          .setEraseOnlyHighlighter(true);

      final settings = container.read(eraserSettingsProvider);
      expect(settings.eraseOnlyHighlighter, true);
    });
  });

  group('Pen Box Presets Provider', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final presets = container.read(penBoxPresetsProvider);
      expect(presets.length, 0);
    });

    test('can add preset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newPreset = PenPreset(
        id: 'new_preset',
        toolType: ToolType.brushPen,
        color: Colors.red,
        thickness: 10.0,
        nibShape: NibShapeType.ellipse,
      );

      container.read(penBoxPresetsProvider.notifier).addPreset(newPreset);

      final presets = container.read(penBoxPresetsProvider);
      // Should find the new preset in one of the empty slots
      final addedPreset = presets.firstWhere((p) => p.id == 'new_preset');
      expect(addedPreset.color, Colors.red);
    });

    test('can remove preset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First add a preset
      final newPreset = PenPreset(
        id: 'test_preset',
        toolType: ToolType.ballpointPen,
        color: Colors.red,
        thickness: 2.0,
        nibShape: NibShapeType.circle,
      );
      container.read(penBoxPresetsProvider.notifier).addPreset(newPreset);
      expect(container.read(penBoxPresetsProvider).length, 1);

      // Then remove it
      container.read(penBoxPresetsProvider.notifier).removePreset(0);
      expect(container.read(penBoxPresetsProvider).length, 0);
    });
  });

  group('Selected Preset Index Provider', () {
    test('first preset is selected by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final index = container.read(selectedPresetIndexProvider);
      expect(index, 0);
    });

    test('can change selected preset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedPresetIndexProvider.notifier).state = 3;
      expect(container.read(selectedPresetIndexProvider), 3);
    });
  });

  group('Shapes Settings Provider', () {
    test('rectangle is selected by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(shapesSettingsProvider);
      expect(settings.selectedShape, ShapeType.rectangle);
      expect(settings.fillEnabled, false);
    });

    test('can change selected shape', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(shapesSettingsProvider.notifier)
          .setSelectedShape(ShapeType.star);

      final settings = container.read(shapesSettingsProvider);
      expect(settings.selectedShape, ShapeType.star);
    });

    test('can enable fill', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shapesSettingsProvider.notifier).setFillEnabled(true);

      final settings = container.read(shapesSettingsProvider);
      expect(settings.fillEnabled, true);
    });
  });

  group('Toolbar Config Provider', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    }

    test('has default tools', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final config = container.read(toolbarConfigProvider);
      expect(config.tools, isNotEmpty);
      expect(config.visibleTools, isNotEmpty);
    });

    test('can reorder tools', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final originalOrder = container.read(toolbarConfigProvider).sortedTools;
      final originalFirst = originalOrder[0].toolType;
      final originalSecond = originalOrder[1].toolType;

      await container.read(toolbarConfigProvider.notifier).reorderTools(0, 1);

      final newOrder = container.read(toolbarConfigProvider).sortedTools;
      expect(newOrder[0].toolType, originalSecond);
      expect(newOrder[1].toolType, originalFirst);
    });

    test('can toggle tool visibility', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final tool = ToolType.sticker;
      await container
          .read(toolbarConfigProvider.notifier)
          .toggleToolVisibility(tool);

      final config = container.read(toolbarConfigProvider);
      final toolConfig = config.tools.firstWhere((t) => t.toolType == tool);
      expect(toolConfig.isVisible, false);
    });

    test('can reset to default', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Make some changes
      await container.read(toolbarConfigProvider.notifier).reorderTools(0, 3);
      await container
          .read(toolbarConfigProvider.notifier)
          .toggleToolVisibility(ToolType.brushPen);

      // Reset
      await container.read(toolbarConfigProvider.notifier).resetToDefault();

      final config = container.read(toolbarConfigProvider);
      final brushPenConfig =
          config.tools.firstWhere((t) => t.toolType == ToolType.brushPen);
      expect(brushPenConfig.isVisible, true);
    });
  });

  group('Undo/Redo Providers', () {
    test('undo is disabled by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(canUndoProvider), false);
    });

    test('redo is disabled by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(canRedoProvider), false);
    });
  });
}

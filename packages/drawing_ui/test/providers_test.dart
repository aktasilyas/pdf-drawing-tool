import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';

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

      container.read(activePanelProvider.notifier).state = ToolType.brush;
      expect(container.read(activePanelProvider), ToolType.brush);
    });

    test('can close panel by setting to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activePanelProvider.notifier).state = ToolType.brush;
      container.read(activePanelProvider.notifier).state = null;
      expect(container.read(activePanelProvider), isNull);
    });
  });

  group('Pen Settings Provider', () {
    test('has default settings for ballpoint pen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.color, const Color(0xFF000000));
      expect(settings.thickness, 2.0);
      expect(settings.nibShape, NibShapeType.circle);
    });

    test('can update color', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setColor(Colors.blue);
      
      final settings = container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.color, Colors.blue);
    });

    test('can update thickness', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(penSettingsProvider(ToolType.ballpointPen).notifier)
          .setThickness(5.0);
      
      final settings = container.read(penSettingsProvider(ToolType.ballpointPen));
      expect(settings.thickness, 5.0);
    });

    test('fountain pen has ellipse nib by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(penSettingsProvider(ToolType.fountainPen));
      expect(settings.nibShape, NibShapeType.ellipse);
      expect(settings.nibAngle, -0.4);
    });
  });

  group('Highlighter Settings Provider', () {
    test('has semi-transparent yellow by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(highlighterSettingsProvider);
      expect(settings.color.alpha, 0x80);
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
    test('pixel mode is default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(eraserSettingsProvider);
      expect(settings.mode, EraserMode.pixel);
    });

    test('can change eraser mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(eraserSettingsProvider.notifier).setMode(EraserMode.stroke);
      
      final settings = container.read(eraserSettingsProvider);
      expect(settings.mode, EraserMode.stroke);
    });

    test('can toggle options', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(eraserSettingsProvider.notifier).setEraseOnlyHighlighter(true);
      
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
        toolType: ToolType.brush,
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

      container.read(shapesSettingsProvider.notifier).setSelectedShape(ShapeType.star);
      
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
    test('has default tool order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(toolbarConfigProvider);
      expect(config.toolOrder, isNotEmpty);
      expect(config.visibleTools, isNotEmpty);
    });

    test('can reorder tools', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final originalOrder = container.read(toolbarConfigProvider).toolOrder;
      final originalFirst = originalOrder[0];
      final originalSecond = originalOrder[1];

      container.read(toolbarConfigProvider.notifier).reorderTools(0, 1);
      
      final newOrder = container.read(toolbarConfigProvider).toolOrder;
      expect(newOrder[0], originalSecond);
      expect(newOrder[1], originalFirst);
    });

    test('can toggle tool visibility', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tool = ToolType.sticker;
      container.read(toolbarConfigProvider.notifier).setToolVisibility(tool, false);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.visibleTools.contains(tool), false);
    });

    test('can reset to default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Make some changes
      container.read(toolbarConfigProvider.notifier).reorderTools(0, 3);
      container.read(toolbarConfigProvider.notifier).setToolVisibility(ToolType.brush, false);

      // Reset
      container.read(toolbarConfigProvider.notifier).resetToDefault();
      
      final config = container.read(toolbarConfigProvider);
      expect(config.visibleTools.contains(ToolType.brush), true);
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

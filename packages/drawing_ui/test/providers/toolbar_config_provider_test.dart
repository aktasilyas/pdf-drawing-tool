import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

void main() {
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

  group('ToolbarConfigNotifier', () {
    test('loads default config when no saved config', () {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final config = container.read(toolbarConfigProvider);
      
      expect(config.tools.isNotEmpty, isTrue);
      expect(config.tools.every((t) => t.isVisible), isTrue);
    });

    test('toggleToolVisibility works and persists', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      await notifier.toggleToolVisibility(ToolType.pixelEraser);
      
      final config = container.read(toolbarConfigProvider);
      final eraserConfig = config.tools.firstWhere((t) => t.toolType == ToolType.pixelEraser);
      
      expect(eraserConfig.isVisible, isFalse);
      
      // Check persistence
      final savedJson = prefs.getString('starnote_toolbar_config');
      expect(savedJson, isNotNull);
    });

    test('reorderTools works correctly', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      final initialFirst = container.read(toolbarConfigProvider).sortedTools.first.toolType;
      
      await notifier.reorderTools(0, 3);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.sortedTools[3].toolType, equals(initialFirst));
    });

    test('toggleQuickAccess works', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      final initialValue = container.read(toolbarConfigProvider).showQuickAccess;
      
      await notifier.toggleQuickAccess();
      
      final config = container.read(toolbarConfigProvider);
      expect(config.showQuickAccess, equals(!initialValue));
    });

    test('setQuickAccessColors persists', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      final colors = [0xFF000000, 0xFF0000FF, 0xFFFF0000];
      
      await notifier.setQuickAccessColors(colors);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.quickAccessColors, equals(colors));
    });

    test('setQuickAccessThicknesses persists', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      final thicknesses = [1.0, 2.5, 5.0];
      
      await notifier.setQuickAccessThicknesses(thicknesses);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.quickAccessThicknesses, equals(thicknesses));
    });

    test('resetToDefault restores all tools', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      // Make some changes
      await notifier.toggleToolVisibility(ToolType.ballpointPen);
      await notifier.toggleToolVisibility(ToolType.pixelEraser);
      
      // Reset
      await notifier.resetToDefault();
      
      final config = container.read(toolbarConfigProvider);
      expect(config.tools.every((t) => t.isVisible), isTrue);
    });

    test('loads saved config on init', () async {
      // Save a config first
      final savedConfig = ToolbarConfig.defaultConfig()
          .toggleToolVisibility(ToolType.shapes);
      await prefs.setString('starnote_toolbar_config', savedConfig.toJsonString());
      
      // Create new container (simulates app restart)
      final container = createContainer();
      addTearDown(container.dispose);
      
      final config = container.read(toolbarConfigProvider);
      
      final shapesConfig = config.tools.firstWhere((t) => t.toolType == ToolType.shapes);
      expect(shapesConfig.isVisible, isFalse);
    });

    test('handles corrupted JSON gracefully', () async {
      // Save invalid JSON
      await prefs.setString('starnote_toolbar_config', 'invalid json {{{');
      
      // Should load default config instead of crashing
      final container = createContainer();
      addTearDown(container.dispose);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.tools.isNotEmpty, isTrue);
      expect(config.tools.every((t) => t.isVisible), isTrue);
    });

    test('updateConfig replaces entire config', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      final newConfig = ToolbarConfig.defaultConfig()
          .toggleToolVisibility(ToolType.highlighter)
          .copyWith(showQuickAccess: false);
      
      await notifier.updateConfig(newConfig);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.showQuickAccess, isFalse);
      
      final highlighterConfig = config.tools.firstWhere((t) => t.toolType == ToolType.highlighter);
      expect(highlighterConfig.isVisible, isFalse);
    });
  });

  group('visibleToolsProvider', () {
    test('returns only visible tools', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      // Hide some tools
      await notifier.toggleToolVisibility(ToolType.pixelEraser);
      await notifier.toggleToolVisibility(ToolType.sticker);
      
      final visibleTools = container.read(visibleToolsProvider);
      
      expect(visibleTools.any((t) => t.toolType == ToolType.pixelEraser), isFalse);
      expect(visibleTools.any((t) => t.toolType == ToolType.sticker), isFalse);
      expect(visibleTools.every((t) => t.isVisible), isTrue);
    });

    test('updates when toolbar config changes', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      final initialCount = container.read(visibleToolsProvider).length;
      
      await notifier.toggleToolVisibility(ToolType.shapes);
      
      final newCount = container.read(visibleToolsProvider).length;
      expect(newCount, equals(initialCount - 1));
    });
  });

  group('isToolVisibleProvider', () {
    test('returns correct visibility for a tool', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      // Initially all tools should be visible
      expect(container.read(isToolVisibleProvider(ToolType.pixelEraser)), isTrue);
      
      // Toggle visibility
      await notifier.toggleToolVisibility(ToolType.pixelEraser);
      
      expect(container.read(isToolVisibleProvider(ToolType.pixelEraser)), isFalse);
      expect(container.read(isToolVisibleProvider(ToolType.ballpointPen)), isTrue);
    });

    test('returns default for unknown tool type', () {
      final container = createContainer();
      addTearDown(container.dispose);
      
      // This should not crash even if the tool type doesn't exist in config
      final isVisible = container.read(isToolVisibleProvider(ToolType.ballpointPen));
      expect(isVisible, isTrue);
    });
  });
}

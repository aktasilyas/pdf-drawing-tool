import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

void main() {
  group('ToolConfig', () {
    test('creates with default values', () {
      const config = ToolConfig(toolType: ToolType.ballpointPen);
      
      expect(config.isVisible, isTrue);
      expect(config.order, equals(0));
    });

    test('copyWith works correctly', () {
      const config = ToolConfig(toolType: ToolType.ballpointPen, isVisible: true);
      final updated = config.copyWith(isVisible: false);
      
      expect(updated.isVisible, isFalse);
      expect(updated.toolType, equals(ToolType.ballpointPen));
    });

    test('JSON serialization roundtrip', () {
      const config = ToolConfig(
        toolType: ToolType.pixelEraser,
        isVisible: false,
        order: 5,
      );
      
      final json = config.toJson();
      final restored = ToolConfig.fromJson(json);
      
      expect(restored, equals(config));
    });
  });

  group('ToolbarConfig', () {
    test('defaultConfig has all tools visible', () {
      final config = ToolbarConfig.defaultConfig();
      
      expect(config.tools.every((t) => t.isVisible), isTrue);
      expect(config.tools.length, greaterThan(5));
    });

    test('visibleTools filters hidden tools', () {
      var config = ToolbarConfig.defaultConfig();
      config = config.toggleToolVisibility(ToolType.pixelEraser);
      
      final visible = config.visibleTools;
      
      expect(visible.any((t) => t.toolType == ToolType.pixelEraser), isFalse);
    });

    test('reorderTools updates order correctly', () {
      final config = ToolbarConfig.defaultConfig();
      final firstTool = config.sortedTools.first.toolType;
      
      final reordered = config.reorderTools(0, 3);
      final sorted = reordered.sortedTools;
      
      expect(sorted[3].toolType, equals(firstTool));
    });

    test('JSON serialization roundtrip', () {
      final config = ToolbarConfig.defaultConfig();
      
      final jsonString = config.toJsonString();
      final restored = ToolbarConfig.fromJsonString(jsonString);
      
      expect(restored.tools.length, equals(config.tools.length));
      expect(restored.showQuickAccess, equals(config.showQuickAccess));
    });

    test('reset returns default config', () {
      var config = ToolbarConfig.defaultConfig();
      config = config.toggleToolVisibility(ToolType.ballpointPen);
      config = config.toggleToolVisibility(ToolType.pixelEraser);
      
      final reset = config.reset();
      
      expect(reset.tools.every((t) => t.isVisible), isTrue);
    });
  });
}

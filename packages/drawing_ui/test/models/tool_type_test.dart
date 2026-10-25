import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart' hide PenType;
import 'package:flutter_pen_toolbar/flutter_pen_toolbar.dart' as toolbar;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolType.fountainPen', () {
    test('maps to core and toolbar PenType', () {
      expect(ToolType.fountainPen.penType, PenType.fountainPen);
      expect(ToolType.fountainPen.isPenTool, isTrue);
      expect(
        PenTypeMapper.toToolbarPenType(ToolType.fountainPen.penType!),
        toolbar.PenType.fountainPen,
      );
    });

    test('is part of the pen group with a settings panel', () {
      expect(penTools, contains(ToolType.fountainPen));
      expect(penToolsSet, contains(ToolType.fountainPen));
      expect(toolsWithPanel, contains(ToolType.fountainPen));
    });

    test('has a display name and an icon', () {
      expect(ToolType.fountainPen.displayName, isNotEmpty);
      expect(ElyanotesIcons.iconForTool(ToolType.fountainPen), isNotNull);
    });
  });
}

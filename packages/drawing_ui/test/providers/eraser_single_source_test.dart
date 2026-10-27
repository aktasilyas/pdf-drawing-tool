import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';

/// #237: the eraser tool type and the eraser mode the canvas erases with
/// must never disagree, whichever path selects the tool.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  ToolType tool() => container.read(currentToolProvider);
  EraserMode activeMode() => container.read(activeEraserModeProvider);
  void select(ToolType t) =>
      container.read(currentToolProvider.notifier).selectTool(t);

  /// What the toolbar shows for the eraser group, as the toolbars build it.
  ToolType eraserButton() {
    final lastMode = container.read(eraserSettingsProvider).mode;
    final tools = getGroupedVisibleTools(
      container.read(toolbarConfigProvider),
      tool(),
      lastEraser: eraserToolForMode(lastMode),
    );
    return tools.firstWhere(eraserTools.contains);
  }

  test('mode helpers map every eraser type both ways', () {
    for (final t in eraserTools) {
      expect(eraserToolForMode(eraserModeForTool(t)!), t);
    }
    expect(eraserModeForTool(ToolType.ballpointPen), isNull);
  });

  test('selecting an eraser tool from any path syncs the mode', () {
    select(ToolType.strokeEraser);
    expect(container.read(eraserSettingsProvider).mode, EraserMode.stroke);
    expect(activeMode(), EraserMode.stroke);

    select(ToolType.lassoEraser);
    expect(activeMode(), EraserMode.lasso);

    select(ToolType.pixelEraser);
    expect(activeMode(), EraserMode.pixel);
  });

  test('stroke eraser > pen > eraser button restores the stroke eraser', () {
    select(ToolType.strokeEraser);
    select(ToolType.ballpointPen);

    expect(eraserButton(), ToolType.strokeEraser);
    select(eraserButton());
    expect(tool(), ToolType.strokeEraser);
    expect(activeMode(), EraserMode.stroke);
  });

  test('the current eraser tool wins over a mismatched stored mode', () {
    select(ToolType.strokeEraser);
    container.read(eraserSettingsProvider.notifier).setMode(EraserMode.pixel);
    expect(activeMode(), EraserMode.stroke);
    expect(container.read(eraserModeProvider), EraserMode.stroke);
  });

  test('old prefs with mismatched tool and mode load consistently', () async {
    SharedPreferences.setMockInitialValues({
      'elyanotes_current_tool': ToolType.strokeEraser.name,
      'elyanotes_eraser': '{"mode":"pixel","size":20.0}',
    });
    final prefs = await SharedPreferences.getInstance();
    final loaded = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(loaded.dispose);

    expect(loaded.read(currentToolProvider), ToolType.strokeEraser);
    expect(loaded.read(activeEraserModeProvider), EraserMode.stroke);
  });
}

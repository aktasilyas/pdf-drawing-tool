import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/drawing_screen.dart';

/// Toolbar button handlers (undo, redo, settings panel) for
/// [DrawingScreen]'s state.
mixin DrawingScreenToolbarActions on ConsumerState<DrawingScreen> {
  void onUndoPressed() {
    ref.read(historyManagerProvider.notifier).undo();
  }

  void onRedoPressed() {
    ref.read(historyManagerProvider.notifier).redo();
  }

  /// Toggles the toolbar settings panel.
  void onSettingsPressed() {
    final current = ref.read(activePanelProvider);
    if (current == ToolType.toolbarSettings) {
      closePanel();
    } else {
      ref.read(activePanelProvider.notifier).state = ToolType.toolbarSettings;
    }
  }

  /// Closes whichever tool panel is open.
  void closePanel() {
    ref.read(activePanelProvider.notifier).state = null;
  }
}

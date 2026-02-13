import 'package:flutter/material.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/toolbar/medium_toolbar.dart';
import 'package:drawing_ui/src/toolbar/tool_bar.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

/// Adaptive toolbar that switches layout based on available width.
///
/// - >=840px: [ToolBar] (expanded — full horizontal, all sections visible)
/// - 600-839px: [MediumToolbar] (compact horizontal, overflow menu)
/// - <600px: [SizedBox.shrink] (compact bottom bar — future phase)
class AdaptiveToolbar extends StatelessWidget {
  const AdaptiveToolbar({
    super.key,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
    this.onSidebarToggle,
    this.showSidebarButton = false,
    this.isSidebarOpen = false,
  });

  /// Callback when undo is pressed.
  final VoidCallback? onUndoPressed;

  /// Callback when redo is pressed.
  final VoidCallback? onRedoPressed;

  /// Callback when toolbar config is pressed.
  final VoidCallback? onSettingsPressed;

  /// GlobalKey for settings button (for anchored panel positioning).
  final GlobalKey? settingsButtonKey;

  /// GlobalKeys for each tool button (for anchored panel positioning).
  final Map<ToolType, GlobalKey>? toolButtonKeys;

  /// Single GlobalKey for pen group button (all pen tools share this).
  final GlobalKey? penGroupButtonKey;

  /// Single GlobalKey for highlighter group button.
  final GlobalKey? highlighterGroupButtonKey;

  /// Callback when sidebar toggle is pressed.
  final VoidCallback? onSidebarToggle;

  /// Whether to show sidebar toggle button.
  final bool showSidebarButton;

  /// Whether sidebar is currently open.
  final bool isSidebarOpen;

  /// Returns true if compact mode should be used (phone layout).
  /// When true, DrawingScreen should:
  /// 1. Hide this toolbar (renders SizedBox.shrink)
  /// 2. Show CompactBottomBar at bottom
  /// 3. Use showToolPanelSheet for panels instead of AnchoredPanel
  static bool shouldUseCompactMode(BuildContext context) {
    return MediaQuery.of(context).size.width < ToolbarLayoutMode.compactBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= ToolbarLayoutMode.expandedBreakpoint) {
          return ToolBar(
            onUndoPressed: onUndoPressed,
            onRedoPressed: onRedoPressed,
            onSettingsPressed: onSettingsPressed,
            settingsButtonKey: settingsButtonKey,
            toolButtonKeys: toolButtonKeys,
            penGroupButtonKey: penGroupButtonKey,
            highlighterGroupButtonKey: highlighterGroupButtonKey,
            onSidebarToggle: onSidebarToggle,
            showSidebarButton: showSidebarButton,
            isSidebarOpen: isSidebarOpen,
          );
        }

        if (width >= ToolbarLayoutMode.compactBreakpoint) {
          return MediumToolbar(
            onUndoPressed: onUndoPressed,
            onRedoPressed: onRedoPressed,
            onSettingsPressed: onSettingsPressed,
            settingsButtonKey: settingsButtonKey,
            toolButtonKeys: toolButtonKeys,
            penGroupButtonKey: penGroupButtonKey,
            highlighterGroupButtonKey: highlighterGroupButtonKey,
            onSidebarToggle: onSidebarToggle,
            showSidebarButton: showSidebarButton,
            isSidebarOpen: isSidebarOpen,
          );
        }

        // Compact (<600px): Future phase — bottom bar widget
        return const SizedBox.shrink();
      },
    );
  }
}

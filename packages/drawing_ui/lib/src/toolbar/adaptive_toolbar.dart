import 'package:flutter/material.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/toolbar/tool_bar.dart';

/// Adaptive toolbar wrapper that delegates to the appropriate toolbar layout
/// based on available screen width.
///
/// Currently delegates directly to [ToolBar] (expanded mode).
/// Future phases will add LayoutBuilder-based switching between
/// expanded, medium, and compact toolbar layouts.
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

  @override
  Widget build(BuildContext context) {
    // Phase M1.1: Direct passthrough to ToolBar (expanded mode).
    // Future: LayoutBuilder will switch between expanded/medium/compact.
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
}

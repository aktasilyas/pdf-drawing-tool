import 'package:flutter/material.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/toolbar/compact_bottom_bar.dart';
import 'package:drawing_ui/src/toolbar/medium_toolbar.dart';
import 'package:drawing_ui/src/toolbar/tool_bar.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';
import 'package:drawing_ui/src/toolbar/top_navigation_bar.dart';

/// Adaptive toolbar that switches layout based on available width.
///
/// - >=840px: [ToolBar] — single-row with nav + tools
/// - 600-839px: [MediumToolbar] — single-row with nav + tools (overflow menu)
/// - <600px: Two-row layout — [TopNavigationBar] + [CompactToolRow]
class AdaptiveToolbar extends StatelessWidget {
  const AdaptiveToolbar({
    super.key,
    this.onAIPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.onToolPanelRequested,
    this.onUndoPressed,
    this.onRedoPressed,
  });

  /// Callback when AI button is pressed.
  final VoidCallback? onAIPressed;

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

  // Nav parameters (passed through to ToolBar/MediumToolbar/TopNavigationBar)
  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;

  /// Callback when a tool's panel should open (compact mode only).
  final ValueChanged<ToolType>? onToolPanelRequested;

  /// Callback when undo is pressed (compact mode).
  final VoidCallback? onUndoPressed;

  /// Callback when redo is pressed (compact mode).
  final VoidCallback? onRedoPressed;

  /// Returns true if compact mode should be used (phone layout).
  /// When true, the toolbar renders as a two-row layout.
  static bool shouldUseCompactMode(BuildContext context) {
    return MediaQuery.of(context).size.width <
        ToolbarLayoutMode.compactBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= ToolbarLayoutMode.expandedBreakpoint) {
          return ToolBar(
            onAIPressed: onAIPressed,
            onSettingsPressed: onSettingsPressed,
            settingsButtonKey: settingsButtonKey,
            toolButtonKeys: toolButtonKeys,
            penGroupButtonKey: penGroupButtonKey,
            highlighterGroupButtonKey: highlighterGroupButtonKey,
            documentTitle: documentTitle,
            onHomePressed: onHomePressed,
            onRenameDocument: onRenameDocument,
            onDeleteDocument: onDeleteDocument,
            onSidebarToggle: onSidebarToggle,
            isSidebarOpen: isSidebarOpen,
          );
        }

        if (width >= ToolbarLayoutMode.compactBreakpoint) {
          return MediumToolbar(
            onAIPressed: onAIPressed,
            onSettingsPressed: onSettingsPressed,
            settingsButtonKey: settingsButtonKey,
            toolButtonKeys: toolButtonKeys,
            penGroupButtonKey: penGroupButtonKey,
            highlighterGroupButtonKey: highlighterGroupButtonKey,
            documentTitle: documentTitle,
            onHomePressed: onHomePressed,
            onRenameDocument: onRenameDocument,
            onDeleteDocument: onDeleteDocument,
            onSidebarToggle: onSidebarToggle,
            isSidebarOpen: isSidebarOpen,
          );
        }

        // Compact (<600px): Two-row layout — nav bar + tool row
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TopNavigationBar(
              documentTitle: documentTitle,
              onHomePressed: onHomePressed,
              onRenameDocument: onRenameDocument,
              onDeleteDocument: onDeleteDocument,
              onSidebarToggle: onSidebarToggle,
              isSidebarOpen: isSidebarOpen,
              compact: true,
              onAIPressed: onAIPressed,
              onToolPanelRequested: onToolPanelRequested,
            ),
            CompactToolRow(
              onAIPressed: onAIPressed,
              onUndoPressed: onUndoPressed,
              onRedoPressed: onRedoPressed,
              onPanelRequested: onToolPanelRequested,
            ),
          ],
        );
      },
    );
  }
}

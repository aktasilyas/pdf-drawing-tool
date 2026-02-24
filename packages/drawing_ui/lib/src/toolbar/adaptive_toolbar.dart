import 'package:flutter/material.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/toolbar/medium_toolbar.dart';
import 'package:drawing_ui/src/toolbar/tool_bar.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';
import 'package:drawing_ui/src/toolbar/top_navigation_bar.dart';

/// Adaptive toolbar that switches layout based on available width.
///
/// - >=840px: [ToolBar] — single-row with nav + tools
/// - 600-839px: [MediumToolbar] — single-row with nav + tools (overflow menu)
/// - <600px: [TopNavigationBar] (compact) — nav only, tools on bottom bar
class AdaptiveToolbar extends StatelessWidget {
  const AdaptiveToolbar({
    super.key,
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
  });

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

  /// Returns true if compact mode should be used (phone layout).
  /// When true, DrawingScreen should show CompactBottomBar at bottom.
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

        // Compact (<600px): Navigation bar only, tools on bottom bar
        return TopNavigationBar(
          documentTitle: documentTitle,
          onHomePressed: onHomePressed,
          onRenameDocument: onRenameDocument,
          onDeleteDocument: onDeleteDocument,
          onSidebarToggle: onSidebarToggle,
          isSidebarOpen: isSidebarOpen,
          compact: true,
        );
      },
    );
  }
}

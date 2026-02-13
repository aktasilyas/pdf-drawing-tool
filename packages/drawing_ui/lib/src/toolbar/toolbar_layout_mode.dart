/// Toolbar display mode based on available screen width.
///
/// Used by [AdaptiveToolbar] to switch between layout tiers:
/// - [expanded]: Full horizontal toolbar with all sections visible (>=840px)
/// - [medium]: Compact horizontal with overflow menu (600-839px)
/// - [compact]: Bottom bar with bottom sheet panels (<600px)
enum ToolbarLayoutMode {
  /// >=840px - Full horizontal toolbar, all sections visible.
  ///
  /// Shows: undo/redo | tools (scrollable) | config | quick access | actions
  expanded,

  /// 600-839px - Compact horizontal, overflow menu for extra tools.
  ///
  /// Shows: undo/redo | tools (first 6-8) | overflow menu
  /// Quick access: collapsible row below toolbar
  medium,

  /// <600px - Bottom bar with bottom sheet panels.
  ///
  /// Shows: undo/redo | active tool group (max 5) | more button
  /// All panels open as bottom sheets
  compact;

  /// Breakpoint below which compact (phone) layout is used.
  static const double compactBreakpoint = 600;

  /// Breakpoint at or above which expanded (tablet landscape) layout is used.
  static const double expandedBreakpoint = 840;
}

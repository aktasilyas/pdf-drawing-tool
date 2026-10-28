import 'package:flutter/foundation.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/models/selection_action_kind.dart';

/// A single action that can be performed on a selection.
class SelectionAction {
  /// Unique identifier for this action.
  final String id;

  /// Icon to display.
  final PhosphorIconData icon;

  /// Semantic kind; the localized label is derived from it in the UI.
  final SelectionActionKind kind;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  /// Whether this action is currently enabled.
  final bool isEnabled;

  /// Callback when action is executed.
  final VoidCallback? onExecute;

  /// If non-null, renders a filled color circle instead of an icon.
  final int? colorIndicator;

  const SelectionAction({
    required this.id,
    required this.icon,
    required this.kind,
    this.isDestructive = false,
    this.isEnabled = true,
    this.onExecute,
    this.colorIndicator,
  });
}

/// Configuration for selection actions split between toolbar and overflow.
class SelectionActionConfig {
  /// Quick actions shown in the horizontal toolbar (max 6-7).
  final List<SelectionAction> toolbarActions;

  /// Icon buttons shown in a horizontal row at the top of the overflow menu.
  final List<SelectionAction> topRowActions;

  /// List actions shown in the overflow menu (text left, icon right).
  final List<SelectionAction> overflowActions;

  const SelectionActionConfig({
    required this.toolbarActions,
    this.topRowActions = const [],
    required this.overflowActions,
  });
}

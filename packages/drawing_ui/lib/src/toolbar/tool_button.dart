import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// A tool button with GoodNotes-style selection indicator.
///
/// Selected state: [colorScheme.primary] pill background + white icon.
/// Deselected state: transparent background + [colorScheme.onSurfaceVariant] icon.
///
/// If the tool is already selected and has a panel, tapping opens the panel.
/// Otherwise, tapping selects the tool.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.toolType,
    required this.isSelected,
    required this.onPressed,
    this.onPanelTap,
    this.enabled = true,
    this.buttonKey,
    this.hasPanel = false,
    this.customIcon,
    this.compact = false,
  });

  /// The type of tool this button represents.
  final ToolType toolType;

  /// Whether this tool is currently selected.
  final bool isSelected;

  /// Callback when the button is pressed (selects tool).
  final VoidCallback onPressed;

  /// Callback when a selected tool with panel is tapped again.
  final VoidCallback? onPanelTap;

  /// Whether the button is enabled.
  final bool enabled;

  /// Optional key for the button (for anchored panel positioning).
  final GlobalKey? buttonKey;

  /// Whether this tool has a settings panel.
  final bool hasPanel;

  /// Custom icon to override the default tool icon.
  final IconData? customIcon;

  /// Whether to use compact sizing (phone layout).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonSize = compact ? 36.0 : 40.0;
    final iconSize = compact ? 20.0 : StarNoteIcons.toolSize;

    final Color bgColor;
    final Color iconColor;

    if (!enabled) {
      bgColor = Colors.transparent;
      iconColor = colorScheme.onSurface.withValues(alpha: 0.25);
    } else if (isSelected) {
      bgColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
    } else {
      bgColor = Colors.transparent;
      iconColor = colorScheme.onSurfaceVariant;
    }

    final iconData =
        customIcon ?? StarNoteIcons.iconForTool(toolType, active: isSelected);

    return Semantics(
      label: toolType.displayName,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: toolType.displayName,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  if (isSelected && hasPanel && onPanelTap != null) {
                    onPanelTap!();
                  } else {
                    onPressed();
                  }
                }
              : null,
          child: Container(
            key: buttonKey,
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: PhosphorIcon(iconData, size: iconSize, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the default icon for a given [ToolType].
  static IconData getIconForTool(ToolType type) {
    return StarNoteIcons.iconForTool(type);
  }
}

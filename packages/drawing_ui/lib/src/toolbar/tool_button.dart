import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// A button for selecting a tool in the toolbar.
///
/// Displays an icon and handles selection state with visual feedback.
/// If the tool has a panel, shows a small chevron indicator when selected.
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
  });

  /// The type of tool this button represents.
  final ToolType toolType;

  /// Whether this tool is currently selected.
  final bool isSelected;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Callback when the panel chevron is tapped.
  final VoidCallback? onPanelTap;

  /// Whether the button is enabled.
  final bool enabled;

  /// Optional key for the button (used for anchoring panels).
  final GlobalKey? buttonKey;

  /// Whether this tool has a settings panel.
  final bool hasPanel;

  /// Custom icon to override default.
  final IconData? customIcon;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    final iconColor = !enabled
        ? theme.toolbarIconDisabledColor
        : isSelected
            ? theme.toolbarIconSelectedColor
            : theme.toolbarIconColor;

    final bgColor = isSelected
        ? theme.toolbarIconSelectedColor.withValues(alpha: 0.1)
        : Colors.transparent;

    // Show chevron when selected AND has panel
    final showChevron = isSelected && hasPanel && onPanelTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              // Eğer zaten seçiliyse ve panel varsa, panel aç
              if (isSelected && hasPanel && onPanelTap != null) {
                onPanelTap!();
              } else {
                onPressed();
              }
            }
          : null,
      child: Container(
        key: buttonKey,
        width: theme.toolButtonSize,
        height: theme.toolButtonSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ana ikon - chevron varsa biraz yukarı kaydır
            Padding(
              padding: EdgeInsets.only(bottom: showChevron ? 4 : 0),
              child: _buildIcon(
                theme: theme,
                iconColor: iconColor,
                showChevron: showChevron,
              ),
            ),
            // Chevron indicator - alt kısımda
            if (showChevron)
              Positioned(
                bottom: 2,
                child: PhosphorIcon(
                  StarNoteIcons.caretDown,
                  size: 10,
                  color: theme.toolbarIconSelectedColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Gets the appropriate icon for a tool type.
  static IconData getIconForTool(ToolType type) {
    return StarNoteIcons.iconForTool(type);
  }

  /// Build the appropriate icon widget based on tool type.
  Widget _buildIcon({
    required DrawingTheme theme,
    required Color iconColor,
    required bool showChevron,
  }) {
    final iconData =
        customIcon ?? StarNoteIcons.iconForTool(toolType, active: isSelected);
    return PhosphorIcon(
      iconData,
      size: showChevron ? theme.toolIconSize - 2 : theme.toolIconSize,
      color: iconColor,
    );
  }
}

/// Undo button for the toolbar.
class UndoButton extends StatelessWidget {
  const UndoButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  /// Whether undo is available.
  final bool enabled;

  /// Callback when pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final color = enabled
        ? theme.toolbarIconColor
        : theme.toolbarIconDisabledColor;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: PhosphorIcon(
          StarNoteIcons.undo,
          size: StarNoteIcons.actionSize,
          color: color,
        ),
      ),
    );
  }
}

/// Redo button for the toolbar.
class RedoButton extends StatelessWidget {
  const RedoButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  /// Whether redo is available.
  final bool enabled;

  /// Callback when pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final color = enabled
        ? theme.toolbarIconColor
        : theme.toolbarIconDisabledColor;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: PhosphorIcon(
          StarNoteIcons.redo,
          size: StarNoteIcons.actionSize,
          color: color,
        ),
      ),
    );
  }
}

/// Settings button for the toolbar.
class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.onPressed,
    this.buttonKey,
  });

  /// Callback when pressed.
  final VoidCallback onPressed;

  /// Optional key for anchoring.
  final GlobalKey? buttonKey;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        key: buttonKey,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: PhosphorIcon(
          StarNoteIcons.settings,
          size: StarNoteIcons.actionSize,
          color: theme.toolbarIconColor,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

/// A toolbar tool button; renders a [ChromeIconButton].
///
/// Idle: `textMuted` icon. Selected: `accentContainer` fill, `accent` icon
/// and the active icon variant. 48dp hit area.
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

  /// Optional key on the 40dp visual (for anchored panel positioning).
  final GlobalKey? buttonKey;

  /// Whether this tool has a settings panel.
  final bool hasPanel;

  /// Custom icon to override the default tool icon.
  final IconData? customIcon;

  /// Phone layout. Kept for API compatibility: phone slots use the same
  /// 48dp hit area and 40dp visual as tablet (spec section 3).
  final bool compact;

  void _handleTap() {
    if (isSelected && hasPanel && onPanelTap != null) {
      onPanelTap!();
    } else {
      onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = customIcon ?? ElyanotesIcons.iconForTool(toolType);
    final selectedIcon =
        customIcon ?? ElyanotesIcons.iconForTool(toolType, active: true);

    return ChromeIconButton(
      icon: icon,
      selectedIcon: selectedIcon,
      tooltip: toolType.label(context.drawingStrings),
      onPressed: _handleTap,
      selected: isSelected,
      enabled: enabled,
      visualKey: buttonKey,
    );
  }

  /// Returns the default icon for a given [ToolType].
  static IconData getIconForTool(ToolType type) {
    return ElyanotesIcons.iconForTool(type);
  }
}

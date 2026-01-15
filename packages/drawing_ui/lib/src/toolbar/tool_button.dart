import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

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

    // Modern color scheme
    const selectedColor = Color(0xFF4A9DFF);
    const defaultColor = Color(0xFF666666);
    const disabledColor = Color(0xFFBBBBBB);

    final iconColor = !enabled
        ? disabledColor
        : isSelected
            ? selectedColor
            : defaultColor;

    final bgColor = isSelected
        ? selectedColor.withAlpha(25)
        : Colors.transparent;

    // Show chevron when selected AND has panel
    final showChevron = isSelected && hasPanel && onPanelTap != null;

    return GestureDetector(
      onTap: enabled ? () {
        // Eğer zaten seçiliyse ve panel varsa, panel aç
        if (isSelected && hasPanel && onPanelTap != null) {
          onPanelTap!();
        } else {
          onPressed();
        }
      } : null,
      child: Container(
        key: buttonKey,
        width: theme.toolButtonSize,
        height: theme.toolButtonSize, // Sabit yükseklik
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
                child: Icon(
                  Icons.expand_more,
                  size: 10,
                  color: selectedColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Gets the appropriate icon for a tool type.
  static IconData getIconForTool(ToolType type) {
    switch (type) {
      case ToolType.pencil:
        return Icons.edit_outlined;
      case ToolType.hardPencil:
        return Icons.create;
      case ToolType.ballpointPen:
        return Icons.edit;
      case ToolType.gelPen:
        return Icons.edit;
      case ToolType.dashedPen:
        return Icons.timeline;
      case ToolType.brushPen:
        return Icons.brush;
      case ToolType.marker:
        return Icons.border_color;
      case ToolType.neonHighlighter:
        return Icons.flash_on;
      case ToolType.highlighter:
        return Icons.highlight;
      case ToolType.rulerPen:
        return Icons.straighten; // Ruler icon for straight lines
      case ToolType.pixelEraser:
        return Icons.auto_fix_normal;
      case ToolType.strokeEraser:
        return Icons.cleaning_services;
      case ToolType.lassoEraser:
        return Icons.gesture;
      case ToolType.shapes:
        return Icons.crop_square;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.sticker:
        return Icons.emoji_emotions;
      case ToolType.image:
        return Icons.image;
      case ToolType.selection:
        return Icons.select_all;
      case ToolType.panZoom:
        return Icons.pan_tool;
      case ToolType.laserPointer:
        return Icons.highlight_alt;
    }
  }

  IconData _getIconForTool(ToolType type) => getIconForTool(type);

  /// Build the appropriate icon widget based on tool type.
  Widget _buildIcon({
    required DrawingTheme theme,
    required Color iconColor,
    required bool showChevron,
  }) {
    // For pen tools (that have a PenType), use custom icon
    final penType = toolType.penType;
    if (penType != null && customIcon == null) {
      final iconSize = showChevron ? theme.toolIconSize : theme.toolIconSize + 4;
      return ToolPenIcon(
        toolType: toolType,
        color: iconColor,
        isSelected: isSelected,
        size: iconSize,
      );
    }

    // For other tools, use Material icon
    return Icon(
      customIcon ?? _getIconForTool(toolType),
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
    const enabledColor = Color(0xFF666666);
    const disabledColor = Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.undo,
          size: 18,
          color: enabled ? enabledColor : disabledColor,
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
    const enabledColor = Color(0xFF666666);
    const disabledColor = Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.redo,
          size: 18,
          color: enabled ? enabledColor : disabledColor,
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
    const iconColor = Color(0xFF666666);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        key: buttonKey,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.settings,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}

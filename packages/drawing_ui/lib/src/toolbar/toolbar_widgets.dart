/// Shared widgets for the toolbar UI.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Undo/Redo button group for toolbar.
class ToolbarUndoRedoButtons extends StatelessWidget {
  const ToolbarUndoRedoButtons({
    super.key,
    required this.canUndo,
    required this.canRedo,
    this.onUndo,
    this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarIconButton(
          icon: StarNoteIcons.undo,
          tooltip: 'Geri al',
          enabled: canUndo,
          onPressed: onUndo,
        ),
        const SizedBox(width: 4),
        ToolbarIconButton(
          icon: StarNoteIcons.redo,
          tooltip: 'İleri al',
          enabled: canRedo,
          onPressed: onRedo,
        ),
      ],
    );
  }
}

/// Vertical divider for toolbar sections.
class ToolbarVerticalDivider extends StatelessWidget {
  const ToolbarVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.panelBorderColor,
    );
  }
}

/// Generic toolbar icon button.
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(
              icon,
              size: StarNoteIcons.actionSize,
              color: enabled
                  ? theme.toolbarIconColor
                  : theme.toolbarIconColor.withValues(alpha: 100.0 / 255.0),
            ),
          ),
        ),
      ),
    );
  }
}

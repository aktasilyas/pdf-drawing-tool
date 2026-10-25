/// Shared widgets for the toolbar UI.
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/drawing_theme.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

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
          icon: ElyanotesIcons.undo,
          tooltip: 'Geri al',
          enabled: canUndo,
          onPressed: onUndo,
        ),
        ToolbarIconButton(
          icon: ElyanotesIcons.redo,
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
      width: 0.5,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.toolbarIconColor.withValues(alpha: 0.3),
    );
  }
}

/// Generic toolbar icon button; renders a [ChromeIconButton].
///
/// 40dp visual in a 48dp hit area, colours from [ChromePalette]
/// (docs/specs/52-editor-chrome.md, section 4).
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
    return ChromeIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed ?? _noop,
      enabled: enabled,
    );
  }

  static void _noop() {}
}

/// Row that spreads [children] evenly and, when it is too narrow for their
/// natural width, gives each an equal share instead of overflowing.
///
/// Used by the phone top bar so 48dp chrome buttons fit narrow screens until
/// the phone toolbar is reworked (docs/specs/52-editor-chrome.md, slice 8).
class ToolbarSharedRow extends StatelessWidget {
  const ToolbarSharedRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final child in children) Flexible(child: child),
      ],
    );
  }
}

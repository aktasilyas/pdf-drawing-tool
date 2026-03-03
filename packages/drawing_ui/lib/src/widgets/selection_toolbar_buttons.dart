import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/selection_action.dart';

/// Icon button for the selection toolbar quick-action bar.
///
/// Renders either a [PhosphorIcon] or a filled color circle
/// (when [SelectionAction.colorIndicator] is set).
class SelectionToolbarButton extends StatelessWidget {
  final SelectionAction action;
  final VoidCallback onTap;

  const SelectionToolbarButton({
    super.key,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = action.isEnabled;
    final color = action.isDestructive ? colorScheme.error : colorScheme.onSurface;

    final child = action.colorIndicator != null
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Color(action.colorIndicator!),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
            ),
          )
        : PhosphorIcon(action.icon, size: 20, color: color);

    return Tooltip(
      message: action.label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.38,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Simple icon-only button for the toolbar (e.g. the "..." more button).
class SelectionToolbarIconButton extends StatelessWidget {
  final PhosphorIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const SelectionToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: PhosphorIcon(icon, size: 20,
              color: isActive ? colorScheme.primary : colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

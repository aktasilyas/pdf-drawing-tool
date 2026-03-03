import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Context menu for text elements showing edit/delete/style/duplicate/move actions
class TextContextMenu extends ConsumerWidget {
  final TextElement textElement;
  final double zoom;
  final Offset canvasOffset;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onStyle;
  final VoidCallback onDuplicate;
  final VoidCallback onMove;

  const TextContextMenu({
    super.key,
    required this.textElement,
    required this.zoom,
    required this.canvasOffset,
    this.onEdit,
    required this.onDelete,
    this.onStyle,
    required this.onDuplicate,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate screen position
    final screenX = textElement.x * zoom + canvasOffset.dx;
    final screenY = textElement.y * zoom + canvasOffset.dy;

    // Position menu above the text
    final menuY = screenY - 50;

    return Positioned(
      left: screenX,
      top: menuY,
      child: Listener(
        // Absorb all pointer events - prevent canvas from handling them
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {}, // Absorb pointer down
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null) ...[
                  _MenuButton(
                    icon: StarNoteIcons.editPencil,
                    tooltip: 'Düzenle',
                    onTap: onEdit!,
                  ),
                  _MenuDivider(color: colorScheme.outlineVariant),
                ],
                _MenuButton(
                  icon: StarNoteIcons.trash,
                  tooltip: 'Sil',
                  onTap: onDelete,
                  color: colorScheme.error,
                ),
                if (onStyle != null) ...[
                  _MenuDivider(color: colorScheme.outlineVariant),
                  _MenuButton(
                    icon: StarNoteIcons.palette,
                    tooltip: 'Stil',
                    onTap: onStyle!,
                  ),
                ],
                _MenuDivider(color: colorScheme.outlineVariant),
                _MenuButton(
                  icon: StarNoteIcons.copy,
                  tooltip: 'Kopyala',
                  onTap: onDuplicate,
                ),
                _MenuDivider(color: colorScheme.outlineVariant),
                _MenuButton(
                  icon: StarNoteIcons.move,
                  tooltip: 'Taşı',
                  onTap: onMove,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menu button widget
class _MenuButton extends StatelessWidget {
  final PhosphorIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _MenuButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(
            icon,
            size: 20,
            color: color ?? colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Vertical divider between menu buttons
class _MenuDivider extends StatelessWidget {
  const _MenuDivider({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: color ?? Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/page_rotation_service.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Header widget for page options panel.
class PageOptionsHeader extends StatelessWidget {
  const PageOptionsHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }
}

/// A single menu item row in the page options panel.
class PageOptionsMenuItem extends StatelessWidget {
  const PageOptionsMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final color =
        disabled ? cs.onSurface.withValues(alpha: 0.38) : isDestructive ? cs.error : cs.onSurface;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              PhosphorIcon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: color),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header for settings area.
class PageOptionsSectionHeader extends StatelessWidget {
  const PageOptionsSectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Toggle switch item for settings.
class PageOptionsToggleItem extends StatelessWidget {
  const PageOptionsToggleItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 22, color: cs.onSurface),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog letting the user choose a rotation angle.
Future<RotationAngle?> showRotatePageDialog(BuildContext context) {
  return showDialog<RotationAngle>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SimpleDialog(
        title: const Text('Sayfayı Döndür'),
        children: [
          _rotateOption(ctx, cs, StarNoteIcons.rotateCW,
              'Saat yönünde (90°)', RotationAngle.cw90),
          _rotateOption(ctx, cs, StarNoteIcons.rotateCCW,
              'Saat yönünün tersine (90°)', RotationAngle.ccw90),
          _rotateOption(ctx, cs, StarNoteIcons.rotateHalf,
              '180°', RotationAngle.half),
        ],
      );
    },
  );
}

Widget _rotateOption(BuildContext ctx, ColorScheme cs, IconData icon,
    String label, RotationAngle angle) {
  return SimpleDialogOption(
    onPressed: () => Navigator.pop(ctx, angle),
    child: Row(
      children: [
        PhosphorIcon(icon, size: 22, color: cs.onSurface),
        const SizedBox(width: 16),
        Text(label),
      ],
    ),
  );
}

/// Dual page (side-by-side) mode toggle.
// ignore: unused_element
class DualPageModeItem extends ConsumerWidget {
  const DualPageModeItem({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDual = ref.watch(dualPageModeProvider);
    return PageOptionsToggleItem(
      icon: StarNoteIcons.splitView,
      label: 'Çift sayfa görünümü',
      value: isDual,
      onChanged: (v) => ref.read(dualPageModeProvider.notifier).state = v,
    );
  }
}

/// Scroll direction toggle for page options settings.
class ScrollDirectionItem extends ConsumerWidget {
  const ScrollDirectionItem({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = ref.watch(scrollDirectionProvider);
    final isHorizontal = direction == Axis.horizontal;
    final cs = Theme.of(context).colorScheme;
    return PageOptionsMenuItem(
      icon: isHorizontal
          ? StarNoteIcons.scrollDirection
          : StarNoteIcons.scrollDirectionVertical,
      label: 'Kaydırma yönü',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHorizontal ? 'Yatay' : 'Dikey',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          PhosphorIcon(
            StarNoteIcons.chevronRight,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () {
        ref.read(scrollDirectionProvider.notifier).state =
            isHorizontal ? Axis.vertical : Axis.horizontal;
      },
    );
  }
}

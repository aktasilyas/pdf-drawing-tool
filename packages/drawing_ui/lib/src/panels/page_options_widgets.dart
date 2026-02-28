import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/page_rotation_service.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Header widget for page options panel.
class PageOptionsHeader extends StatelessWidget {
  const PageOptionsHeader({super.key, required this.title, this.compact = false});
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 8 : 12,
      ),
      child: Text(
        title,
        style: GoogleFonts.sourceSerif4(
          fontSize: compact ? 14 : 16,
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
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final color =
        disabled ? cs.onSurface.withValues(alpha: 0.38) : isDestructive ? cs.error : cs.onSurface;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: compact ? 40 : 48,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
          child: Row(
            children: [
              PhosphorIcon(icon, size: compact ? 20 : 22, color: color),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sourceSerif4(fontSize: compact ? 13 : 15, color: color),
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
  const PageOptionsSectionHeader({super.key, required this.title, this.compact = false});
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 20, compact ? 2 : 4, compact ? 16 : 20, compact ? 1 : 2),
      child: Text(
        title,
        style: GoogleFonts.sourceSerif4(
          fontSize: compact ? 12 : 13,
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
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: compact ? 40 : 48,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        child: Row(
          children: [
            PhosphorIcon(icon, size: compact ? 20 : 22, color: cs.onSurface),
            SizedBox(width: compact ? 12 : 16),
            Expanded(
              child: subtitle != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: GoogleFonts.sourceSerif4(fontSize: compact ? 13 : 15, color: cs.onSurface)),
                        Text(subtitle!, style: GoogleFonts.sourceSerif4(fontSize: compact ? 11 : 12, color: cs.onSurfaceVariant)),
                      ],
                    )
                  : Text(label, style: GoogleFonts.sourceSerif4(fontSize: compact ? 13 : 15, color: cs.onSurface)),
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
  const ScrollDirectionItem({super.key, required this.onClose, this.compact = false});
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = ref.watch(scrollDirectionProvider);
    final isHorizontal = direction == Axis.horizontal;
    return PageOptionsToggleItem(
      icon: isHorizontal
          ? StarNoteIcons.scrollDirection
          : StarNoteIcons.scrollDirectionVertical,
      label: 'Kaydırma yönü',
      subtitle: isHorizontal ? 'Yatay' : 'Dikey',
      value: isHorizontal,
      onChanged: (v) => ref.read(scrollDirectionProvider.notifier).state =
          v ? Axis.horizontal : Axis.vertical,
      compact: compact,
    );
  }
}

// ═══════════════════════════════════════════
// Extracted helpers (shared with page_options_panel.dart)
// ═══════════════════════════════════════════

/// Chevron trailing widget with optional label (e.g. "3 / 10 >").
Widget pageOptionsChevronTrailing(ColorScheme cs, [String? label]) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    if (label != null) ...[
      Text(label, style: GoogleFonts.sourceSerif4(fontSize: 13, color: cs.onSurfaceVariant)),
      const SizedBox(width: 4),
    ],
    PhosphorIcon(StarNoteIcons.chevronRight, size: 18, color: cs.onSurfaceVariant),
  ]);
}

/// Thin divider between menu items.
Widget pageOptionsDivider(ColorScheme cs) =>
    Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);

/// Thick divider separating sections.
Widget pageOptionsThickDivider(ColorScheme cs, {bool compact = false}) =>
    Divider(
      height: compact ? 6 : 8,
      thickness: compact ? 6 : 8,
      color: cs.outlineVariant.withValues(alpha: 0.3),
    );

/// "Go to page" dialog extracted from PageOptionsPanel.
void showGoToPageDialog({
  required BuildContext context,
  required int pageCount,
  required PageManagerNotifier pageManager,
}) {
  final controller = TextEditingController();
  void goTo(String value, BuildContext ctx) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= pageCount) {
      Navigator.pop(ctx);
      pageManager.goToPage(page - 1);
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sayfaya Git'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(hintText: '1 - $pageCount'),
        onSubmitted: (v) => goTo(v, ctx),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(onPressed: () => goTo(controller.text, ctx), child: const Text('Git')),
      ],
    ),
  );
}

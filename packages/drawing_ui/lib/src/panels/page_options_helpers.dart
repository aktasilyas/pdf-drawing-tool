import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/page_rotation_service.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Shows a dialog letting the user choose a rotation angle.
Future<RotationAngle?> showRotatePageDialog(BuildContext context) {
  return showDialog<RotationAngle>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SimpleDialog(
        title: const Text('Sayfayı Döndür'),
        children: [
          _rotateOption(ctx, cs, ElyanotesIcons.rotateCW, 'Saat yönünde (90°)',
              RotationAngle.cw90),
          _rotateOption(ctx, cs, ElyanotesIcons.rotateCCW,
              'Saat yönünün tersine (90°)', RotationAngle.ccw90),
          _rotateOption(
              ctx, cs, ElyanotesIcons.rotateHalf, '180°', RotationAngle.half),
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
        const SizedBox(width: ChromeSpacing.lg),
        Text(label),
      ],
    ),
  );
}

// ═══════════════════════════════════════════
// Extracted helpers (shared with page_options_panel.dart)
// ═══════════════════════════════════════════

/// Chevron trailing widget with optional label (e.g. "3 / 10 >").
Widget pageOptionsChevronTrailing(ColorScheme cs,
    [String? label, TextTheme? textTheme]) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    if (label != null) ...[
      Text(label,
          style: textTheme?.bodySmall
              ?.copyWith(fontSize: 13, color: cs.onSurfaceVariant)),
      const SizedBox(width: ChromeSpacing.xs),
    ],
    PhosphorIcon(ElyanotesIcons.chevronRight,
        size: 18, color: cs.onSurfaceVariant),
  ]);
}

/// Thin divider between menu items with indent matching circular icon layout.
Widget pageOptionsDivider(ColorScheme cs, {bool compact = false}) => Divider(
      height: 0.5,
      thickness: 0.5,
      color: cs.outlineVariant,
      indent: compact ? 46 : 56,
    );

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
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(
            onPressed: () => goTo(controller.text, ctx),
            child: const Text('Git')),
      ],
    ),
  );
}

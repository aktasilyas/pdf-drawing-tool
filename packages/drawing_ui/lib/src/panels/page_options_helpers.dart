import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/go_to_page_dialog.dart';

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

/// "Go to page" from the page options menu: validated [GoToPageDialog],
/// then navigates [pageManager] to the chosen page.
void showGoToPageDialog({
  required BuildContext context,
  required int pageCount,
  required PageManagerNotifier pageManager,
}) {
  pickGoToPageIndex(context, pageCount: pageCount).then((index) {
    if (index != null) pageManager.goToPage(index);
  });
}

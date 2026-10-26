import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

/// 48dp panel header: title (titleSmall w600 textPrimary, one line,
/// ellipsis) and a [ChromeIconButton] close action
/// (docs/specs/52-editor-chrome.md, section 4).
class ChromePanelHeader extends StatelessWidget {
  const ChromePanelHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  /// Header height.
  static const double height = ChromeSizes.minTouchTarget;

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
            ),
          ),
          ChromeIconButton(
            icon: ElyanotesIcons.close,
            iconSize: ChromeIconSizes.md,
            tooltip: 'Kapat',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// 1dp `border` divider with `md` vertical breathing room.
class ChromeHairline extends StatelessWidget {
  const ChromeHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.md),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: ChromePalette.of(context).border),
      ),
    );
  }
}

/// Section label: labelMedium, w600, `textMuted`, `xs` bottom padding.
class ChromeSectionLabel extends StatelessWidget {
  const ChromeSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ChromeSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ChromePalette.of(context).textMuted,
            ),
      ),
    );
  }
}

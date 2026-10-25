import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

/// Navigation button for the editor toolbars; renders a [ChromeIconButton].
///
/// Used in [TopNavigationBar] and the toolbar nav sections. 40dp visual in a
/// 48dp hit area (docs/specs/52-editor-chrome.md, section 4). Active state
/// uses `accentContainer` + `accent`; colours come from [ChromePalette].
class ElyanotesNavButton extends StatelessWidget {
  const ElyanotesNavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.isDisabled = false,
    this.size = 36.0,
    this.iconSize,
    this.badge,
  });

  /// Phosphor icon to display.
  final IconData icon;

  /// Tooltip text shown on hover/long-press.
  final String tooltip;

  /// Callback when button is pressed.
  final VoidCallback onPressed;

  /// Whether this button is in active/selected state.
  final bool isActive;

  /// Whether this button is disabled (greyed out, not tappable).
  final bool isDisabled;

  /// Legacy visual size. No longer affects layout: every chrome button has
  /// a [ChromeIconButton.visualSize] visual in a 48dp hit area. Kept so
  /// existing callers compile.
  final double size;

  /// Override icon size (defaults to [ChromeIconSizes.lg]).
  final double? iconSize;

  /// Optional badge widget (e.g. notification dot), top-right of the visual.
  final Widget? badge;

  /// Inset of [badge] from the top-right corner of the 48dp hit area.
  static const double badgeInset = ChromeSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final button = ChromeIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      selected: isActive,
      enabled: !isDisabled,
      iconSize: iconSize ?? ChromeIconSizes.lg,
    );
    final badgeWidget = badge;
    if (badgeWidget == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: badgeInset,
          right: badgeInset,
          child: IgnorePointer(child: badgeWidget),
        ),
      ],
    );
  }
}

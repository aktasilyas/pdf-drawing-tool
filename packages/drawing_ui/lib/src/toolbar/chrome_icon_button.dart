import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Icon button for editor chrome (docs/specs/52-editor-chrome.md, section 4).
///
/// 48x48 hit area around a 40x40 visual, no ripple. States: idle
/// (transparent, `textMuted`), pressed (`textPrimary` 8%), selected
/// (`accentContainer` fill, `accent` icon, [selectedIcon]), disabled
/// (`textDisabled`) and keyboard focus (2dp `accent` ring). Colours come
/// from [ChromePalette].
class ChromeIconButton extends StatefulWidget {
  const ChromeIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.selected = false,
    this.enabled = true,
    this.iconSize = ChromeIconSizes.lg,
    this.inkDotColor,
    this.visualKey,
  });

  /// Visual edge of the button (the hit area is [ChromeSizes.minTouchTarget]).
  static const double visualSize = 40;

  /// Diameter of the ink-colour dot shown on the pen group.
  static const double inkDotSize = 8;

  /// Width of the `surface` ring around the ink dot.
  static const double inkDotRing = 1.5;

  /// Width of the keyboard focus ring.
  static const double focusRingWidth = 2;

  /// Alpha of the `textPrimary` overlay while pressed.
  static const double pressedAlpha = 0.08;

  /// Icon when idle (Phosphor Regular).
  final IconData icon;

  /// Icon when [selected] (Phosphor Fill); falls back to [icon].
  final IconData? selectedIcon;

  /// Tooltip and semantics label.
  final String tooltip;

  /// Called on tap or keyboard activation while [enabled].
  final VoidCallback onPressed;

  final bool selected;
  final bool enabled;

  /// [ChromeIconSizes.lg] in toolbars, [ChromeIconSizes.md] in panels.
  final double iconSize;

  /// When set, an ink dot of this colour sits bottom-right (pen group).
  final Color? inkDotColor;

  /// Key on the 40x40 visual, used to anchor popovers to the button.
  final Key? visualKey;

  @override
  State<ChromeIconButton> createState() => _ChromeIconButtonState();
}

class _ChromeIconButtonState extends State<ChromeIconButton> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  Color _fill(ChromePalette p) {
    final base = widget.selected && widget.enabled
        ? p.accentContainer
        : p.accentContainer.withValues(alpha: 0);
    if (!_pressed || !widget.enabled) return base;
    final overlay =
        p.textPrimary.withValues(alpha: ChromeIconButton.pressedAlpha);
    return Color.alphaBlend(overlay, base);
  }

  Color _iconColor(ChromePalette p) {
    if (!widget.enabled) return p.textDisabled;
    return widget.selected ? p.accent : p.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final enabled = widget.enabled;
    final icon = widget.selected && enabled
        ? (widget.selectedIcon ?? widget.icon)
        : widget.icon;
    final duration = _pressed ? ChromeDurations.instant : ChromeDurations.fast;

    Widget visual = AnimatedContainer(
      key: widget.visualKey,
      duration: duration,
      curve: Curves.easeOut,
      width: ChromeIconButton.visualSize,
      height: ChromeIconButton.visualSize,
      decoration: BoxDecoration(
        color: _fill(palette),
        borderRadius: BorderRadius.circular(ChromeRadius.md),
        border: _focused
            ? Border.all(
                color: palette.accent,
                width: ChromeIconButton.focusRingWidth,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        icon,
        size: widget.iconSize,
        color: _iconColor(palette),
      ),
    );

    final dotColor = widget.inkDotColor;
    if (dotColor != null) {
      visual = Stack(
        clipBehavior: Clip.none,
        children: [
          visual,
          Positioned(
            right: ChromeSpacing.xs,
            bottom: ChromeSpacing.xs,
            child: _InkDot(color: dotColor, ring: palette.surface),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.tooltip,
      onTap: enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: enabled ? widget.onPressed : null,
            child: SizedBox.square(
              dimension: ChromeSizes.minTouchTarget,
              child: Center(child: visual),
            ),
          ),
        ),
      ),
    );
  }
}

class _InkDot extends StatelessWidget {
  const _InkDot({required this.color, required this.ring});

  final Color color;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ChromeIconButton.inkDotSize + 2 * ChromeIconButton.inkDotRing,
      height: ChromeIconButton.inkDotSize + 2 * ChromeIconButton.inkDotRing,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: ChromeIconButton.inkDotRing),
      ),
    );
  }
}

/// Compact toggle widget for panel settings.
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Compact toggle (switch) with label.
///
/// Commonly used in tool settings panels for boolean options
/// like "Pressure sensitivity", "Auto-lift", etc.
///
/// Example:
/// ```dart
/// CompactToggle(
///   label: 'Basınç hassasiyeti',
///   value: isPressureSensitive,
///   onChanged: (value) => setState(() => isPressureSensitive = value),
/// )
/// ```
class CompactToggle extends StatelessWidget {
  const CompactToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.scale = 0.8,
  });

  /// Label text displayed next to the switch
  final String label;

  /// Current toggle value
  final bool value;

  /// Callback when value changes
  final ValueChanged<bool> onChanged;

  /// Active switch color (defaults to accent blue)
  final Color? activeColor;

  /// Scale factor for the switch (defaults to 0.8 for compact look)
  final double scale;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    void toggle() => onChanged(!value);

    // One node for the whole row ("<label>, switch, on"): the Text and the
    // Switch below are excluded, so TalkBack does not stop on each.
    return Semantics(
      container: true,
      label: label,
      toggled: value,
      enabled: true,
      excludeSemantics: true,
      onTap: toggle,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(minHeight: ChromeSizes.minTouchTarget),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: activeColor ?? palette.accent,
                  activeThumbColor: palette.onAccent,
                  inactiveThumbColor: palette.textMuted,
                  inactiveTrackColor: palette.surfaceElevated,
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.transparent
                        : palette.textMuted,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

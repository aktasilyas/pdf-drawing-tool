import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/chrome_tokens.dart';

/// Bold / italic / underline toggle of the [TextStylePopup].
///
/// A 48dp hit area around a 40dp visual, announced as one toggle button
/// labelled [semanticLabel].
class TextStyleToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final bool isSelected;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final VoidCallback onTap;

  const TextStyleToggleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    this.fontStyle,
    this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: ChromeSizes.minTouchTarget,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight:
                        label == 'B' ? FontWeight.bold : FontWeight.normal,
                    fontStyle: fontStyle,
                    decoration: decoration,
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';

/// Cancel / Done buttons at the bottom of the picker; each is at least
/// [ChromeSizes.minTouchTarget] tall.
class ColorPickerActions extends StatelessWidget {
  const ColorPickerActions({
    super.key,
    required this.onCancel,
    required this.onDone,
    required this.textColor,
    required this.primaryColor,
    required this.dividerColor,
  });

  final VoidCallback onCancel;
  final VoidCallback onDone;
  final Color textColor;
  final Color primaryColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final p = context.drawingStrings.panels;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: textColor,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChromeSpacing.lg,
        ChromeSpacing.xs,
        ChromeSpacing.lg,
        ChromeSpacing.sm,
      ),
      child: Row(children: [
        _button(p.colorCancel, style, onCancel),
        Container(width: 1, height: 20, color: dividerColor),
        _button(
          p.colorDone,
          style?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
          onDone,
        ),
      ]),
    );
  }

  Widget _button(String label, TextStyle? style, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: ChromeSizes.minTouchTarget),
            child: Center(child: Text(label, style: style)),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Compact visibility switch with a full 48dp hit area.
///
/// The switch keeps its small visual size (60% of a Material switch) while
/// the whole 48x48 square toggles it and carries the tool name as its
/// semantics label.
class CompactVisibilitySwitch extends StatelessWidget {
  const CompactVisibilitySwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  /// Visual scale of the switch inside the hit area.
  static const double _scale = 0.6;

  /// Semantics label: the name of the item this switch shows or hides.
  final String label;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      toggled: value,
      enabled: true,
      onTap: onToggle,
      child: InkResponse(
        onTap: onToggle,
        excludeFromSemantics: true,
        radius: kMinInteractiveDimension / 2,
        child: SizedBox.square(
          dimension: kMinInteractiveDimension,
          // The switch lays out at its natural size and is scaled down
          // visually; OverflowBox keeps that from squeezing it into 48dp.
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            // Only the 48dp square is interactive: one tap target,
            // one focus stop, one semantics node.
            child: ExcludeFocus(
              child: IgnorePointer(
                child: Transform.scale(
                  scale: _scale,
                  child: Switch(
                    value: value,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: cs.primary,
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

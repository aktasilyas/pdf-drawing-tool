import 'package:flutter/material.dart';

/// GoodNotes-style stepped slider with dot tick marks.
///
/// Features:
/// - Uppercase label + percentage value header
/// - Track with visible dot markers at each step
/// - Active dots colored [activeColor], inactive grey
/// - Larger thumb circle
class GoodNotesSlider extends StatelessWidget {
  const GoodNotesSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.activeColor,
    required this.onChanged,
    this.divisions = 8,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final int divisions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        )),
        Text(displayValue, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        )),
      ]),
      const SizedBox(height: 2),
      SizedBox(
        height: 32,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: activeColor,
            inactiveTrackColor: cs.outlineVariant.withValues(alpha: 0.4),
            thumbColor: activeColor,
            activeTickMarkColor: activeColor,
            inactiveTickMarkColor: cs.outlineVariant,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }
}

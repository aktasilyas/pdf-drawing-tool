import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// Chrome slider: label and tabular value header above a continuous track.
///
/// Track 4dp, thumb 20dp, 48dp hit height, no step ticks (docs/specs/
/// 52-editor-chrome.md, section 4). Colours come from [ChromePalette];
/// [activeColor] tints the filled track and thumb. Pass [divisions] only for
/// values that must snap; defaults to 8 steps (no tick marks), pass null for
/// a continuous value.
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

  /// Track thickness.
  static const double trackHeight = 4;

  /// Thumb diameter.
  static const double thumbSize = 20;

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  /// Optional snapping; null means continuous. Never draws tick marks.
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: labelStyle?.copyWith(color: palette.textMuted),
              ),
            ),
            const SizedBox(width: ChromeSpacing.sm),
            Text(
              displayValue,
              style: labelStyle?.copyWith(
                color: palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(
          height: ChromeSizes.minTouchTarget,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: thumbSize / 2,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: ChromeSizes.minTouchTarget / 2,
              ),
              overlayColor: activeColor.withValues(alpha: 0.12),
              activeTrackColor: activeColor,
              inactiveTrackColor: palette.border,
              thumbColor: activeColor,
              tickMarkShape: SliderTickMarkShape.noTickMark,
              trackShape: const RoundedRectSliderTrackShape(),
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
      ],
    );
  }
}

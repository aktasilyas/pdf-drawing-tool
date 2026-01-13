import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Shape options for thickness preview.
enum ThicknessPreviewShape {
  circle,
  rectangle,
}

/// A slider for adjusting stroke thickness.
///
/// Displays a visual preview of the thickness and allows fine-grained control.
class ThicknessSlider extends StatelessWidget {
  const ThicknessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.5,
    this.max = 50.0,
    this.label,
    this.previewColor,
    this.showPreview = true,
    this.previewShape = ThicknessPreviewShape.circle,
  });

  /// Current thickness value.
  final double value;

  /// Callback when thickness changes.
  final ValueChanged<double> onChanged;

  /// Minimum thickness value.
  final double min;

  /// Maximum thickness value.
  final double max;

  /// Optional label to display above the slider.
  final String? label;

  /// Color for the preview (defaults to black).
  final Color? previewColor;

  /// Whether to show the thickness preview.
  final bool showPreview;

  /// Shape of the preview indicator.
  final ThicknessPreviewShape previewShape;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final color = previewColor ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (showPreview)
              SizedBox(
                width: max + 8, // Max preview size + padding
                height: max + 8,
                child: Center(
                  child: previewShape == ThicknessPreviewShape.circle
                      ? Container(
                          width: value,
                          height: value,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: value * 1.5,
                          height: value * 0.4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                ),
              ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: theme.sliderTrackHeight,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  activeTrackColor: theme.toolbarIconSelectedColor,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: theme.toolbarIconSelectedColor,
                  overlayColor: theme.toolbarIconSelectedColor.withAlpha(32),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A slider for adjusting stabilization.
class StabilizationSlider extends StatelessWidget {
  const StabilizationSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current stabilization value (0.0 to 1.0).
  final double value;

  /// Callback when stabilization changes.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stabilization',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: theme.sliderTrackHeight,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20,
            ),
            activeTrackColor: theme.toolbarIconSelectedColor,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: theme.toolbarIconSelectedColor,
            overlayColor: theme.toolbarIconSelectedColor.withAlpha(32),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

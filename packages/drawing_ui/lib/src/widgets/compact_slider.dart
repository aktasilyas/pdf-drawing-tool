/// Compact slider widget for panel settings.
import 'package:flutter/material.dart';

/// Compact slider with inline title and value label.
///
/// Commonly used in tool settings panels for adjusting numeric values
/// like thickness, opacity, duration, etc.
///
/// Example:
/// ```dart
/// CompactSlider(
///   title: 'KALINLIK',
///   value: thickness,
///   min: 1.0,
///   max: 20.0,
///   label: '${thickness.toInt()} pt',
///   onChanged: (value) => setState(() => thickness = value),
/// )
/// ```
class CompactSlider extends StatelessWidget {
  const CompactSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbRadius = 6.0,
    this.trackHeight = 3.0,
    this.height = 18.0,
  });

  /// Title label displayed above the slider
  final String title;

  /// Current slider value
  final double value;

  /// Minimum slider value
  final double min;

  /// Maximum slider value
  final double max;

  /// Value label displayed next to title
  final String label;

  /// Callback when value changes
  final ValueChanged<double> onChanged;

  /// Active track color (defaults to accent blue)
  final Color? activeColor;

  /// Inactive track color (defaults to light grey)
  final Color? inactiveColor;

  /// Thumb radius (defaults to 6.0)
  final double thumbRadius;

  /// Track height (defaults to 3.0)
  final double trackHeight;

  /// Slider container height (defaults to 18.0)
  final double height;

  static const _defaultActiveColor = Color(0xFF4A9DFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and value label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Slider
        SizedBox(
          height: height,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
              overlayShape: RoundSliderOverlayShape(overlayRadius: thumbRadius * 2),
              activeTrackColor: activeColor ?? _defaultActiveColor,
              inactiveTrackColor: inactiveColor ?? Colors.grey.shade200,
              thumbColor: activeColor ?? _defaultActiveColor,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

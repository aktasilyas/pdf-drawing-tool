/// Compact toggle widget for panel settings.
import 'package:flutter/material.dart';

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
    this.scale = 0.65,
  });

  /// Label text displayed next to the switch
  final String label;

  /// Current toggle value
  final bool value;

  /// Callback when value changes
  final ValueChanged<bool> onChanged;

  /// Active switch color (defaults to accent blue)
  final Color? activeColor;

  /// Scale factor for the switch (defaults to 0.65 for compact look)
  final double scale;

  static const _defaultActiveColor = Color(0xFF4A9DFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF444444),
              ),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor ?? _defaultActiveColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

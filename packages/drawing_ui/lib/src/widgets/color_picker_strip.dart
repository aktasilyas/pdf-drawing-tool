import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';

const double _pickerMaxWidth = 320;

/// Horizontal scrollable colour strip with a "+" button that opens
/// [CompactColorPicker].
///
/// Swatches are [chipSize] (32dp) inside 48dp cells. The selected swatch gets
/// a 2dp `accent` ring separated by a 2dp gap (docs/specs/52-editor-chrome.md,
/// section 4). Colours come from [ChromePalette].
class ColorPickerStrip extends StatelessWidget {
  const ColorPickerStrip({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors,
    this.chipSize = 32.0,
    this.isHighlighter = false,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  /// Colors to display. Defaults to [ColorPresets.popular20].
  final List<Color>? colors;

  /// Diameter of each colour swatch.
  final double chipSize;

  /// When true, CompactColorPicker shows opacity slider.
  final bool isHighlighter;

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? ColorPresets.popular20;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final color in palette)
                  _ColorSwatch(
                    color: color,
                    size: chipSize,
                    isSelected: _colorsMatch(color, selectedColor),
                    onTap: () => onColorSelected(color),
                  ),
              ],
            ),
          ),
        ),
        ChromeIconButton(
          icon: ElyanotesIcons.plus,
          iconSize: ChromeIconSizes.md,
          tooltip: 'Renk ekle',
          onPressed: () => _showColorPalette(context),
        ),
      ],
    );
  }

  void _showColorPalette(BuildContext context) {
    final overlay = Overlay.of(context);
    final scrim = ChromePalette.of(context).textPrimary.withValues(alpha: 0.12);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: scrim,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => overlayEntry.remove(),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _pickerMaxWidth,
                    maxHeight: MediaQuery.of(overlayContext).size.height * 0.85,
                  ),
                  child: CompactColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (color) {
                      onColorSelected(color);
                      overlayEntry.remove();
                    },
                    showOpacity: isHighlighter,
                    onClose: () => overlayEntry.remove(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  static bool _colorsMatch(Color a, Color b) {
    return (a.r * 255.0).round().clamp(0, 255) ==
            (b.r * 255.0).round().clamp(0, 255) &&
        (a.g * 255.0).round().clamp(0, 255) ==
            (b.g * 255.0).round().clamp(0, 255) &&
        (a.b * 255.0).round().clamp(0, 255) ==
            (b.b * 255.0).round().clamp(0, 255);
  }
}

/// Round swatch in a 48dp cell; selected = accent ring + gap.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  static const double _ring = 2;
  static const double _gap = 2;

  final Color color;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    const inset = _ring + _gap;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Renk',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: ChromeSizes.minTouchTarget,
          child: Center(
            child: Container(
              width: size + 2 * inset,
              height: size + 2 * inset,
              padding: const EdgeInsets.all(_gap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? palette.accent : Colors.transparent,
                  width: _ring,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

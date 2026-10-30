import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/recent_colors_provider.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/color_picker_logic.dart';
import 'package:drawing_ui/src/widgets/color_swatch_target.dart';

/// Recent-colour slots (newest first) + eyedropper glyph.
///
/// Each filled slot is a [ChromeSizes.minTouchTarget] hit area around a 32dp
/// swatch announced by [ColorSwatchTarget]; the outer padding is reduced by the same amount so the swatches
/// keep their 16dp inset from the panel edge.
class ColorPickerRecentRow extends ConsumerWidget {
  const ColorPickerRecentRow({
    super.key,
    required this.onColorSelected,
    required this.outlineColor,
    required this.iconColor,
    this.selectedColor,
  });

  final ValueChanged<Color> onColorSelected;
  final Color outlineColor;
  final Color iconColor;

  /// Current picker colour; the matching slot reports `selected`.
  final Color? selectedColor;

  static const double _swatchSize = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ColorPickerLogic.recentSlots(ref.watch(recentColorsProvider));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.sm),
      child: Row(children: [
        for (var i = 0; i < slots.length; i++) _slot(i, slots[i]),
        const Spacer(),
        Container(
          width: _swatchSize,
          height: _swatchSize,
          margin: const EdgeInsets.only(right: ChromeSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: outlineColor),
          ),
          child: PhosphorIcon(ElyanotesIcons.colorize,
              size: ChromeIconSizes.sm, color: iconColor),
        ),
      ]),
    );
  }

  Widget _slot(int index, Color? color) {
    final swatch = Container(
      width: _swatchSize,
      height: _swatchSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: color == null
              ? outlineColor
              : outlineColor.withValues(alpha: 0.5),
        ),
      ),
    );
    if (color == null) {
      return SizedBox.square(
        dimension: ChromeSizes.minTouchTarget,
        child: Center(child: swatch),
      );
    }
    return ColorSwatchTarget(
      key: ValueKey('recentColorSlot$index'),
      color: color,
      isSelected: selectedColor != null &&
          color.toARGB32() == selectedColor!.toARGB32(),
      onTap: () => onColorSelected(color),
      child: swatch,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/chrome_roles.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/color_swatch_target.dart';

/// Ortak renk seçici widget - hızlı renkler + daha fazla butonu
class UnifiedColorPicker extends StatelessWidget {
  const UnifiedColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.quickColors,
    this.allColors,
    this.colorSets,
    this.showMoreButton = true,
    this.chipSize = 22.0,
    this.spacing = 6.0,
    this.isHighlighter = false,
    this.compactMoreButton = false,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final List<Color>? quickColors;
  final List<Color>? allColors;
  final Map<String, List<Color>>? colorSets;
  final bool showMoreButton;
  final double chipSize;
  final double spacing;
  final bool isHighlighter;

  /// Shows "more" as a swatch-sized palette dot (label kept for screen
  /// readers) instead of the labelled chip, so narrow popovers fit one row.
  final bool compactMoreButton;

  @override
  Widget build(BuildContext context) {
    final colors = (quickColors ?? ColorPresets.quickAccess).take(5).toList();

    // Each swatch sits in a 48dp hit area, which already leaves
    // (48 - chipSize) between the visuals; only add what is missing.
    final gap =
        (spacing - (ChromeSizes.minTouchTarget - chipSize)).clamp(0.0, spacing);

    return Wrap(
      spacing: gap,
      runSpacing: 0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...colors.map((color) => _ColorChip(
              color: color,
              isSelected: _colorsMatch(color, selectedColor),
              size: chipSize,
              onTap: () => onColorSelected(color),
              onDoubleTap: () => _showColorPalette(context),
            )),
        if (showMoreButton)
          _MoreButton(
            onTap: () => _showColorPalette(context),
            compactSize: compactMoreButton ? chipSize : null,
          ),
      ],
    );
  }

  void _showColorPalette(BuildContext context) {
    // Use custom full-screen overlay for color picker
    // This ensures it appears above all panels and is centered on screen
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: Theme.of(overlayContext)
              .colorScheme
              .scrim
              .withValues(alpha: 0.54),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => overlayEntry.remove(),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Absorb taps on picker
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 320,
                    maxHeight: MediaQuery.of(overlayContext).size.height * 0.85,
                  ),
                  child: CompactColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (color) {
                      onColorSelected(color);
                      overlayEntry.remove();
                    },
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

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255.0).round().clamp(0, 255) ==
            (b.r * 255.0).round().clamp(0, 255) &&
        (a.g * 255.0).round().clamp(0, 255) ==
            (b.g * 255.0).round().clamp(0, 255) &&
        (a.b * 255.0).round().clamp(0, 255) ==
            (b.b * 255.0).round().clamp(0, 255);
  }
}

/// Tek bir renk chip'i
class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.size,
    required this.onTap,
    this.onDoubleTap,
  });

  final Color color;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColorSwatchTarget(
      color: color,
      isSelected: isSelected,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : (color.computeLuminance() > 0.8
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? PhosphorIcon(
                ElyanotesIcons.check,
                size: size * 0.5,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// "Daha fazla" butonu
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap, this.compactSize});

  final VoidCallback onTap;

  /// When set, renders a palette dot of this diameter instead of the chip.
  final double? compactSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.drawingStrings.selection.more,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ChromeSizes.minTouchTarget,
            minHeight: ChromeSizes.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: compactSize == null
                ? _moreChip(context)
                : _morePaletteDot(context, compactSize!),
          ),
        ),
      ),
    );
  }

  Widget _morePaletteDot(BuildContext context, double size) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.chipSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: PhosphorIcon(
        ElyanotesIcons.palette,
        size: size * 0.6,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _moreChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.chipSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            ElyanotesIcons.palette,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            context.drawingStrings.selection.more,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Full palette sheet (for compatibility)
class ColorPaletteSheet extends StatelessWidget {
  const ColorPaletteSheet({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colorSets,
    this.allColors,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final Map<String, List<Color>>? colorSets;
  final List<Color>? allColors;

  @override
  Widget build(BuildContext context) {
    return CompactColorPicker(
      selectedColor: selectedColor,
      onColorSelected: onColorSelected,
    );
  }
}

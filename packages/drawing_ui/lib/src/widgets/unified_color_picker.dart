import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = (quickColors ?? ColorPresets.quickAccess).take(5).toList();

    return Wrap(
      spacing: spacing,
      runSpacing: 4,
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
          color: Colors.black.withValues(alpha: 137.0 / 255.0), // 0.54 opacity for stronger backdrop
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
    return (a.r * 255.0).round().clamp(0, 255) == (b.r * 255.0).round().clamp(0, 255) && 
        (a.g * 255.0).round().clamp(0, 255) == (b.g * 255.0).round().clamp(0, 255) && 
        (a.b * 255.0).round().clamp(0, 255) == (b.b * 255.0).round().clamp(0, 255);
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
    
    return GestureDetector(
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
                StarNoteIcons.check,
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
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              StarNoteIcons.palette,
              size: 12,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 3),
            Text(
              'Daha fazla',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
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

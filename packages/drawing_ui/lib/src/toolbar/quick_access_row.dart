import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';

/// Quick access row for changing color and thickness without opening panels.
///
/// Shows 5 color chips and 3 thickness dots.
/// Only visible when a drawing tool (pen/highlighter) is selected.
class QuickAccessRow extends ConsumerWidget {
  const QuickAccessRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);

    // Only show for drawing tools
    if (!_isDrawingTool(currentTool)) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick colors
        QuickColorChips(currentTool: currentTool),
        const SizedBox(width: 6),
        // Separator
        Container(
          width: 1,
          height: 20,
          color: Colors.grey.shade300,
        ),
        const SizedBox(width: 6),
        // Quick thickness
        QuickThicknessDots(currentTool: currentTool),
      ],
    );
  }

  bool _isDrawingTool(ToolType tool) {
    // Use the isPenTool getter from ToolType
    // Note: neonHighlighter.isPenTool returns true, so it's covered
    return tool.isPenTool || tool == ToolType.highlighter || tool == ToolType.neonHighlighter;
  }
}

/// Quick color selection chips.
class QuickColorChips extends ConsumerWidget {
  const QuickColorChips({
    super.key,
    required this.currentTool,
  });

  final ToolType currentTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vurgulayıcı için farklı renkler kullan
    final isHighlighter = currentTool == ToolType.highlighter || currentTool == ToolType.neonHighlighter;
    final colors = isHighlighter
        ? ColorSets.highlighter.take(5).toList()
        : ColorSets.quickAccess.take(5).toList();
    final selectedColor = _getSelectedColor(ref);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...colors.map((color) {
          final isSelected = _colorsMatch(color, selectedColor);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _QuickColorChip(
              color: color,
              isSelected: isSelected,
              onTap: () => _setColor(ref, color),
              onDoubleTap: () => _showColorPalette(context, ref, selectedColor),
            ),
          );
        }),
        // "Daha fazla" butonu
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => _showColorPalette(context, ref, selectedColor),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: const Icon(Icons.more_horiz, size: 14, color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSelectedColor(WidgetRef ref) {
    if (currentTool == ToolType.highlighter || currentTool == ToolType.neonHighlighter) {
      return ref.watch(highlighterSettingsProvider).color;
    }
    return ref.watch(penSettingsProvider(currentTool)).color;
  }

  void _setColor(WidgetRef ref, Color color) {
    if (currentTool == ToolType.highlighter || currentTool == ToolType.neonHighlighter) {
      // For highlighter, apply alpha for transparency (less for neon)
      final alpha = currentTool == ToolType.neonHighlighter ? 200 : 128;
      final highlighterColor = color.withAlpha(alpha);
      ref.read(highlighterSettingsProvider.notifier).setColor(highlighterColor);
    } else {
      ref.read(penSettingsProvider(currentTool).notifier).setColor(color);
    }
  }

  void _showColorPalette(BuildContext context, WidgetRef ref, Color selectedColor) {
    final isHighlighter = currentTool == ToolType.highlighter || currentTool == ToolType.neonHighlighter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ColorPaletteSheet(
        selectedColor: selectedColor,
        onColorSelected: (color) {
          _setColor(ref, color);
          Navigator.pop(ctx);
        },
        colorSets: isHighlighter
            ? {'Vurgulayıcı': ColorSets.highlighter, 'Pastel': ColorSets.pastel}
            : ColorSets.all,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    // Compare RGB only (ignore alpha for highlighter comparison)
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }
}

/// A single quick color chip.
class _QuickColorChip extends StatelessWidget {
  const _QuickColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// Quick thickness selection dots.
class QuickThicknessDots extends ConsumerWidget {
  const QuickThicknessDots({
    super.key,
    required this.currentTool,
  });

  final ToolType currentTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DrawingTheme.of(context);
    final thicknesses = ref.watch(quickThicknessProvider);
    final selectedThickness = _getSelectedThickness(ref);
    final toolColor = _getToolColor(ref);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: thicknesses.asMap().entries.map((entry) {
        final index = entry.key;
        final thickness = entry.value;
        final isSelected = _thicknessMatches(thickness, selectedThickness);

        // Scale dot sizes: small, medium, large
        final dotSize = 8.0 + (index * 4.0); // 8, 12, 16

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _QuickThicknessDot(
            size: dotSize,
            thickness: thickness,
            color: toolColor,
            isSelected: isSelected,
            selectedColor: theme.toolbarIconSelectedColor,
            onTap: () => _setThickness(ref, thickness),
          ),
        );
      }).toList(),
    );
  }

  bool get _isHighlighter => currentTool == ToolType.highlighter || currentTool == ToolType.neonHighlighter;

  double _getSelectedThickness(WidgetRef ref) {
    if (_isHighlighter) {
      return ref.watch(highlighterSettingsProvider).thickness;
    }
    return ref.watch(penSettingsProvider(currentTool)).thickness;
  }

  Color _getToolColor(WidgetRef ref) {
    if (_isHighlighter) {
      return ref.watch(highlighterSettingsProvider).color;
    }
    return ref.watch(penSettingsProvider(currentTool)).color;
  }

  void _setThickness(WidgetRef ref, double thickness) {
    if (_isHighlighter) {
      // Scale up for highlighter (highlighter is typically thicker)
      final highlighterThickness = thickness * 4;
      ref
          .read(highlighterSettingsProvider.notifier)
          .setThickness(highlighterThickness);
    } else {
      ref.read(penSettingsProvider(currentTool).notifier).setThickness(thickness);
    }
  }

  bool _thicknessMatches(double a, double b) {
    // For highlighter, compare scaled values
    if (_isHighlighter) {
      return (a * 4 - b).abs() < 0.1;
    }
    return (a - b).abs() < 0.1;
  }
}

/// A single quick thickness dot.
class _QuickThicknessDot extends StatelessWidget {
  const _QuickThicknessDot({
    required this.size,
    required this.thickness,
    required this.color,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final double size;
  final double thickness;
  final Color color;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: selectedColor, width: 1.5)
              : null,
          color: isSelected ? selectedColor.withAlpha(15) : Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : color.withAlpha(150),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

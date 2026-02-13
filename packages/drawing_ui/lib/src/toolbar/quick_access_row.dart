import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/quick_thickness_chips.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';

/// Quick access row for changing color and thickness without opening panels.
///
/// Shows 5 color chips (24dp) and 3 thickness line previews.
/// Only visible when a drawing tool (pen/highlighter) is selected.
class QuickAccessRow extends ConsumerWidget {
  const QuickAccessRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);

    if (!_isDrawingTool(currentTool)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuickColorChips(currentTool: currentTool),
        const SizedBox(width: 6),
        Container(
          width: 1,
          height: 20,
          color: colorScheme.outlineVariant,
        ),
        const SizedBox(width: 6),
        QuickThicknessChips(currentTool: currentTool),
      ],
    );
  }

  bool _isDrawingTool(ToolType tool) {
    return tool.isPenTool ||
        tool == ToolType.highlighter ||
        tool == ToolType.neonHighlighter;
  }
}

/// Quick color selection chips (24dp circles).
class QuickColorChips extends ConsumerWidget {
  const QuickColorChips({
    super.key,
    required this.currentTool,
  });

  final ToolType currentTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighlighter = currentTool == ToolType.highlighter ||
        currentTool == ToolType.neonHighlighter;
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
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _QuickColorChip(
              color: color,
              isSelected: isSelected,
              onTap: () => _setColor(ref, color),
              onDoubleTap: () => _showColorPalette(context, ref, selectedColor),
            ),
          );
        }),
        // "More colors" button
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Tooltip(
            message: 'Daha Fazla Renk',
            child: Semantics(
              label: 'Daha Fazla Renk',
              button: true,
              child: GestureDetector(
                onTap: () => _showColorPalette(context, ref, selectedColor),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  child: PhosphorIcon(
                    StarNoteIcons.more,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                    semanticLabel: 'Daha Fazla Renk',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSelectedColor(WidgetRef ref) {
    if (currentTool == ToolType.highlighter ||
        currentTool == ToolType.neonHighlighter) {
      return ref.watch(highlighterSettingsProvider).color;
    }
    return ref.watch(penSettingsProvider(currentTool)).color;
  }

  void _setColor(WidgetRef ref, Color color) {
    if (currentTool == ToolType.highlighter ||
        currentTool == ToolType.neonHighlighter) {
      final alpha = currentTool == ToolType.neonHighlighter ? 200 : 128;
      final highlighterColor = color.withValues(alpha: alpha / 255.0);
      ref.read(highlighterSettingsProvider.notifier).setColor(highlighterColor);
    } else {
      ref.read(penSettingsProvider(currentTool).notifier).setColor(color);
    }
  }

  void _showColorPalette(
      BuildContext context, WidgetRef ref, Color selectedColor) {
    final isHighlighter = currentTool == ToolType.highlighter ||
        currentTool == ToolType.neonHighlighter;
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
            ? {
                'Vurgulayıcı': ColorSets.highlighter,
                'Pastel': ColorSets.pastel,
              }
            : ColorSets.all,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

/// A single 24dp color chip with selection indicator.
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

  String _colorHex(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = isSelected
        ? 'Seçili renk ${_colorHex(color)}'
        : 'Renk ${_colorHex(color)}';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : color.computeLuminance() > 0.8
                        ? colorScheme.outlineVariant
                        : Colors.transparent,
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? PhosphorIcon(
                    StarNoteIcons.check,
                    size: 12,
                    color: color.computeLuminance() > 0.5
                        ? colorScheme.onSurface
                        : Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}


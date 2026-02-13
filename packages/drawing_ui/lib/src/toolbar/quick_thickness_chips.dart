import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Quick thickness selection with line preview chips.
class QuickThicknessChips extends ConsumerWidget {
  const QuickThicknessChips({
    super.key,
    required this.currentTool,
  });

  final ToolType currentTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thicknesses = ref.watch(quickThicknessProvider);
    final selectedThickness = _getSelectedThickness(ref);
    final toolColor = _getToolColor(ref);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: thicknesses.map((thickness) {
        final isSelected = _thicknessMatches(thickness, selectedThickness);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: QuickThicknessChip(
            thickness: thickness,
            currentColor: toolColor,
            isSelected: isSelected,
            onTap: () => _setThickness(ref, thickness),
          ),
        );
      }).toList(),
    );
  }

  bool get _isHighlighter =>
      currentTool == ToolType.highlighter ||
      currentTool == ToolType.neonHighlighter;

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
      final highlighterThickness = thickness * 4;
      ref
          .read(highlighterSettingsProvider.notifier)
          .setThickness(highlighterThickness);
    } else {
      ref
          .read(penSettingsProvider(currentTool).notifier)
          .setThickness(thickness);
    }
  }

  bool _thicknessMatches(double a, double b) {
    if (_isHighlighter) {
      return (a * 4 - b).abs() < 0.1;
    }
    return (a - b).abs() < 0.1;
  }
}

/// A single thickness chip showing a horizontal line preview.
class QuickThicknessChip extends StatelessWidget {
  const QuickThicknessChip({
    super.key,
    required this.thickness,
    required this.currentColor,
    required this.isSelected,
    required this.onTap,
  });

  final double thickness;
  final Color currentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Map thickness to 1-6dp visual height
    final visualThickness = (thickness * 0.8).clamp(1.0, 6.0);
    final label = 'Kalınlık ${thickness.toStringAsFixed(1)}';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: visualThickness,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(visualThickness / 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

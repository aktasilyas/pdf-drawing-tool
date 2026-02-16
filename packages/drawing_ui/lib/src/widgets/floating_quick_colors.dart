import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';

/// Floating vertical color strip shown when pen or highlighter is active.
/// Contains scrollable quick-access colors and a palette button for the
/// full color picker overlay.
class FloatingQuickColors extends ConsumerWidget {
  const FloatingQuickColors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final isPen = penToolsSet.contains(currentTool);
    final isHighlighter = highlighterToolsSet.contains(currentTool);
    final isLaser = currentTool == ToolType.laserPointer;

    if (!isPen && !isHighlighter && !isLaser) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }

    final colors = isLaser
        ? ColorSets.laser
        : isPen
            ? ColorPresets.quickAccess
            : ColorPresets.highlighter;
    final currentColor = isLaser
        ? ref.watch(laserSettingsProvider).color
        : isPen
            ? ref.watch(penSettingsProvider(currentTool)).color
            : ref.watch(highlighterSettingsProvider).color;
    final currentThickness = isLaser
        ? ref.watch(laserSettingsProvider).thickness
        : isPen
            ? ref.watch(penSettingsProvider(currentTool)).thickness
            : ref.watch(highlighterSettingsProvider).thickness;
    final thicknesses = ref.watch(quickThicknessProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 16,
      top: 80,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: colorScheme.outlineVariant)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thickness lines
            ...thicknesses.map((t) => _ThicknessLine(
                  thickness: t,
                  isSelected: (currentThickness - t).abs() < 0.01,
                  color: currentColor,
                  onTap: () => _onThicknessTap(
                    ref, t, currentTool, isPen,
                  ),
                )),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            // Quick-access color chips
            ...colors.map((color) => _ColorDot(
                  color: color,
                  isSelected: _isColorSelected(
                    color, currentColor, isHighlighter,
                  ),
                  onTap: () => _onQuickColorTap(
                    ref, color, currentTool, isPen,
                  ),
                )),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            // Palette button → opens full color picker
            _PaletteButton(
              currentColor: currentColor,
              isHighlighter: isHighlighter,
              onColorSelected: (color) {
                // Color picker returns color with user-chosen opacity
                if (isLaser) {
                  ref.read(laserSettingsProvider.notifier).setColor(color);
                } else if (isPen) {
                  ref.read(penSettingsProvider(currentTool).notifier)
                      .setColor(color);
                } else {
                  ref.read(highlighterSettingsProvider.notifier)
                      .setColor(color);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isColorSelected(Color preset, Color current, bool isHighlighter) {
    if (isHighlighter) {
      // Compare RGB only — highlighter colors carry alpha
      return preset.r == current.r
          && preset.g == current.g
          && preset.b == current.b;
    }
    return preset == current;
  }

  void _onThicknessTap(
    WidgetRef ref, double thickness, ToolType tool, bool isPen,
  ) {
    if (tool == ToolType.laserPointer) {
      ref.read(laserSettingsProvider.notifier).setThickness(thickness);
    } else if (isPen) {
      ref.read(penSettingsProvider(tool).notifier).setThickness(thickness);
    } else {
      ref.read(highlighterSettingsProvider.notifier).setThickness(thickness);
    }
  }

  void _onQuickColorTap(
    WidgetRef ref, Color color, ToolType tool, bool isPen,
  ) {
    if (tool == ToolType.laserPointer) {
      ref.read(laserSettingsProvider.notifier).setColor(color);
    } else if (isPen) {
      ref.read(penSettingsProvider(tool).notifier).setColor(color);
    } else {
      // Apply standard highlighter transparency for quick colors
      ref.read(highlighterSettingsProvider.notifier).setColor(
        color.withValues(alpha: 0.5),
      );
    }
  }
}

/// Horizontal line representing a pen thickness option.
class _ThicknessLine extends StatelessWidget {
  const _ThicknessLine({
    required this.thickness,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final double thickness;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Container(
          width: 26,
          height: 20,
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Center(
            child: Container(
              width: 18,
              height: thickness.clamp(1.0, 5.0),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                borderRadius: BorderRadius.circular(thickness / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single color chip in the quick-access strip.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = color.computeLuminance() < 0.4;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: isDark ? Colors.white : Colors.black,
                )
              : null,
        ),
      ),
    );
  }
}

/// Palette icon that opens the full [CompactColorPicker] as an overlay.
class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.currentColor,
    required this.isHighlighter,
    required this.onColorSelected,
  });

  final Color currentColor;
  final bool isHighlighter;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showColorPicker(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: PhosphorIcon(
            StarNoteIcons.palette,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Material(
        color: Colors.black.withValues(alpha: 137.0 / 255.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => entry.remove(),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Absorb taps on picker
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 320,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: CompactColorPicker(
                  selectedColor: currentColor,
                  showOpacity: isHighlighter,
                  onColorSelected: (color) {
                    onColorSelected(color);
                    entry.remove();
                  },
                  onClose: () => entry.remove(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';

/// Laser pointer settings content for popover panel.
class LaserPointerPanel extends ConsumerWidget {
  const LaserPointerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(laserSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lazer işaretleyici', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          _LaserModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (m) =>
                ref.read(laserSettingsProvider.notifier).setMode(m),
          ),
          const SizedBox(height: 12),
          _GoodNotesSlider(
            label: 'KALINLIK', activeColor: settings.color,
            value: settings.thickness, min: 0.5, max: 5.0,
            displayValue: '${settings.thickness.toStringAsFixed(1)}mm',
            onChanged: (v) =>
                ref.read(laserSettingsProvider.notifier).setThickness(v),
          ),
          const SizedBox(height: 8),
          _GoodNotesSlider(
            label: 'SÜRE', activeColor: cs.primary,
            value: settings.duration, min: 0.5, max: 5.0,
            displayValue: '${settings.duration.toStringAsFixed(1)}s',
            onChanged: (v) =>
                ref.read(laserSettingsProvider.notifier).setDuration(v),
          ),
          const SizedBox(height: 12),
          Text('RENK', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: cs.onSurfaceVariant,
              letterSpacing: 0.5)),
          const SizedBox(height: 6),
          UnifiedColorPicker(
            selectedColor: settings.color,
            onColorSelected: (c) =>
                ref.read(laserSettingsProvider.notifier).setColor(c),
            quickColors: ColorSets.laser,
            colorSets: const {'Lazer': ColorSets.laser, 'Neon': ColorSets.neon},
            chipSize: 26.0, spacing: 8.0,
          ),
        ],
      ),
    );
  }
}

/// GoodNotes-style slider: uppercase label + value + compact slider.
class _GoodNotesSlider extends StatelessWidget {
  const _GoodNotesSlider({
    required this.label, required this.value, required this.min,
    required this.max, required this.displayValue,
    required this.activeColor, required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final String displayValue;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant, letterSpacing: 0.5)),
        Text(displayValue, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w500, color: cs.onSurface)),
      ]),
      const SizedBox(height: 2),
      SizedBox(height: 28, child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: activeColor,
          inactiveTrackColor: cs.surfaceContainerHighest,
          thumbColor: activeColor,
        ),
        child: Slider(value: value.clamp(min, max), min: min, max: max,
            onChanged: onChanged),
      )),
    ]);
  }
}

/// Selector for laser pointer modes.
class _LaserModeSelector extends StatelessWidget {
  const _LaserModeSelector({
    required this.selectedMode, required this.onModeSelected,
  });
  final LaserMode selectedMode;
  final ValueChanged<LaserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _LaserModeOption(
        mode: LaserMode.line, icon: StarNoteIcons.chartLine,
        label: 'Çizgi', isSelected: selectedMode == LaserMode.line,
        onTap: () => onModeSelected(LaserMode.line),
      )),
      const SizedBox(width: 8),
      Expanded(child: _LaserModeOption(
        mode: LaserMode.dot, icon: StarNoteIcons.circle,
        label: 'Nokta', isSelected: selectedMode == LaserMode.dot,
        onTap: () => onModeSelected(LaserMode.dot),
      )),
    ]);
  }
}

/// A single laser mode option button.
class _LaserModeOption extends StatelessWidget {
  const _LaserModeOption({
    required this.mode, required this.icon, required this.label,
    required this.isSelected, required this.onTap,
  });
  final LaserMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.error.withValues(alpha: 0.1)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.error : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20,
            color: isSelected ? cs.error : cs.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? cs.error : cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

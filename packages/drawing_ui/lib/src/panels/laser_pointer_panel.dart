import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the laser pointer tool.
///
/// Allows configuring laser mode, thickness, duration, and color.
/// All changes update MOCK state only - no real laser effect.
class LaserPointerPanel extends ConsumerWidget {
  const LaserPointerPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(laserSettingsProvider);

    return ToolPanel(
      title: 'Lazer işaretleyici',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector (compact)
          _LaserModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (mode) {
              ref.read(laserSettingsProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 14),

          // Thickness slider (compact)
          _CompactSlider(
            title: 'Kalınlık',
            value: settings.thickness,
            valueLabel: '${settings.thickness.toStringAsFixed(1)}mm',
            min: 0.5,
            max: 5.0,
            onChanged: (value) {
              ref.read(laserSettingsProvider.notifier).setThickness(value);
            },
            color: settings.color,
          ),
          const SizedBox(height: 12),

          // Duration slider (compact)
          _CompactSlider(
            title: 'Süre',
            value: settings.duration,
            valueLabel: '${settings.duration.toStringAsFixed(1)}s',
            min: 0.5,
            max: 5.0,
            onChanged: (value) {
              ref.read(laserSettingsProvider.notifier).setDuration(value);
            },
          ),
          const SizedBox(height: 12),

          // Color selector using unified picker
          _ColorSection(
            selectedColor: settings.color,
            onColorSelected: (color) {
              ref.read(laserSettingsProvider.notifier).setColor(color);
            },
          ),
        ],
      ),
    );
  }
}

/// Compact slider for laser panel.
class _CompactSlider extends StatelessWidget {
  const _CompactSlider({
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.onChanged,
    this.color,
  });

  final String title;
  final double value;
  final String valueLabel;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            Text(valueLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: color ?? Colors.red,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: color ?? Colors.red,
            ),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

/// Color section for laser panel.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renk',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        UnifiedColorPicker(
          selectedColor: selectedColor,
          onColorSelected: onColorSelected,
          quickColors: ColorSets.laser,
          colorSets: const {
            'Lazer': ColorSets.laser,
            'Neon': ColorSets.neon,
          },
          chipSize: 26.0,
          spacing: 8.0,
        ),
      ],
    );
  }
}

/// Selector for laser pointer modes (compact).
class _LaserModeSelector extends StatelessWidget {
  const _LaserModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LaserMode selectedMode;
  final ValueChanged<LaserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LaserModeOption(
            mode: LaserMode.line,
            icon: Icons.show_chart,
            label: 'Çizgi',
            isSelected: selectedMode == LaserMode.line,
            onTap: () => onModeSelected(LaserMode.line),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LaserModeOption(
            mode: LaserMode.dot,
            icon: Icons.fiber_manual_record,
            label: 'Nokta',
            isSelected: selectedMode == LaserMode.dot,
            onTap: () => onModeSelected(LaserMode.dot),
          ),
        ),
      ],
    );
  }
}

/// A single laser mode option button (compact).
class _LaserModeOption extends StatelessWidget {
  const _LaserModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final LaserMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.red : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

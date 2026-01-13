import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Hide HighlighterSettings from drawing_core as we use our own UI-specific version
import 'package:drawing_core/drawing_core.dart' hide HighlighterSettings;

import '../providers/drawing_providers.dart';
import '../widgets/unified_color_picker.dart';
import 'tool_panel.dart';

/// Settings panel for the highlighter tool (compact version).
class HighlighterSettingsPanel extends ConsumerWidget {
  const HighlighterSettingsPanel({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(highlighterSettingsProvider);

    return ToolPanel(
      title: 'Vurgulayıcı',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thickness bar preview (compact)
          _ThicknessBarPreview(
            color: settings.color,
            thickness: settings.thickness,
          ),
          const SizedBox(height: 12),

          // Thickness slider (compact)
          _CompactSlider(
            title: 'Kalınlık',
            value: settings.thickness,
            min: 5.0,
            max: 40.0,
            label: '${settings.thickness.toStringAsFixed(0)}mm',
            color: settings.color,
            onChanged: (value) {
              ref.read(highlighterSettingsProvider.notifier).setThickness(value);
            },
          ),
          const SizedBox(height: 10),

          // Straight line toggle (compact)
          _CompactToggle(
            label: 'Düz çizgi',
            value: settings.straightLineMode,
            onChanged: (value) {
              ref.read(highlighterSettingsProvider.notifier).setStraightLineMode(value);
            },
          ),
          const SizedBox(height: 12),

          // Colors (compact)
          _CompactHighlighterColors(
            selectedColor: settings.color,
            onColorSelected: (color) {
              ref.read(highlighterSettingsProvider.notifier).setColor(color);
            },
          ),
          const SizedBox(height: 12),

          // Add button (compact)
          _CompactAddButton(
            onPressed: () => _addToPenBox(context, ref, settings),
          ),
        ],
      ),
    );
  }

  void _addToPenBox(BuildContext context, WidgetRef ref, HighlighterSettings settings) {
    final presets = ref.read(penBoxPresetsProvider);
    
    // Duplicate kontrolü
    final isDuplicate = presets.any((p) => 
      !p.isEmpty &&
      p.toolType == ToolType.highlighter &&
      p.color.value == settings.color.value &&
      (p.thickness - settings.thickness).abs() < 0.1
    );
    
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu vurgulayıcı zaten kalem kutusunda mevcut'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final newPreset = PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: ToolType.highlighter,
      color: settings.color,
      thickness: settings.thickness,
      nibShape: NibShapeType.rectangle,
    );
    ref.read(penBoxPresetsProvider.notifier).addPreset(newPreset);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kalem kutusuna eklendi'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Thickness bar preview (compact).
class _ThicknessBarPreview extends StatelessWidget {
  const _ThicknessBarPreview({
    required this.color,
    required this.thickness,
  });

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Center(
        child: Container(
          width: double.infinity,
          height: (thickness / 3).clamp(4.0, 16.0),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Compact slider.
class _CompactSlider extends StatelessWidget {
  const _CompactSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.color,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
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
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
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
              activeTrackColor: color ?? const Color(0xFF4A9DFF),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: color ?? const Color(0xFF4A9DFF),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

/// Compact toggle.
class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4A9DFF),
          ),
        ),
      ],
    );
  }
}

/// Compact highlighter colors using unified color system.
class _CompactHighlighterColors extends StatelessWidget {
  const _CompactHighlighterColors({
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
          quickColors: ColorSets.highlighter.take(6).toList(),
          colorSets: const {
            'Vurgulayıcı': ColorSets.highlighter,
            'Pastel': ColorSets.pastel,
          },
          chipSize: 28.0,
          spacing: 6.0,
          isHighlighter: true,
        ),
      ],
    );
  }
}

/// Compact add button.
class _CompactAddButton extends StatelessWidget {
  const _CompactAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF374151)),
            SizedBox(width: 6),
            Text('Kalem kutusuna ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

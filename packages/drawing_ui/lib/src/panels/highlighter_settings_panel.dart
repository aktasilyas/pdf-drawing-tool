import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the highlighter tools (highlighter + neonHighlighter).
class HighlighterSettingsPanel extends ConsumerWidget {
  const HighlighterSettingsPanel({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(highlighterSettingsProvider);
    final currentTool = ref.watch(currentToolProvider);
    final isNeon = currentTool == ToolType.neonHighlighter;

    return ToolPanel(
      title: isNeon ? 'Neon Fosforlu' : 'Fosforlu Kalem',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highlighter type selector
          _HighlighterTypeSelector(
            selectedType: currentTool,
            onTypeSelected: (type) {
              ref.read(currentToolProvider.notifier).state = type;
            },
          ),
          const SizedBox(height: 12),

          // Thickness bar preview (compact)
          _ThicknessBarPreview(
            color: settings.color,
            thickness: settings.thickness,
            isNeon: isNeon,
          ),
          const SizedBox(height: 12),

          // Thickness slider (compact)
          _CompactSlider(
            title: 'Kalınlık',
            value: settings.thickness.clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0),
            min: isNeon ? 8.0 : 10.0,
            max: isNeon ? 30.0 : 40.0,
            label: '${settings.thickness.clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0).toStringAsFixed(0)}mm',
            color: settings.color,
            onChanged: (value) {
              ref.read(highlighterSettingsProvider.notifier).setThickness(value);
            },
          ),
          const SizedBox(height: 10),

          // Neon-specific: Glow intensity slider
          if (isNeon) ...[
            _CompactSlider(
              title: 'Parlaklık',
              value: settings.glowIntensity,
              min: 0.1,
              max: 1.0,
              label: '${(settings.glowIntensity * 100).round()}%',
              color: settings.color,
              onChanged: (value) {
                ref.read(highlighterSettingsProvider.notifier).setGlowIntensity(value);
              },
            ),
            const SizedBox(height: 10),
          ],

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
            isNeon: isNeon,
          ),
          const SizedBox(height: 12),

          // Add button (compact)
          _CompactAddButton(
            onPressed: () => _addToPenBox(context, ref, settings, isNeon),
          ),
        ],
      ),
    );
  }

  void _addToPenBox(BuildContext context, WidgetRef ref, HighlighterSettings settings, bool isNeon) {
    final presets = ref.read(penBoxPresetsProvider);
    final toolType = isNeon ? ToolType.neonHighlighter : ToolType.highlighter;
    
    // Duplicate kontrolü
    final isDuplicate = presets.any((p) => 
      !p.isEmpty &&
      p.toolType == toolType &&
      p.color.value == settings.color.value &&
      (p.thickness - settings.thickness).abs() < 0.1
    );
    
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu ${isNeon ? "neon fosforlu" : "fosforlu kalem"} zaten kalem kutusunda mevcut'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final newPreset = PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: toolType,
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

/// Highlighter type selector (2 options: normal + neon)
class _HighlighterTypeSelector extends StatelessWidget {
  const _HighlighterTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final ValueChanged<ToolType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HighlighterTypeButton(
            label: 'Fosforlu',
            icon: Icons.highlight,
            isSelected: selectedType == ToolType.highlighter,
            onTap: () => onTypeSelected(ToolType.highlighter),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HighlighterTypeButton(
            label: 'Neon',
            icon: Icons.flash_on,
            isSelected: selectedType == ToolType.neonHighlighter,
            onTap: () => onTypeSelected(ToolType.neonHighlighter),
            isNeon: true,
          ),
        ),
      ],
    );
  }
}

class _HighlighterTypeButton extends StatelessWidget {
  const _HighlighterTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isNeon = false,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNeon;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isNeon ? const Color(0xFFFF00FF) : const Color(0xFFFFEB3B);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withAlpha(30) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? selectedColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thickness bar preview (compact).
class _ThicknessBarPreview extends StatelessWidget {
  const _ThicknessBarPreview({
    required this.color,
    required this.thickness,
    this.isNeon = false,
  });

  final Color color;
  final double thickness;
  final bool isNeon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      decoration: BoxDecoration(
        color: isNeon ? Colors.grey.shade900 : Colors.grey.shade50,
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
            boxShadow: isNeon
                ? [
                    BoxShadow(
                      color: color.withAlpha(180),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
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
    this.isNeon = false,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool isNeon;

  // Neon renkler (canlı, parlak)
  static const _neonColors = [
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF0080), // Pink
    Color(0xFF00FF00), // Green
    Color(0xFFFF8000), // Orange
    Color(0xFF8000FF), // Purple
  ];

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
          quickColors: isNeon ? _neonColors : ColorSets.highlighter.take(6).toList(),
          colorSets: isNeon
              ? const {'Neon': _neonColors, 'Vurgulayıcı': ColorSets.highlighter}
              : const {'Vurgulayıcı': ColorSets.highlighter, 'Pastel': ColorSets.pastel},
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

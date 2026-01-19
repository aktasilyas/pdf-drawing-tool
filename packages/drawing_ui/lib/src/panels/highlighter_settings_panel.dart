import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';
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
            selectedColor: settings.color,
            onTypeSelected: (type) {
              ref.read(currentToolProvider.notifier).state = type;
            },
          ),
          const SizedBox(height: 8),

          // Thickness bar preview (compact)
          _ThicknessBarPreview(
            color: settings.color,
            thickness: settings.thickness,
            isNeon: isNeon,
          ),
          const SizedBox(height: 8),

          // Thickness slider (compact)
          _CompactSlider(
            title: 'Kalınlık',
            value: settings.thickness
                .clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0),
            min: isNeon ? 8.0 : 10.0,
            max: isNeon ? 30.0 : 40.0,
            label:
                '${settings.thickness.clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0).toStringAsFixed(0)}mm',
            color: settings.color,
            onChanged: (value) {
              ref
                  .read(highlighterSettingsProvider.notifier)
                  .setThickness(value);
            },
          ),
          const SizedBox(height: 8),

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
                ref
                    .read(highlighterSettingsProvider.notifier)
                    .setGlowIntensity(value);
              },
            ),
            const SizedBox(height: 8),
          ],

          // Straight line toggle (compact)
          _CompactToggle(
            label: 'Düz çizgi',
            value: settings.straightLineMode,
            onChanged: (value) {
              ref
                  .read(highlighterSettingsProvider.notifier)
                  .setStraightLineMode(value);
            },
          ),
          const SizedBox(height: 8),

          // Colors (compact)
          Builder(
            builder: (context) {
              final notifier = ref.read(highlighterSettingsProvider.notifier);
              return _CompactHighlighterColors(
                selectedColor: settings.color,
                onColorSelected: (color) {
                  notifier.setColor(color);
                },
                isNeon: isNeon,
              );
            },
          ),
          const SizedBox(height: 8),

          // Add button (compact)
          _CompactAddButton(
            onPressed: () => _addToPenBox(context, ref, settings, isNeon),
          ),
        ],
      ),
    );
  }

  void _addToPenBox(BuildContext context, WidgetRef ref,
      HighlighterSettings settings, bool isNeon) {
    final presets = ref.read(penBoxPresetsProvider);
    final toolType = isNeon ? ToolType.neonHighlighter : ToolType.highlighter;

    // Duplicate kontrolü
    final isDuplicate = presets.any((p) =>
        !p.isEmpty &&
        p.toolType == toolType &&
        p.color.value == settings.color.value &&
        (p.thickness - settings.thickness).abs() < 0.1);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bu ${isNeon ? "neon fosforlu" : "fosforlu kalem"} zaten kalem kutusunda mevcut'),
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

/// Highlighter type selector - GoodNotes/Fenci style toolbar.
/// Pens are vertical, tip UP, bottom clipped by container.
/// Selected pen rises up to show more body.
class _HighlighterTypeSelector extends StatelessWidget {
  const _HighlighterTypeSelector({
    required this.selectedType,
    required this.selectedColor,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final Color selectedColor;
  final ValueChanged<ToolType> onTypeSelected;

  static const _highlighterTypes = [
    ToolType.highlighter,
    ToolType.neonHighlighter,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _highlighterTypes.map((type) {
          final isSelected = type == selectedType;
          return _HighlighterSlot(
            type: type,
            isSelected: isSelected,
            selectedColor: selectedColor,
            onTap: () => onTypeSelected(type),
          );
        }).toList(),
      ),
    );
  }
}

/// Single highlighter slot with proper clipping and animation.
class _HighlighterSlot extends StatelessWidget {
  const _HighlighterSlot({
    required this.type,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final ToolType type;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  // Highlighter dimensions (kompakt)
  static const double _penHeight = 56;
  static const double _slotHeight = 44;
  static const double _slotWidth = 48;

  // Vertical offsets
  static const double _selectedTopOffset = -6;
  static const double _unselectedTopOffset = 4;

  @override
  Widget build(BuildContext context) {
    final displayName = type.displayName;

    return Tooltip(
      message: displayName,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _slotWidth,
          height: _slotHeight,
          child: ClipRect(
            child: OverflowBox(
              maxHeight: _penHeight + 20,
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: _penHeight,
                margin: EdgeInsets.only(
                  top: isSelected
                      ? _selectedTopOffset + 10
                      : _unselectedTopOffset + 10,
                ),
                child: ToolPenIcon(
                  toolType: type,
                  color: isSelected ? selectedColor : Colors.grey.shade400,
                  isSelected: false,
                  size: _penHeight,
                  orientation: PenOrientation.vertical,
                ),
              ),
            ),
          ),
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
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333))),
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
            child:
                Slider(value: value, min: min, max: max, onChanged: onChanged),
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
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
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
          quickColors:
              isNeon ? _neonColors : ColorSets.highlighter.take(6).toList(),
          colorSets: isNeon
              ? const {
                  'Neon': _neonColors,
                  'Vurgulayıcı': ColorSets.highlighter
                }
              : const {
                  'Vurgulayıcı': ColorSets.highlighter,
                  'Pastel': ColorSets.pastel
                },
          chipSize: 24.0,
          spacing: 5.0,
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
            Text('Kalem kutusuna ekle',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

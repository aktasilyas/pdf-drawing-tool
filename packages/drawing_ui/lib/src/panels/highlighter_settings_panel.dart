import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

Color _darkenColor(Color c, double amt) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness * (1 - amt)).clamp(0.0, 1.0)).toColor();
}

/// Highlighter settings content for popover panel.
class HighlighterSettingsPanel extends ConsumerWidget {
  const HighlighterSettingsPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(highlighterSettingsProvider);
    final currentTool = ref.watch(currentToolProvider);
    final isNeon = currentTool == ToolType.neonHighlighter;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isNeon ? 'Neon Fosforlu' : 'Fosforlu Kalem', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          _HighlighterTypeSelector(
            selectedType: currentTool, selectedColor: settings.color,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).state = t,
          ),
          const SizedBox(height: 8),
          _ThicknessBarPreview(
            color: settings.color, thickness: settings.thickness,
            isNeon: isNeon,
          ),
          const SizedBox(height: 8),
          _GoodNotesSlider(
            label: 'KALINLIK', activeColor: settings.color,
            value: settings.thickness
                .clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0),
            min: isNeon ? 8.0 : 10.0, max: isNeon ? 30.0 : 40.0,
            displayValue:
                '${settings.thickness.clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0).toStringAsFixed(0)}mm',
            onChanged: (v) => ref.read(
                highlighterSettingsProvider.notifier).setThickness(v),
          ),
          const SizedBox(height: 8),
          if (isNeon) ...[
            _GoodNotesSlider(
              label: 'PARLAKLIK', activeColor: settings.color,
              value: settings.glowIntensity, min: 0.1, max: 1.0,
              displayValue: '${(settings.glowIntensity * 100).round()}%',
              onChanged: (v) => ref.read(
                  highlighterSettingsProvider.notifier).setGlowIntensity(v),
            ),
            const SizedBox(height: 8),
          ],
          CompactToggle(
            label: 'Düz çizgi', value: settings.straightLineMode,
            onChanged: (v) => ref.read(
                highlighterSettingsProvider.notifier).setStraightLineMode(v),
          ),
          const SizedBox(height: 8),
          _CompactHighlighterColors(
            selectedColor: settings.color, isNeon: isNeon,
            onColorSelected: (c) => ref.read(
                highlighterSettingsProvider.notifier).setColor(c),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _addToPenBox(context, ref, settings, isNeon),
              icon: Icon(StarNoteIcons.plus, size: 16),
              label: const Text('Kalem kutusuna ekle',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToPenBox(BuildContext ctx, WidgetRef ref,
      HighlighterSettings settings, bool isNeon) {
    final presets = ref.read(penBoxPresetsProvider);
    final toolType = isNeon ? ToolType.neonHighlighter : ToolType.highlighter;
    if (presets.any((p) => !p.isEmpty && p.toolType == toolType &&
        p.color.toARGB32() == settings.color.toARGB32() &&
        (p.thickness - settings.thickness).abs() < 0.1)) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Bu ${isNeon ? "neon fosforlu" : "fosforlu kalem"}'
              ' zaten kalem kutusunda mevcut'),
          duration: const Duration(seconds: 2)));
      return;
    }
    ref.read(penBoxPresetsProvider.notifier).addPreset(PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: toolType, color: settings.color,
      thickness: settings.thickness, nibShape: NibShapeType.rectangle,
    ));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Kalem kutusuna eklendi'),
        duration: Duration(seconds: 1)));
  }
}

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

class _HighlighterTypeSelector extends StatelessWidget {
  const _HighlighterTypeSelector({
    required this.selectedType, required this.selectedColor,
    required this.onTypeSelected,
  });
  final ToolType selectedType;
  final Color selectedColor;
  final ValueChanged<ToolType> onTypeSelected;
  static const _types = [ToolType.highlighter, ToolType.neonHighlighter];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: dk ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: dk ? Border.all(
            color: cs.outline.withValues(alpha: 0.3), width: 0.5) : null,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: (dk ? 25 : 15) / 255.0),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final t in _types) _HighlighterSlot(
          type: t, isSelected: t == selectedType,
          selColor: selectedColor, onTap: () => onTypeSelected(t))],
      ),
    );
  }
}

class _HighlighterSlot extends StatelessWidget {
  const _HighlighterSlot({
    required this.type, required this.isSelected,
    required this.selColor, required this.onTap,
  });
  final ToolType type;
  final bool isSelected;
  final Color selColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    final c = isSelected && dk ? _darkenColor(selColor, 0.3) : selColor;
    return Tooltip(
      message: type.displayName,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 48, height: 44, child: ClipRect(
          child: OverflowBox(maxHeight: 76, alignment: Alignment.topCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic, height: 56,
              margin: EdgeInsets.only(top: isSelected ? 4 : 14),
              child: ToolPenIcon(toolType: type, size: 56,
                orientation: PenOrientation.vertical, isSelected: false,
                color: isSelected ? c
                    : (dk ? cs.onSurface.withValues(alpha: 0.6)
                        : cs.onSurfaceVariant)),
            ),
          ),
        )),
      ),
    );
  }
}

class _ThicknessBarPreview extends StatelessWidget {
  const _ThicknessBarPreview({
    required this.color, required this.thickness, this.isNeon = false,
  });
  final Color color;
  final double thickness;
  final bool isNeon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    final dColor = dk ? _darkenColor(color, 0.3) : color;
    return Container(
      width: double.infinity, height: 28,
      decoration: BoxDecoration(
        color: isNeon
            ? (dk ? cs.onSurface : cs.surfaceContainerHighest)
            : (dk ? cs.surfaceContainerHigh : cs.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: cs.outline.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Center(child: Container(
        width: double.infinity, height: (thickness / 3).clamp(4.0, 16.0),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dColor, borderRadius: BorderRadius.circular(2),
          boxShadow: isNeon ? [BoxShadow(
            color: color.withValues(alpha: 180.0 / 255.0),
            blurRadius: 8, spreadRadius: 2)] : null,
        ),
      )),
    );
  }
}

class _CompactHighlighterColors extends StatelessWidget {
  const _CompactHighlighterColors({
    required this.selectedColor, required this.onColorSelected,
    this.isNeon = false,
  });
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool isNeon;
  static const _neonColors = [
    Color(0xFFFF00FF), Color(0xFF00FFFF), Color(0xFFFF0080),
    Color(0xFF00FF00), Color(0xFFFF8000), Color(0xFF8000FF),
  ];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RENK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      UnifiedColorPicker(
        selectedColor: selectedColor, onColorSelected: onColorSelected,
        quickColors:
            isNeon ? _neonColors : ColorSets.highlighter.take(6).toList(),
        colorSets: isNeon
            ? const {'Neon': _neonColors, 'Vurgulayici': ColorSets.highlighter}
            : const {
                'Vurgulayici': ColorSets.highlighter,
                'Pastel': ColorSets.pastel,
              },
        chipSize: 24.0, spacing: 5.0, isHighlighter: true,
      ),
    ]);
  }
}

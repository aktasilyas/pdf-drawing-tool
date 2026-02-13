import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

Color _darkenColor(Color c, double amt) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness * (1 - amt)).clamp(0.0, 1.0)).toColor();
}

/// Pen settings content for popover panel.
///
/// Designed for PopoverPanel — no ToolPanel wrapper needed.
class PenSettingsPanel extends ConsumerWidget {
  const PenSettingsPanel({super.key, required this.toolType});
  final ToolType toolType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final active = _isPenTool(currentTool) ? currentTool : toolType;
    final s = ref.watch(penSettingsProvider(active));
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title(active), style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          _LiveStrokePreview(
              color: s.color, thickness: s.thickness, toolType: active),
          const SizedBox(height: 12),
          _PenTypeSelector(
            selectedType: currentTool, selectedColor: s.color,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).state = t,
          ),
          const SizedBox(height: 12),
          _GoodNotesSlider(
            label: 'KALINLIK', activeColor: s.color,
            value: s.thickness.clamp(_minTh(active), _maxTh(active)),
            min: _minTh(active), max: _maxTh(active),
            displayValue: '${s.thickness.toStringAsFixed(1)}mm',
            onChanged: (v) => ref.read(
                penSettingsProvider(active).notifier).setThickness(v),
          ),
          const SizedBox(height: 8),
          _GoodNotesSlider(
            label: 'SABİTLEME', activeColor: cs.primary,
            value: s.stabilization, min: 0, max: 1,
            displayValue: '${(s.stabilization * 100).round()}%',
            onChanged: (v) => ref.read(
                penSettingsProvider(active).notifier).setStabilization(v),
          ),
          const SizedBox(height: 12),
          // Color section inline
          Text('RENK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          UnifiedColorPicker(
            selectedColor: s.color,
            onColorSelected: (c) => ref.read(
                penSettingsProvider(active).notifier).setColor(c),
            quickColors: ColorSets.quickAccess,
            colorSets: ColorSets.all, chipSize: 24, spacing: 6,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _addToPenBox(context, ref, s),
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

  bool _isPenTool(ToolType t) => const [
    ToolType.pencil, ToolType.hardPencil, ToolType.ballpointPen,
    ToolType.gelPen, ToolType.dashedPen, ToolType.brushPen, ToolType.rulerPen,
  ].contains(t);

  String _title(ToolType t) => t.penType?.config.displayNameTr ?? 'Kalem';
  double _minTh(ToolType t) => t.penType?.config.minThickness ?? 0.1;
  double _maxTh(ToolType t) => t.penType?.config.maxThickness ?? 20.0;

  void _addToPenBox(BuildContext ctx, WidgetRef ref, PenSettings s) {
    final presets = ref.read(penBoxPresetsProvider);
    final tool = ref.read(currentToolProvider);
    final cur = ref.read(penSettingsProvider(tool));
    if (presets.any((p) => !p.isEmpty && p.toolType == tool &&
        p.color.toARGB32() == cur.color.toARGB32() &&
        (p.thickness - cur.thickness).abs() < 0.1)) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Bu kalem zaten kalem kutusunda mevcut'),
          duration: Duration(seconds: 2)));
      return;
    }
    ref.read(penBoxPresetsProvider.notifier).addPreset(PenPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      toolType: tool, color: cur.color,
      thickness: cur.thickness, nibShape: cur.nibShape,
    ));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Kalem kutusuna eklendi'),
        duration: Duration(seconds: 1)));
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

/// Live stroke preview — 50dp height sine wave.
class _LiveStrokePreview extends StatelessWidget {
  const _LiveStrokePreview({
    required this.color, required this.thickness, required this.toolType,
  });
  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(size: const Size(double.infinity, 50),
          painter: _StrokePainter(color, thickness, toolType, isDark)),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.color, this.thickness, this.toolType, this.isDark);
  final Color color;
  final double thickness;
  final ToolType toolType;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? _darkenColor(color, 0.3) : color
      ..style = PaintingStyle.stroke..strokeWidth = thickness * 1.5
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(16, size.height / 2);
    for (var x = 16.0; x < size.width - 16; x += 24) {
      path.quadraticBezierTo(x + 6, size.height / 2 - 10, x + 12, size.height / 2);
      path.quadraticBezierTo(x + 18, size.height / 2 + 10, x + 24, size.height / 2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePainter o) =>
      color != o.color || thickness != o.thickness ||
      toolType != o.toolType || isDark != o.isDark;
}

/// Pen type selector row.
class _PenTypeSelector extends StatelessWidget {
  const _PenTypeSelector({
    required this.selectedType, required this.selectedColor,
    required this.onTypeSelected,
  });
  final ToolType selectedType;
  final Color selectedColor;
  final ValueChanged<ToolType> onTypeSelected;
  static const _types = [ToolType.pencil, ToolType.hardPencil,
    ToolType.ballpointPen, ToolType.gelPen, ToolType.dashedPen,
    ToolType.brushPen, ToolType.rulerPen];

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
        children: [for (final t in _types) _PenSlot(
          type: t, isSelected: t == selectedType,
          selColor: selectedColor, onTap: () => onTypeSelected(t))],
      ),
    );
  }
}

class _PenSlot extends StatelessWidget {
  const _PenSlot({
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
      message: type.penType?.config.displayNameTr ?? type.displayName,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 32, height: 44, child: ClipRect(
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

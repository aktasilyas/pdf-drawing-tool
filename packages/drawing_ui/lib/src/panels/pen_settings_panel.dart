import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/pen_settings_widgets.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';

/// Pen settings content for popover panel.
///
/// GoodNotes-style layout: title, stroke preview, pen type selector,
/// 3 sliders (thickness, pressure sensitivity, stabilization),
/// collapsible AYARLAR section with color picker.
class PenSettingsPanel extends ConsumerStatefulWidget {
  const PenSettingsPanel({super.key, required this.toolType});
  final ToolType toolType;

  @override
  ConsumerState<PenSettingsPanel> createState() => _PenSettingsPanelState();
}

class _PenSettingsPanelState extends ConsumerState<PenSettingsPanel> {
  bool _isAyarlarExpanded = false;

  static const _penTools = [
    ToolType.pencil,
    ToolType.ballpointPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  bool _isPenTool(ToolType t) => _penTools.contains(t);

  String _title(ToolType t) => t.penType?.config.displayNameTr ?? 'Kalem';
  double _minTh(ToolType t) => t.penType?.config.minThickness ?? 0.1;
  double _maxTh(ToolType t) => t.penType?.config.maxThickness ?? 20.0;

  int _thicknessPercent(double value, double min, double max) {
    if (max <= min) return 0;
    return ((value - min) / (max - min) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final currentTool = ref.watch(currentToolProvider);
    final active = _isPenTool(currentTool) ? currentTool : widget.toolType;
    final s = ref.watch(penSettingsProvider(active));
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(penSettingsProvider(active).notifier);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(_title(active), style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          // Stroke preview
          LiveStrokePreview(
            color: s.color, thickness: s.thickness, toolType: active),
          const SizedBox(height: 12),
          // Pen type selector
          PenTypeSelector(
            selectedType: currentTool,
            selectedColor: s.color,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).state = t,
          ),
          const SizedBox(height: 12),
          // Slider 1: Thickness (percentage display)
          GoodNotesSlider(
            label: 'UÇ KESKİNLİĞİ',
            activeColor: s.color,
            value: s.thickness.clamp(_minTh(active), _maxTh(active)),
            min: _minTh(active),
            max: _maxTh(active),
            displayValue:
                '${_thicknessPercent(s.thickness, _minTh(active), _maxTh(active))}%',
            onChanged: (v) => notifier.setThickness(v),
          ),
          const SizedBox(height: 8),
          // Slider 2: Pressure sensitivity
          GoodNotesSlider(
            label: 'BASINÇ DUYARLILIĞI',
            activeColor: cs.primary,
            value: s.pressureSensitivity,
            min: 0,
            max: 1,
            displayValue: '${(s.pressureSensitivity * 100).round()}%',
            onChanged: (v) => notifier.setPressureSensitivity(v),
          ),
          const SizedBox(height: 8),
          // Slider 3: Stabilization
          GoodNotesSlider(
            label: 'ÇİZGİ STABİLİZASYONU',
            activeColor: cs.primary,
            value: s.stabilization,
            min: 0,
            max: 1,
            displayValue: '${(s.stabilization * 100).round()}%',
            onChanged: (v) => notifier.setStabilization(v),
          ),
          const SizedBox(height: 12),
          // Collapsible AYARLAR section
          _AyarlarSection(
            isExpanded: _isAyarlarExpanded,
            onToggle: () =>
                setState(() => _isAyarlarExpanded = !_isAyarlarExpanded),
            child: UnifiedColorPicker(
              selectedColor: s.color,
              onColorSelected: (c) => notifier.setColor(c),
              quickColors: ColorSets.quickAccess,
              colorSets: ColorSets.all,
              chipSize: 24,
              spacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible AYARLAR section with header and animated content.
class _AyarlarSection extends StatelessWidget {
  const _AyarlarSection({
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('AYARLAR', style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                )),
                const SizedBox(width: 4),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RENK', style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                )),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

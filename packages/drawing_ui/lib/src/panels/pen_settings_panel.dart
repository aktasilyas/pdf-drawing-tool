import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/panels/pen_type_picker.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Pen settings panel (docs/specs/52-editor-chrome.md, section 4).
///
/// Header (48dp, pen name, close), one [PenTypePicker], hairline, three
/// sliders, hairline, colour strip. Colours come from [ChromePalette].
class PenSettingsPanel extends ConsumerWidget {
  const PenSettingsPanel({super.key, required this.toolType});
  final ToolType toolType;

  /// Panel width on tablet (inside the popover).
  static const double width = 380;

  /// Header height.
  static const double headerHeight = ChromePanelHeader.height;

  /// Tools this panel edits (the picker row shows the five v2 presets;
  /// legacy pens keep their settings here when they are current).
  static const _penTools = [
    ToolType.fountainPen,
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  static double _minTh(ToolType t) => t.penType?.config.minThickness ?? 0.1;
  static double _maxTh(ToolType t) => t.penType?.config.maxThickness ?? 20.0;
  static int _pct(double val, double min, double max) {
    if (max <= min) return 0;
    return ((val - min) / (max - min) * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final active = _penTools.contains(currentTool) ? currentTool : toolType;
    final s = ref.watch(penSettingsProvider(active));
    final palette = ChromePalette.of(context);
    final notifier = ref.read(penSettingsProvider(active).notifier);

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: active.penType?.config.displayNameTr ?? 'Kalem',
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          PenTypePicker(
            padding: EdgeInsets.zero,
            onPenSelected: (t) {
              // The highlighter has its own settings panel.
              if (t == ToolType.highlighter) {
                ref.read(activePanelProvider.notifier).state = t;
              }
            },
          ),
          const ChromeHairline(),
          GoodNotesSlider(
            label: 'Kalınlık',
            value: s.thickness.clamp(_minTh(active), _maxTh(active)),
            min: _minTh(active),
            max: _maxTh(active),
            displayValue:
                '${_pct(s.thickness, _minTh(active), _maxTh(active))}%',
            divisions: null,
            activeColor: palette.accent,
            onChanged: notifier.setThickness,
          ),
          GoodNotesSlider(
            label: 'Basınç Duyarlılığı',
            value: s.pressureSensitivity,
            min: 0,
            max: 1,
            displayValue: '${(s.pressureSensitivity * 100).round()}%',
            divisions: null,
            activeColor: palette.accent,
            onChanged: notifier.setPressureSensitivity,
          ),
          GoodNotesSlider(
            label: 'Çizgi Stabilizasyonu',
            value: s.stabilization,
            min: 0,
            max: 1,
            displayValue: '${(s.stabilization * 100).round()}%',
            divisions: null,
            activeColor: palette.accent,
            onChanged: notifier.setStabilization,
          ),
          const ChromeHairline(),
          ColorPickerStrip(
            selectedColor: s.color,
            onColorSelected: notifier.setColor,
          ),
        ],
      ),
    );
  }
}

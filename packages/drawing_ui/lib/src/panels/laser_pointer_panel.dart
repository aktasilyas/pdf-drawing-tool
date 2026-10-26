import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/panels/laser_preview_painter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Returns display title based on current mode + line style.
String _titleFor(LaserMode mode, LaserLineStyle style) {
  if (mode == LaserMode.dot) return 'Lazer Nokta';
  return switch (style) {
    LaserLineStyle.solid => 'Lazer Çizgi',
    LaserLineStyle.hollow => 'Lazer Çizgi (Boş)',
    LaserLineStyle.rainbow => 'Lazer Gökkuşağı',
  };
}

/// Laser pointer settings panel — pen popup style.
class LaserPointerPanel extends ConsumerWidget {
  const LaserPointerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(laserSettingsProvider);
    final notifier = ref.read(laserSettingsProvider.notifier);
    final palette = ChromePalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: _titleFor(settings.mode, settings.lineStyle),
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          LaserPreview(
            color: settings.color,
            thickness: settings.thickness,
            mode: settings.mode,
            lineStyle: settings.lineStyle,
          ),
          const SizedBox(height: ChromeSpacing.sm),
          // Combined mode + line style selector (4 options)
          _LaserTypeSelector(
            mode: settings.mode,
            lineStyle: settings.lineStyle,
            onSelected: (mode, style) {
              notifier.setMode(mode);
              notifier.setLineStyle(style);
            },
          ),
          const ChromeHairline(),
          GoodNotesSlider(
            label: 'Kalınlık',
            value: settings.thickness.clamp(0.5, 5.0),
            min: 0.5,
            max: 5.0,
            displayValue: '${settings.thickness.toStringAsFixed(1)}mm',
            activeColor: palette.accent,
            onChanged: notifier.setThickness,
          ),
          GoodNotesSlider(
            label: 'Süre',
            value: settings.duration.clamp(0.5, 5.0),
            min: 0.5,
            max: 5.0,
            displayValue: '${settings.duration.toStringAsFixed(1)}s',
            activeColor: palette.accent,
            onChanged: notifier.setDuration,
          ),
          // Color strip (hidden for rainbow)
          if (settings.lineStyle != LaserLineStyle.rainbow) ...[
            const ChromeHairline(),
            ColorPickerStrip(
              selectedColor: settings.color,
              onColorSelected: notifier.setColor,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Combined type selector (4 options in one row)
// ─────────────────────────────────────────────────────────────────────────────

class _LaserTypeSelector extends StatelessWidget {
  const _LaserTypeSelector({
    required this.mode,
    required this.lineStyle,
    required this.onSelected,
  });

  final LaserMode mode;
  final LaserLineStyle lineStyle;
  final void Function(LaserMode mode, LaserLineStyle style) onSelected;

  Widget _button({
    required String keyName,
    required IconData icon,
    required bool selected,
    required LaserMode targetMode,
    required LaserLineStyle targetStyle,
  }) {
    return ChromeIconButton(
      key: ValueKey('laser-type-$keyName'),
      icon: icon,
      iconSize: ChromeIconSizes.md,
      tooltip: _titleFor(targetMode, targetStyle),
      selected: selected,
      onPressed: () => onSelected(targetMode, targetStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLine = mode == LaserMode.line;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _button(
          keyName: 'solid',
          icon: PhosphorIconsLight.lineSegment,
          selected: isLine && lineStyle == LaserLineStyle.solid,
          targetMode: LaserMode.line,
          targetStyle: LaserLineStyle.solid,
        ),
        _button(
          keyName: 'hollow',
          icon: PhosphorIconsLight.lineSegments,
          selected: isLine && lineStyle == LaserLineStyle.hollow,
          targetMode: LaserMode.line,
          targetStyle: LaserLineStyle.hollow,
        ),
        _button(
          keyName: 'rainbow',
          icon: PhosphorIconsLight.rainbow,
          selected: isLine && lineStyle == LaserLineStyle.rainbow,
          targetMode: LaserMode.line,
          targetStyle: LaserLineStyle.rainbow,
        ),
        _button(
          keyName: 'dot',
          icon: ElyanotesIcons.circle,
          selected: mode == LaserMode.dot,
          targetMode: LaserMode.dot,
          targetStyle: lineStyle,
        ),
      ],
    );
  }
}

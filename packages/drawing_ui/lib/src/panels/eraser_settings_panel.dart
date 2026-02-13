import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';

/// Eraser settings content for popover panel.
class EraserSettingsPanel extends ConsumerWidget {
  const EraserSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(eraserSettingsProvider);
    final showSizeSlider = settings.mode != EraserMode.lasso;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Silgi', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          _EraserModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (m) =>
                ref.read(eraserSettingsProvider.notifier).setMode(m),
          ),
          const SizedBox(height: 8),
          if (showSizeSlider)
            _GoodNotesSlider(
              label: 'BOYUT', activeColor: cs.primary,
              value: settings.size, min: 5.0, max: 100.0,
              displayValue: '${settings.size.round()}px',
              onChanged: (v) =>
                  ref.read(eraserSettingsProvider.notifier).setSize(v),
            ),
          const SizedBox(height: 8),
          CompactToggle(
            label: 'Basınç hassasiyeti', value: settings.pressureSensitive,
            onChanged: (v) => ref.read(
                eraserSettingsProvider.notifier).setPressureSensitive(v),
          ),
          CompactToggle(
            label: 'Sadece vurgulayıcı sil',
            value: settings.eraseOnlyHighlighter,
            onChanged: (v) => ref.read(
                eraserSettingsProvider.notifier).setEraseOnlyHighlighter(v),
          ),
          CompactToggle(
            label: 'Sadece bant sil', value: settings.eraseBandOnly,
            onChanged: (v) => ref.read(
                eraserSettingsProvider.notifier).setEraseBandOnly(v),
          ),
          CompactToggle(
            label: 'Otomatik kaldır', value: settings.autoLift,
            onChanged: (v) =>
                ref.read(eraserSettingsProvider.notifier).setAutoLift(v),
          ),
          const SizedBox(height: 8),
          _CompactActionButton(
            label: 'Sayfayı Temizle', icon: StarNoteIcons.trash,
            isDestructive: true,
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Sayfayı Temizle?',
            style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Bu sayfa içeriğini tamamen silecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearActivePage(ref);
            },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _clearActivePage(WidgetRef ref) {
    final document = ref.read(documentProvider);
    ref.read(historyManagerProvider.notifier).execute(
      core.ClearLayerCommand(layerIndex: document.activeLayerIndex),
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

/// Compact action button.
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label, required this.icon,
    required this.onPressed, this.isDestructive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? cs.error : cs.primary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Selector for eraser modes.
class _EraserModeSelector extends StatelessWidget {
  const _EraserModeSelector({
    required this.selectedMode, required this.onModeSelected,
  });
  final EraserMode selectedMode;
  final ValueChanged<EraserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _EraserModeOption(
        mode: EraserMode.pixel, icon: StarNoteIcons.sparkle,
        label: 'Piksel', isSelected: selectedMode == EraserMode.pixel,
        onTap: () => onModeSelected(EraserMode.pixel),
      )),
      const SizedBox(width: 4),
      Expanded(child: _EraserModeOption(
        mode: EraserMode.stroke, icon: StarNoteIcons.broom,
        label: 'Çizgi', isSelected: selectedMode == EraserMode.stroke,
        onTap: () => onModeSelected(EraserMode.stroke),
      )),
      const SizedBox(width: 4),
      Expanded(child: _EraserModeOption(
        mode: EraserMode.lasso, icon: StarNoteIcons.selection,
        label: 'Kement', isSelected: selectedMode == EraserMode.lasso,
        onTap: () => onModeSelected(EraserMode.lasso), isPremium: true,
      )),
    ]);
  }
}

/// A single eraser mode option button.
class _EraserModeOption extends StatelessWidget {
  const _EraserModeOption({
    required this.mode, required this.icon, required this.label,
    required this.isSelected, required this.onTap, this.isPremium = false,
  });
  final EraserMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            Icon(icon, size: 16,
              color: isSelected ? cs.primary : cs.onSurfaceVariant),
            if (isPremium) Positioned(top: -2, right: -2,
              child: PhosphorIcon(StarNoteIcons.lock, size: 9,
                color: cs.tertiary)),
          ]),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? cs.primary : cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

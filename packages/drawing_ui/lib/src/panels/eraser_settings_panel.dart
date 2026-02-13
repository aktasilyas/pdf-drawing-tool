import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for eraser tools.
///
/// Allows configuring eraser mode, size, and various options.
/// All changes update MOCK state only - no real drawing effect.
class EraserSettingsPanel extends ConsumerWidget {
  const EraserSettingsPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(eraserSettingsProvider);
    final showSizeSlider = settings.mode != EraserMode.lasso;

    return ToolPanel(
      title: 'Silgi',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector
          _EraserModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (mode) {
              ref.read(eraserSettingsProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 8),

          // Size slider (only for pixel and stroke eraser)
          if (showSizeSlider)
            _CompactSizeSlider(
              label: 'Boyut',
              value: settings.size,
              min: 5.0,
              max: 100.0,
              onChanged: (value) {
                ref.read(eraserSettingsProvider.notifier).setSize(value);
              },
            ),
          const SizedBox(height: 8),

          // Options - compact toggles
          CompactToggle(
            label: 'Basınç hassasiyeti',
            value: settings.pressureSensitive,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setPressureSensitive(value);
            },
          ),
          CompactToggle(
            label: 'Sadece vurgulayıcı sil',
            value: settings.eraseOnlyHighlighter,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setEraseOnlyHighlighter(value);
            },
          ),
          CompactToggle(
            label: 'Sadece bant sil',
            value: settings.eraseBandOnly,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setEraseBandOnly(value);
            },
          ),
          CompactToggle(
            label: 'Otomatik kaldır',
            value: settings.autoLift,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setAutoLift(value);
            },
          ),
          const SizedBox(height: 8),

          // Clear page button (destructive action)
          _CompactActionButton(
            label: 'Sayfayı Temizle',
            icon: StarNoteIcons.trash,
            isDestructive: true,
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Sayfayı Temizle?', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Bu sayfa içeriğini tamamen silecek. '
          'Bu işlem geri alınamaz.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear active layer
              _clearActivePage(ref);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _clearActivePage(WidgetRef ref) {
    final document = ref.read(documentProvider);
    final layerIndex = document.activeLayerIndex;
    
    // Clear all strokes, shapes, and texts from active layer
    ref.read(historyManagerProvider.notifier).execute(
      core.ClearLayerCommand(layerIndex: layerIndex),
    );
  }
}

/// Compact size slider
class _CompactSizeSlider extends StatelessWidget {
  const _CompactSizeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toInt()}px',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 22,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.outlineVariant,
              thumbColor: colorScheme.primary,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// _CompactToggle removed - using shared CompactToggle widget

/// Compact action button
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector for eraser modes - compact version.
class _EraserModeSelector extends StatelessWidget {
  const _EraserModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final EraserMode selectedMode;
  final ValueChanged<EraserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.pixel,
            icon: StarNoteIcons.sparkle,
            label: 'Piksel',
            isSelected: selectedMode == EraserMode.pixel,
            onTap: () => onModeSelected(EraserMode.pixel),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.stroke,
            icon: StarNoteIcons.broom,
            label: 'Çizgi',
            isSelected: selectedMode == EraserMode.stroke,
            onTap: () => onModeSelected(EraserMode.stroke),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.lasso,
            icon: StarNoteIcons.selection,
            label: 'Kement',
            isSelected: selectedMode == EraserMode.lasso,
            onTap: () => onModeSelected(EraserMode.lasso),
            isPremium: true,
          ),
        ),
      ],
    );
  }
}

/// A single eraser mode option button - compact version.
class _EraserModeOption extends StatelessWidget {
  const _EraserModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPremium = false,
  });

  final EraserMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.1) 
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                if (isPremium)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: PhosphorIcon(
                      StarNoteIcons.lock,
                      size: 9,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/panels/eraser_preview_painter.dart';
import 'package:drawing_ui/src/panels/eraser_settings_widgets.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Eraser settings panel — matches pen/highlighter panel design pattern.
class EraserSettingsPanel extends ConsumerWidget {
  const EraserSettingsPanel({super.key});

  static const _eraserTools = [
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final active =
        _eraserTools.contains(currentTool) ? currentTool : ToolType.pixelEraser;
    final settings = ref.watch(eraserSettingsProvider);
    final showSizeSlider = settings.mode != EraserMode.lasso;
    final palette = ChromePalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: _titleForMode(active),
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          EraserPreview(mode: settings.mode, size: settings.size),
          const SizedBox(height: ChromeSpacing.sm),
          EraserTypeSelector(
            selectedType: active,
            onTypeSelected: (t) {
              ref.read(currentToolProvider.notifier).selectTool(t);
              final mode = _toolTypeToMode(t);
              ref.read(eraserSettingsProvider.notifier).setMode(mode);
            },
          ),
          const ChromeHairline(),
          if (showSizeSlider)
            GoodNotesSlider(
              label: 'Boyut',
              value: settings.size.clamp(5.0, 100.0),
              min: 5.0,
              max: 100.0,
              displayValue: '${settings.size.round()}px',
              activeColor: palette.accent,
              onChanged: (v) =>
                  ref.read(eraserSettingsProvider.notifier).setSize(v),
            ),
          CompactToggle(
            label: 'Basınç hassasiyeti',
            value: settings.pressureSensitive,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setPressureSensitive(v),
          ),
          CompactToggle(
            label: 'Sadece vurgulayıcı sil',
            value: settings.eraseOnlyHighlighter,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setEraseOnlyHighlighter(v),
          ),
          CompactToggle(
            label: 'Otomatik kaldır',
            value: settings.autoLift,
            onChanged: (v) =>
                ref.read(eraserSettingsProvider.notifier).setAutoLift(v),
          ),
          const ChromeHairline(),
          ClearPageButton(
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  String _titleForMode(ToolType tool) {
    return switch (tool) {
      ToolType.pixelEraser => 'Piksel Silgi',
      ToolType.strokeEraser => 'Çizgi Silgisi',
      ToolType.lassoEraser => 'Kement Silgisi',
      _ => 'Silgi',
    };
  }

  static EraserMode _toolTypeToMode(ToolType t) {
    return switch (t) {
      ToolType.pixelEraser => EraserMode.pixel,
      ToolType.strokeEraser => EraserMode.stroke,
      ToolType.lassoEraser => EraserMode.lasso,
      _ => EraserMode.pixel,
    };
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Read values before closing panel to avoid ref-after-dispose
    final document = ref.read(documentProvider);
    final historyManager = ref.read(historyManagerProvider.notifier);

    // Close the eraser panel so dialog appears on top
    ref.read(activePanelProvider.notifier).state = null;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceElevated,
        title: Text(
          'Sayfayı Temizle?',
          style: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        ),
        content: Text(
          'Bu sayfa içeriğini tamamen silecek. '
          'Bu işlem geri alınamaz.',
          style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              historyManager.execute(
                core.ClearLayerCommand(layerIndex: document.activeLayerIndex),
              );
            },
            style: TextButton.styleFrom(foregroundColor: palette.danger),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

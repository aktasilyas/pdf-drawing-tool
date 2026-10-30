import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/l10n/l10n.dart';
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
    final mode = ref.watch(activeEraserModeProvider);
    final showSizeSlider = mode != EraserMode.lasso;
    final palette = ChromePalette.of(context);
    final str = context.drawingStrings;

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: eraserTypeLabel(active, str),
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          EraserPreview(mode: mode, size: settings.size),
          const SizedBox(height: ChromeSpacing.sm),
          EraserTypeSelector(
            selectedType: active,
            // Selecting the tool also syncs the eraser mode (#237).
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).selectTool(t),
          ),
          const ChromeHairline(),
          if (showSizeSlider)
            GoodNotesSlider(
              label: str.panels.size,
              value: settings.size.clamp(5.0, 100.0),
              min: 5.0,
              max: 100.0,
              displayValue: '${settings.size.round()}px',
              activeColor: palette.accent,
              onChanged: (v) =>
                  ref.read(eraserSettingsProvider.notifier).setSize(v),
            ),
          CompactToggle(
            label: str.panels.eraserPressure,
            value: settings.pressureSensitive,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setPressureSensitive(v),
          ),
          CompactToggle(
            label: str.panels.eraserHighlighterOnly,
            value: settings.eraseOnlyHighlighter,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setEraseOnlyHighlighter(v),
          ),
          CompactToggle(
            label: str.panels.eraserAutoLift,
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
      builder: (ctx) {
        final p = ctx.drawingStrings.panels;
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: Text(
            p.clearPageTitle,
            style: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
          ),
          content: Text(
            p.clearPageMessage,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(p.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (core.ClearPageCommand.isNoop(document.layers)) return;
                historyManager.execute(core.ClearPageCommand());
              },
              style: TextButton.styleFrom(foregroundColor: palette.danger),
              child: Text(p.clearPageConfirm),
            ),
          ],
        );
      },
    );
  }
}

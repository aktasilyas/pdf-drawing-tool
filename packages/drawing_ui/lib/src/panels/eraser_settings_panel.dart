import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/eraser_preview_painter.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Ba\u015fl\u0131k --
          Text(
            _titleForMode(active),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // -- Eraser Preview --
          EraserPreview(mode: settings.mode, size: settings.size),
          const SizedBox(height: 16),

          // -- Eraser Type Selector --
          _EraserTypeSelector(
            selectedType: active,
            onTypeSelected: (t) {
              ref.read(currentToolProvider.notifier).state = t;
              final mode = _toolTypeToMode(t);
              ref.read(eraserSettingsProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 20),

          // -- BOYUT slider --
          if (showSizeSlider) ...[
            GoodNotesSlider(
              label: 'BOYUT',
              value: settings.size.clamp(5.0, 100.0),
              min: 5.0,
              max: 100.0,
              displayValue: '${settings.size.round()}px',
              activeColor: cs.primary,
              onChanged: (v) =>
                  ref.read(eraserSettingsProvider.notifier).setSize(v),
            ),
            const SizedBox(height: 8),
          ],

          // -- Toggles --
          CompactToggle(
            label: 'Bas\u0131n\u00e7 hassasiyeti',
            value: settings.pressureSensitive,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setPressureSensitive(v),
          ),
          CompactToggle(
            label: 'Sadece vurgulay\u0131c\u0131 sil',
            value: settings.eraseOnlyHighlighter,
            onChanged: (v) => ref
                .read(eraserSettingsProvider.notifier)
                .setEraseOnlyHighlighter(v),
          ),
          CompactToggle(
            label: 'Sadece bant sil',
            value: settings.eraseBandOnly,
            onChanged: (v) =>
                ref.read(eraserSettingsProvider.notifier).setEraseBandOnly(v),
          ),
          CompactToggle(
            label: 'Otomatik kald\u0131r',
            value: settings.autoLift,
            onChanged: (v) =>
                ref.read(eraserSettingsProvider.notifier).setAutoLift(v),
          ),
          const SizedBox(height: 8),

          // -- Clear page action --
          _CompactActionButton(
            label: 'Sayfay\u0131 Temizle',
            icon: StarNoteIcons.trash,
            isDestructive: true,
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  String _titleForMode(ToolType tool) {
    return switch (tool) {
      ToolType.pixelEraser => 'Piksel Silgi',
      ToolType.strokeEraser => '\u00c7izgi Silgisi',
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
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Sayfay\u0131 Temizle?',
            style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Bu sayfa i\u00e7eri\u011fini tamamen silecek. '
          'Bu i\u015flem geri al\u0131namaz.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u0130ptal'),
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

// ---------------------------------------------------------------------------
// Eraser Type Selector (matches _HighlighterTypeSelector style)
// ---------------------------------------------------------------------------

class _EraserTypeSelector extends StatelessWidget {
  const _EraserTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final ValueChanged<ToolType> onTypeSelected;

  static const _types = [
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _types.map((t) {
        final selected = t == selectedType;
        final icon = _iconFor(t, selected);
        return GestureDetector(
          onTap: () => onTypeSelected(t),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  static IconData _iconFor(ToolType type, bool selected) {
    return switch (type) {
      ToolType.pixelEraser => selected
          ? PhosphorIconsRegular.sparkle
          : PhosphorIconsLight.sparkle,
      ToolType.strokeEraser => selected
          ? PhosphorIconsRegular.broom
          : PhosphorIconsLight.broom,
      ToolType.lassoEraser => selected
          ? PhosphorIconsRegular.selection
          : PhosphorIconsLight.selection,
      _ => PhosphorIconsLight.eraser,
    };
  }
}

// ---------------------------------------------------------------------------
// Compact Action Button
// ---------------------------------------------------------------------------

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

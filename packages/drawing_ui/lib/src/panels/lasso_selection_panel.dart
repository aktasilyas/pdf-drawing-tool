import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/panels/selection_preview_painter.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Settings panel for the lasso (kement) selection tool.
///
/// Matches the eraser/highlighter panel design pattern with preview,
/// icon-based type selector, and selectable types grid.
class LassoSelectionPanel extends ConsumerWidget {
  const LassoSelectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(lassoSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Title + Close --
          Row(
            children: [
              Expanded(
                child: Text(
                  _titleForMode(settings.mode),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              PanelCloseButton(
                onTap: () =>
                    ref.read(activePanelProvider.notifier).state = null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -- Selection Preview --
          SelectionPreview(mode: settings.mode),
          const SizedBox(height: 16),

          // -- Selection Type Selector (40x40 icon buttons) --
          _SelectionTypeSelector(
            selectedMode: settings.mode,
            onModeSelected: (mode) {
              ref.read(lassoSettingsProvider.notifier).setMode(mode);
              final selectionType = mode == LassoMode.freeform
                  ? SelectionType.lasso
                  : SelectionType.rectangle;
              ref.read(activeSelectionToolTypeProvider.notifier).state =
                  selectionType;
            },
          ),
          const SizedBox(height: 20),

          // -- Section label --
          Text(
            'Seçilebilir',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // -- Selectable types grid --
          _SelectableTypesGrid(
            selectableTypes: settings.selectableTypes,
            onTypeChanged: (type, value) {
              ref.read(lassoSettingsProvider.notifier)
                  .setSelectableType(type, value);
            },
          ),
        ],
      ),
    );
  }

  String _titleForMode(LassoMode mode) {
    return switch (mode) {
      LassoMode.freeform => 'Serbest Seçim',
      LassoMode.rectangle => 'Dikdörtgen Seçim',
    };
  }
}

// ---------------------------------------------------------------------------
// Selection Type Selector (matches _EraserTypeSelector style)
// ---------------------------------------------------------------------------

class _SelectionTypeSelector extends StatelessWidget {
  const _SelectionTypeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LassoMode selectedMode;
  final ValueChanged<LassoMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: LassoMode.values.map((mode) {
        final selected = mode == selectedMode;
        final icon = _iconFor(mode, selected);
        return GestureDetector(
          onTap: () => onModeSelected(mode),
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

  static IconData _iconFor(LassoMode mode, bool selected) {
    return switch (mode) {
      LassoMode.freeform => selected
          ? PhosphorIconsRegular.selection
          : PhosphorIconsLight.selection,
      LassoMode.rectangle => selected
          ? PhosphorIconsRegular.boundingBox
          : PhosphorIconsLight.boundingBox,
    };
  }
}

// ---------------------------------------------------------------------------
// Selectable Types Grid
// ---------------------------------------------------------------------------

class _SelectableTypesGrid extends StatelessWidget {
  const _SelectableTypesGrid({
    required this.selectableTypes,
    required this.onTypeChanged,
  });

  final Map<SelectableType, bool> selectableTypes;
  final void Function(SelectableType, bool) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final types = [
      (SelectableType.handwriting, 'El yazısı', StarNoteIcons.pencil),
      (SelectableType.shape, 'Şekil', StarNoteIcons.shapes),
      (SelectableType.imageSticker, 'Resim', StarNoteIcons.image),
      (SelectableType.highlighter, 'Vurgulayıcı', StarNoteIcons.highlighter),
      (SelectableType.textBox, 'Metin', StarNoteIcons.textT),
      (SelectableType.tape, 'Bant', StarNoteIcons.ruler),
      (SelectableType.link, 'Link', StarNoteIcons.link),
      (SelectableType.label, 'Etiket', StarNoteIcons.tag),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((t) {
        final isSelected = selectableTypes[t.$1] ?? true;
        return _TypeChip(
          label: t.$2,
          icon: t.$3,
          isSelected: isSelected,
          onTap: () => onTypeChanged(t.$1, !isSelected),
        );
      }).toList(),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer
              : (isDark
                  ? cs.surfaceContainerHigh
                  : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

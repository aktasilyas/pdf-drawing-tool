import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/panels/selection_preview_painter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

String _titleForMode(LassoMode mode, DrawingStrings s) {
  return switch (mode) {
    LassoMode.freeform => s.selection.lassoFreeform,
    LassoMode.rectangle => s.selection.lassoRectangle,
  };
}

/// Settings panel for the lasso (kement) selection tool.
///
/// Matches the eraser/highlighter panel design pattern with preview,
/// icon-based type selector, and selectable types grid.
class LassoSelectionPanel extends ConsumerWidget {
  const LassoSelectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(lassoSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: _titleForMode(settings.mode, context.drawingStrings),
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          SelectionPreview(mode: settings.mode),
          const SizedBox(height: ChromeSpacing.sm),
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
          const ChromeHairline(),
          ChromeSectionLabel(context.drawingStrings.selection.lassoSelectable),
          _SelectableTypesGrid(
            selectableTypes: settings.selectableTypes,
            onTypeChanged: (type, value) {
              ref
                  .read(lassoSettingsProvider.notifier)
                  .setSelectableType(type, value);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selection Type Selector
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: LassoMode.values.map((mode) {
        return ChromeIconButton(
          key: ValueKey('lasso-mode-${mode.name}'),
          icon: _iconFor(mode, false),
          selectedIcon: _iconFor(mode, true),
          iconSize: ChromeIconSizes.md,
          tooltip: _titleForMode(mode, context.drawingStrings),
          selected: mode == selectedMode,
          onPressed: () => onModeSelected(mode),
        );
      }).toList(),
    );
  }

  static IconData _iconFor(LassoMode mode, bool selected) {
    return switch (mode) {
      LassoMode.freeform =>
        selected ? PhosphorIconsRegular.lasso : PhosphorIconsLight.lasso,
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
    final s = context.drawingStrings.selection;
    final types = [
      (SelectableType.handwriting, s.typeHandwriting, ElyanotesIcons.pencil),
      (SelectableType.shape, s.typeShape, ElyanotesIcons.shapes),
      (SelectableType.imageSticker, s.typeImage, ElyanotesIcons.image),
      (
        SelectableType.highlighter,
        s.typeHighlighter,
        ElyanotesIcons.highlighter
      ),
      (SelectableType.textBox, s.typeText, ElyanotesIcons.textT),
      (SelectableType.tape, s.typeTape, ElyanotesIcons.ruler),
      (SelectableType.link, s.typeLink, ElyanotesIcons.link),
      (SelectableType.label, s.typeLabel, ElyanotesIcons.tag),
    ];

    return Wrap(
      spacing: ChromeSpacing.sm,
      runSpacing: 0,
      children: types.map((t) {
        final isSelected = selectableTypes[t.$1] ?? true;
        return _TypeChip(
          key: ValueKey('lasso-type-${t.$1.name}'),
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
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _visualHeight = 40;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final color = isSelected ? palette.accent : palette.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 4 + 40 + 4 = the 48dp hit row.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.xs),
          child: _chip(context, color),
        ),
      ),
    );
  }

  /// The pill is a 40dp visual inside the 48dp hit row, like
  /// `ChromeIconButton`.
  Widget _chip(BuildContext context, Color color) {
    final palette = ChromePalette.of(context);
    return Container(
      height: _visualHeight,
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? palette.accentContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(ChromeRadius.full),
        border: Border.all(
          color: isSelected ? palette.accent : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ChromeIconSizes.sm, color: color),
          const SizedBox(width: ChromeSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the lasso (kement) selection tool.
///
/// Compact design showing all options without scrolling.
class LassoSelectionPanel extends ConsumerWidget {
  const LassoSelectionPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(lassoSettingsProvider);

    return ToolPanel(
      title: 'Kement',
      onClose: onClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact mode selector
          _CompactModeSelector(
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
          const SizedBox(height: 12),

          // Compact selectable types as chips
          Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return Text(
                'Seçilebilir',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
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
}

/// Compact mode selector with two inline buttons.
class _CompactModeSelector extends StatelessWidget {
  const _CompactModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final LassoMode selectedMode;
  final ValueChanged<LassoMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: StarNoteIcons.selection,
              label: 'Serbest',
              isSelected: selectedMode == LassoMode.freeform,
              onTap: () => onModeSelected(LassoMode.freeform),
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: StarNoteIcons.shapes,
              label: 'Dikdörtgen',
              isSelected: selectedMode == LassoMode.rectangle,
              onTap: () => onModeSelected(LassoMode.rectangle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? colorScheme.surface : colorScheme.surface) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: (isDark ? 40 : 20) / 255.0),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact grid of selectable type chips.
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer 
              : (isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary.withValues(alpha: 0.5) 
                : colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

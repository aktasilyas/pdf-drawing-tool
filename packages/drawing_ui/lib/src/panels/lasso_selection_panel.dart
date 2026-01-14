import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
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
          const Text(
            'Seçilebilir',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.gesture,
              label: 'Serbest',
              isSelected: selectedMode == LassoMode.freeform,
              onTap: () => onModeSelected(LassoMode.freeform),
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: Icons.crop_square,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
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
      (SelectableType.handwriting, 'El yazısı', Icons.edit),
      (SelectableType.shape, 'Şekil', Icons.category_outlined),
      (SelectableType.imageSticker, 'Resim', Icons.image_outlined),
      (SelectableType.highlighter, 'Vurgulayıcı', Icons.highlight),
      (SelectableType.textBox, 'Metin', Icons.text_fields),
      (SelectableType.tape, 'Bant', Icons.straighten),
      (SelectableType.link, 'Link', Icons.link),
      (SelectableType.label, 'Etiket', Icons.label_outline),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

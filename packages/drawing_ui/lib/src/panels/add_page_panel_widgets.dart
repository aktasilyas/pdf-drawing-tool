import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

/// Position where the new page should be inserted.
enum AddPagePosition {
  before('Önce'),
  after('Sonra'),
  lastPage('Son sayfa');

  const AddPagePosition(this.label);
  final String label;
}

/// Segmented control for selecting where the new page should be inserted.
class AddPagePositionSelector extends StatelessWidget {
  const AddPagePositionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AddPagePosition selected;
  final ValueChanged<AddPagePosition> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<AddPagePosition>(
        segments: AddPagePosition.values
            .map((pos) => ButtonSegment<AddPagePosition>(
                  value: pos,
                  label: Text(pos.label),
                ))
            .toList(),
        selected: {selected},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 13, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A single quick-access template thumbnail with label.
class QuickTemplateThumbnail extends StatelessWidget {
  const QuickTemplateThumbnail({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final Template template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: TemplatePreviewWidget(
                template: template,
                size: const Size(68, 92),
                borderRadius: BorderRadius.circular(5),
                showBorder: false,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

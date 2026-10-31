import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

/// Position where the new page should be inserted.
enum AddPagePosition { before, after, lastPage }

/// Localized label of an [AddPagePosition].
String addPagePositionLabel(PageListStrings strings, AddPagePosition pos) =>
    switch (pos) {
      AddPagePosition.before => strings.positionBefore,
      AddPagePosition.after => strings.positionAfter,
      AddPagePosition.lastPage => strings.lastPage,
    };

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
    final strings = context.drawingStrings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<AddPagePosition>(
        segments: AddPagePosition.values
            .map((pos) => ButtonSegment<AddPagePosition>(
                  value: pos,
                  label: Text(addPagePositionLabel(strings.pageList, pos)),
                ))
            .toList(),
        selected: {selected},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A single quick-access template thumbnail with label.
///
/// Exposed to accessibility services as one selectable button named after
/// the template; the whole cell (well above 48dp) is the tap area.
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

  static const double _previewWidth = 68;

  /// Size of the page preview inside the border.
  static const Size previewSize = Size(_previewWidth, 92);

  /// Room for the selected (thickest) border: 2dp on each side.
  static const double _borderAllowance = 2 * ChromeSpacing.xxs;

  /// Cell width: the preview plus the selected border.
  static const double width = _previewWidth + _borderAllowance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = context.drawingStrings.templates.templateName(template);

    final cell = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radii moved from 6/5 literals to the chrome scale (8, inner 6
            // so the preview stays concentric inside the 2dp border).
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ChromeRadius.sm),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: TemplatePreviewWidget(
                template: template,
                size: previewSize,
                borderRadius:
                    BorderRadius.circular(ChromeRadius.sm - ChromeSpacing.xxs),
                showBorder: false,
              ),
            ),
            const SizedBox(height: ChromeSpacing.xs),
            Text(
              name,
              style: theme.textTheme.labelSmall?.copyWith(
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

    // One node per thumbnail: the caption is not read a second time, and the
    // selection (shown only by colour) is announced.
    return Semantics(
      button: true,
      selected: isSelected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: cell,
    );
  }
}

/// Header row with title and close button for AddPagePanel.
class AddPageHeader extends StatelessWidget {
  const AddPageHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.drawingStrings.pageList.addPage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              ElyanotesIcons.close,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: onClose,
            tooltip: context.drawingStrings.panels.close,
            splashRadius: 20,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

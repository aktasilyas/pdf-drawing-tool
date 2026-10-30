import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';

/// TemplateCategory.iconName → IconData mapping
IconData _categoryIcon(String iconName) {
  switch (iconName) {
    case 'description':
      return Icons.description_outlined;
    case 'work':
      return Icons.work_outline;
    case 'palette':
      return Icons.palette_outlined;
    case 'star':
      return Icons.star_outline;
    case 'calendar_today':
      return Icons.calendar_today_outlined;
    case 'auto_stories':
      return Icons.auto_stories_outlined;
    case 'school':
      return Icons.school_outlined;
    case 'checklist':
      return Icons.checklist_outlined;
    default:
      return Icons.description_outlined;
  }
}

/// Kategori sekmeleri - responsive, horizontal scroll
class CategoryTabs extends StatelessWidget {
  final TemplateCategory? selectedCategory;
  final ValueChanged<TemplateCategory?> onCategorySelected;
  final bool showAllOption;

  const CategoryTabs({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = context.drawingStrings.templates;

    // 48dp row: every chip's tap target meets the platform minimum.
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption)
            _CategoryChip(
              label: s.allCategories,
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
              colorScheme: colorScheme,
            ),
          ...TemplateCategory.values.map((category) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CategoryChip(
                  label: s.categoryName(category),
                  icon: _categoryIcon(category.iconName),
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                  colorScheme: colorScheme,
                ),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: contentColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: contentColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    // The pill keeps its 40dp look; the tap target fills the 48dp row.
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(child: SizedBox(height: 40, child: chip)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

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

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption)
            _CategoryChip(
              label: 'Tümü',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
              colorScheme: colorScheme,
            ),
          ...TemplateCategory.values.map((category) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _CategoryChip(
              label: category.displayName,
              isSelected: selectedCategory == category,
              isPremium: category.isPremium,
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
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    this.isPremium = false,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isPremium && !isSelected) ...[
              const SizedBox(width: 4),
              PhosphorIcon(
                StarNoteIcons.crown,
                size: 14,
                color: colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ElyaNotes Template Category Tabs - Horizontal scrolling category chips
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';

/// TemplateCategory.iconName → IconData mapping
IconData categoryIcon(String iconName) {
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

/// Template category tabs widget — null = "All"
class TemplateCategoryTabs extends StatelessWidget {
  final TemplateCategory? selectedCategory;
  final ValueChanged<TemplateCategory?> onCategorySelected;

  const TemplateCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(
              label: l10n.libraryTemplateCategoryAll,
              icon: Icons.apps_outlined,
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
          ),
          ...TemplateCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: localizedName(
                  l10n,
                  tr: category.displayName,
                  en: category.displayNameEn,
                ),
                icon: categoryIcon(category.iconName),
                isSelected: isSelected,
                onTap: () => onCategorySelected(category),
              ),
            );
          }),
        ],
      ),
    );
  }
}

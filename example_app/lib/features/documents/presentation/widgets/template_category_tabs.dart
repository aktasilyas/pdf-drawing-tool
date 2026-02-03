/// StarNote Template Category Tabs - Horizontal scrolling category chips
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

/// Template category tabs widget
class TemplateCategoryTabs extends StatelessWidget {
  final TemplateCategory selectedCategory;
  final ValueChanged<TemplateCategory> onCategorySelected;

  const TemplateCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: TemplateCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(
              label: category.displayName,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

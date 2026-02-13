/// StarNote Document Card Helper Widgets
///
/// Doküman kartı için yardımcı widget'lar.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Selection checkbox for document card
class DocumentSelectionCheckbox extends StatelessWidget {
  final bool isSelected;
  const DocumentSelectionCheckbox({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
          : null,
    );
  }
}

/// Favorite button for document card
class DocumentFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const DocumentFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                  .withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.star : Icons.star_outline,
              size: AppIconSize.sm,
              color: isFavorite
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page count badge for document card
class DocumentPageCountBadge extends StatelessWidget {
  final int count;
  const DocumentPageCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$count sayfa',
        style: AppTypography.caption.copyWith(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          fontSize: 9,
        ),
      ),
    );
  }
}

/// Days left badge for trashed documents
class DocumentDaysLeftBadge extends StatelessWidget {
  final DateTime deletedAt;
  const DocumentDaysLeftBadge({super.key, required this.deletedAt});

  @override
  Widget build(BuildContext context) {
    final daysLeft = 30 - DateTime.now().difference(deletedAt).inDays;
    final clampedDays = daysLeft.clamp(0, 30);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: clampedDays <= 7 ? AppColors.error : AppColors.warning,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$clampedDays gün',
        style: AppTypography.caption.copyWith(
          color: clampedDays <= 7 ? AppColors.onError : AppColors.onWarning,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Paper color utility for document card
class DocumentPaperColors {
  DocumentPaperColors._();

  static Color fromName(String paperColor) {
    switch (paperColor) {
      case 'Beyaz kağıt':
        return AppColors.surfaceLight;
      case 'Sarı kağıt':
      case 'Krem kağıt':
        return AppColors.paperCream;
      case 'Gri kağıt':
      case 'Açık Gri':
        return AppColors.surfaceVariantLight;
      case 'Siyah kağıt':
        return AppColors.surfaceDark;
      default:
        return AppColors.paperCream;
    }
  }
}

/// Date formatter for document card
class DocumentDateFormatter {
  DocumentDateFormatter._();

  static const _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara'
  ];

  static String format(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}

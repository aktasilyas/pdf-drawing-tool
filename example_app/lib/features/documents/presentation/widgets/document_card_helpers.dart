/// ElyaNotes Document Card Helper Widgets
///
/// Doküman kartı için yardımcı widget'lar (gün rozeti, kağıt rengi, tarih).
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';

/// Days left badge for trashed documents and pages.
///
/// 7 days or fewer: `danger`; otherwise a quiet elevated chip.
class DocumentDaysLeftBadge extends StatelessWidget {
  final DateTime deletedAt;
  const DocumentDaysLeftBadge({super.key, required this.deletedAt});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final daysLeft = 30 - DateTime.now().difference(deletedAt).inDays;
    final clampedDays = daysLeft.clamp(0, 30);
    final urgent = clampedDays <= 7;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: urgent ? palette.danger : palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$clampedDays gün',
        style: AppTypography.labelMedium.copyWith(
          color: urgent ? palette.onDanger : palette.textMuted,
        ),
      ),
    );
  }
}

/// Paper color utility for document card.
/// Paper colors are document data, not theme roles: they stay fixed in both
/// light and dark mode (intentional, not migrated to AppPalette).
class DocumentPaperColors {
  DocumentPaperColors._();

  static Color fromName(String paperColor) {
    final color = PaperColor.tryParse(paperColor);
    if (color == null) return AppColors.paperCream;
    switch (color) {
      case PaperColor.white:
        return AppColors.surfaceLight;
      case PaperColor.gray:
        return AppColors.surfaceVariantLight;
      case PaperColor.black:
        return AppColors.surfaceDark;
      case PaperColor.green:
      case PaperColor.blue:
        // Document data, not a theme role (see class doc).
        return Color(color.argb);
      case PaperColor.cream:
      case PaperColor.yellow:
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

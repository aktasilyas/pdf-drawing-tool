/// StarNote Design System - AppSectionHeader Component
///
/// Bölüm başlığı komponenti.
///
/// Kullanım:
/// ```dart
/// AppSectionHeader(
///   title: 'Son Dökümanlar',
///   trailing: TextButton(
///     onPressed: viewAll,
///     child: Text('Tümünü Gör'),
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// StarNote section header komponenti.
///
/// Liste bölümlerini ayırmak için kullanılır.
class AppSectionHeader extends StatelessWidget {
  /// Bölüm başlığı.
  final String title;

  /// Sağ taraftaki widget (örn: "Tümünü Gör" butonu).
  final Widget? trailing;

  /// İç boşluk.
  final EdgeInsets padding;

  const AppSectionHeader({
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

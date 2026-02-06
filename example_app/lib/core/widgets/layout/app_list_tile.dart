/// StarNote Design System - AppListTile Component
///
/// Modern liste item komponenti.
/// Selected state: sol kenar 3px primary bar.
///
/// Kullanım:
/// ```dart
/// AppListTile(
///   leading: Icon(Icons.folder),
///   title: 'Dokümanlar',
///   subtitle: '12 dosya',
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => navigate(),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// StarNote modern list tile komponenti.
///
/// Modern tasarım kuralları:
/// - Vertical padding: 14-16dp (daha fazla nefes alanı)
/// - Title-subtitle arası: 2dp
/// - Selected state: sol kenar 3px primary bar (border değil)
/// - Hover: hafif surfaceVariant
class AppListTile extends StatelessWidget {
  /// Sol taraftaki widget (icon, avatar vb.).
  final Widget? leading;

  /// Başlık.
  final String title;

  /// Alt başlık.
  final String? subtitle;

  /// Sağ taraftaki widget (icon, button vb.).
  final Widget? trailing;

  /// Tıklama callback'i.
  final VoidCallback? onTap;

  /// Uzun basma callback'i.
  final VoidCallback? onLongPress;

  /// Seçili durumu (sol kenar 3px primary bar gösterir).
  final bool isSelected;

  /// Alt çizgi gösterilsin mi?
  final bool showDivider;

  const AppListTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showDivider = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final hoverColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final dividerColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Main content with hover effect
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                hoverColor: hoverColor.withValues(alpha: 0.5),
                splashColor: hoverColor,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14, // Daha fazla vertical padding (12→14)
                    ),
                    child: Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: textPrimary,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(
                                    height: 2), // Title-subtitle: 2dp
                                Text(
                                  subtitle!,
                                  style: AppTypography.caption.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          // Trailing daha subtle
                          IconTheme(
                            data: IconThemeData(
                              color: textSecondary,
                              size: AppIconSize.md,
                            ),
                            child: trailing!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Selected indicator: sol kenar 3px primary bar
            if (isSelected)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: AppSpacing.lg,
          ),
      ],
    );
  }
}

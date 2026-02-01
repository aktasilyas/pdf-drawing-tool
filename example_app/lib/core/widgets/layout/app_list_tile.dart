/// StarNote Design System - AppListTile Component
///
/// Liste item komponenti.
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

/// StarNote list tile komponenti.
///
/// Leading, title, subtitle, trailing destekler.
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

  /// Seçili durumu.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color:
              isSelected ? AppColors.surfaceVariantLight : Colors.transparent,
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
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
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineLight,
            indent: AppSpacing.lg,
          ),
      ],
    );
  }
}

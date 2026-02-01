/// StarNote Design System - AppActionSheet Component
///
/// Action sheet komponenti (liste seçimi).
///
/// Kullanım:
/// ```dart
/// final result = await AppActionSheet.show<String>(
///   context: context,
///   title: 'Seçenekler',
///   items: [
///     AppActionSheetItem(
///       icon: Icons.edit,
///       label: 'Düzenle',
///       value: 'edit',
///     ),
///     AppActionSheetItem(
///       icon: Icons.delete,
///       label: 'Sil',
///       value: 'delete',
///       isDestructive: true,
///     ),
///   ],
/// );
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Action sheet item modeli.
class AppActionSheetItem<T> {
  /// Item icon'u (opsiyonel).
  final IconData? icon;

  /// Item label'ı.
  final String label;

  /// Item değeri.
  final T value;

  /// Destructive action mı? (kırmızı renk).
  final bool isDestructive;

  const AppActionSheetItem({
    this.icon,
    required this.label,
    required this.value,
    this.isDestructive = false,
  });
}

/// StarNote action sheet komponenti.
///
/// Bottom sheet olarak açılır, itemlardan biri seçilir.
class AppActionSheet {
  /// Action sheet göster.
  ///
  /// Returns: Seçilen item'ın value'su veya null (iptal/dismiss).
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<AppActionSheetItem<T>> items,
    AppActionSheetItem<T>? cancelItem,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => _ActionSheetContent(
        title: title,
        items: items,
        cancelItem: cancelItem,
      ),
    );
  }
}

class _ActionSheetContent<T> extends StatelessWidget {
  final String? title;
  final List<AppActionSheetItem<T>> items;
  final AppActionSheetItem<T>? cancelItem;

  const _ActionSheetContent({
    required this.title,
    required this.items,
    required this.cancelItem,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.outlineVariantLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Title
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                title!,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Items
          ...items.map(
            (item) => _ActionSheetTile(
              icon: item.icon,
              label: item.label,
              isDestructive: item.isDestructive,
              onTap: () => Navigator.of(context).pop(item.value),
            ),
          ),
          // Divider before cancel
          if (cancelItem != null) ...[
            const Divider(height: 1),
            _ActionSheetTile(
              icon: cancelItem!.icon,
              label: cancelItem!.label,
              isDestructive: cancelItem!.isDestructive,
              onTap: () => Navigator.of(context).pop(cancelItem!.value),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionSheetTile({
    this.icon,
    required this.label,
    required this.isDestructive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimaryLight;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppIconSize.lg,
                color: color,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

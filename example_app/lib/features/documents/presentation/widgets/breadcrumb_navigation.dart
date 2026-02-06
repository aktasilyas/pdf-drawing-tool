/// StarNote Breadcrumb Navigation Widget
///
/// Klasör path navigasyonu için kullanılır.
/// Tıklanabilir segmentler ile üst klasörlere dönüş imkanı sağlar.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Breadcrumb item model
class BreadcrumbItem {
  /// Folder ID - null ise root anlamına gelir
  final String? folderId;

  /// Gösterilecek label
  final String label;

  const BreadcrumbItem({
    this.folderId,
    required this.label,
  });
}

/// Breadcrumb navigation widget
///
/// Kullanım:
/// ```dart
/// BreadcrumbNavigation(
///   items: [
///     BreadcrumbItem(folderId: null, label: 'Belgelerim'),
///     BreadcrumbItem(folderId: 'folder1', label: 'İş Notları'),
///     BreadcrumbItem(folderId: 'folder2', label: 'Toplantılar'),
///   ],
///   onItemTap: (item) => navigateToFolder(item.folderId),
/// )
/// ```
class BreadcrumbNavigation extends StatelessWidget {
  /// Breadcrumb item listesi (root'tan current'a doğru sıralı)
  final List<BreadcrumbItem> items;

  /// Item tıklandığında çağrılır
  final ValueChanged<BreadcrumbItem>? onItemTap;

  /// Geri butonu gösterilsin mi?
  final bool showBackButton;

  /// Geri butonuna tıklandığında çağrılır
  final VoidCallback? onBackPressed;

  const BreadcrumbNavigation({
    super.key,
    required this.items,
    this.onItemTap,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: AppSpacing.minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Back button
          if (showBackButton && items.length > 1) ...[
            _BackButton(onPressed: onBackPressed),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Breadcrumb items (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildItems(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems() {
    final widgets = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      // Separator (except for first item)
      if (i > 0) {
        widgets.add(const _Separator());
      }

      // Item
      widgets.add(
        _BreadcrumbItemWidget(
          item: item,
          isActive: isLast,
          onTap: isLast ? null : () => onItemTap?.call(item),
        ),
      );
    }

    return widgets;
  }
}

/// Geri butonu widget
class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back,
            size: AppIconSize.md,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

/// Separator (chevron_right icon)
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
    );
  }
}

/// Breadcrumb item widget
class _BreadcrumbItemWidget extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isActive;
  final VoidCallback? onTap;

  const _BreadcrumbItemWidget({
    required this.item,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            item.label,
            style: AppTypography.bodyMedium.copyWith(
              color: isActive
                  ? (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// StarNote Design System - AppEmptyState Component
///
/// Boş durum göstergesi.
///
/// Kullanım:
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'Hiç doküman yok',
///   description: 'Yeni bir doküman oluşturarak başlayın',
///   actionLabel: 'Yeni Doküman',
///   onAction: createDocument,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import '../../theme/tokens/index.dart';
import '../buttons/index.dart';

/// StarNote empty state komponenti.
///
/// Boş liste/sayfa durumlarında kullanılır.
class AppEmptyState extends StatelessWidget {
  /// Gösterilecek icon.
  final IconData icon;

  /// Ana başlık.
  final String title;

  /// Açıklama metni (opsiyonel).
  final String? description;

  /// Aksiyon buton label'ı (opsiyonel).
  final String? actionLabel;

  /// Aksiyon buton callback'i (opsiyonel).
  final VoidCallback? onAction;

  const AppEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.emptyState,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

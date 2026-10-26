import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

/// Full-screen error shown when the editor cannot load a document.
///
/// Shows fixed, localized copy (never the raw exception) with a way to retry
/// the load and a way back to the library.
class EditorLoadErrorView extends StatelessWidget {
  const EditorLoadErrorView({
    super.key,
    required this.onRetry,
    required this.onBack,
  });

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: AppIconSize.emptyState,
                color: palette.danger,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Belge açılamadı',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Belge bulunamadı ya da okunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Geri dön',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.large,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: 'Tekrar dene',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

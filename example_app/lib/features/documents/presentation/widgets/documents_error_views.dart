import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

/// Error state view for documents feature.
///
/// Shows a "Tekrar dene" button when [onRetry] is provided.
class DocumentsErrorView extends StatelessWidget {
  const DocumentsErrorView({super.key, required this.error, this.onRetry});
  final Object error;

  /// Re-runs the failed load (typically `ref.invalidate(provider)`).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.palette.danger,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hata: $error'),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Tekrar dene',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.large,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty folder view for documents feature.
class DocumentsEmptyFolderView extends StatelessWidget {
  const DocumentsEmptyFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bu klasör boş',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

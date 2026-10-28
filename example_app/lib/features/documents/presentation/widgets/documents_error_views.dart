import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Error state view for documents feature.
///
/// Shows a "Try again" button when [onRetry] is provided.
class DocumentsErrorView extends StatelessWidget {
  const DocumentsErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  /// Key of the retry button (for tests).
  static const retryKey = Key('documentsErrorRetry');

  final Object error;

  /// Plain-language text shown instead of the raw [error] detail. When null
  /// the generic "error: detail" copy is used.
  final String? message;

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
          Text(message ?? context.l10n.commonErrorDetail('$error')),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: retryKey,
              label: context.l10n.commonRetry,
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
            context.l10n.libraryEmptyFolderTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Logs a failed library load ([what] names it in the log) and returns the
/// plain error view. The [error] is an English diagnostic for the log only;
/// the user sees [message] (or the generic localized load-failed copy).
Widget libraryLoadErrorView(
  String what,
  Object error,
  StackTrace stackTrace, {
  String? message,
  VoidCallback? onRetry,
}) {
  logger.w('$what failed to load', error: error, stackTrace: stackTrace);
  return DocumentsErrorView(error: error, message: message, onRetry: onRetry);
}

/// Error state view for documents feature.
///
/// Never renders the [error] itself: Failure/exception text is an English
/// diagnostic to be logged by the caller, not shown (#405). Shows a
/// "Try again" button when [onRetry] is provided.
class DocumentsErrorView extends StatelessWidget {
  const DocumentsErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  /// Key of the retry button (for tests).
  static const retryKey = Key('documentsErrorRetry');

  /// The failure, kept for callers and tests; never shown to the user.
  final Object error;

  /// Plain-language text to show. When null the generic localized
  /// "couldn't load" copy is used.
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
          Text(
            message ?? context.l10n.libraryLoadFailed,
            textAlign: TextAlign.center,
          ),
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

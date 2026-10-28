/// ElyaNotes compact inline error row for the sidebar folder section.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Plain-language "couldn't load folders" message with a retry action.
class FoldersLoadErrorRow extends StatelessWidget {
  const FoldersLoadErrorRow({super.key, required this.onRetry});

  /// Key of the retry button (for tests).
  static const retryKey = Key('foldersLoadRetry');

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.libraryFoldersLoadFailed,
              style: AppTypography.caption.copyWith(color: palette.textMuted),
            ),
          ),
          IconButton(
            key: retryKey,
            tooltip: l10n.commonRetry,
            icon: Icon(Icons.refresh, color: palette.accent),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

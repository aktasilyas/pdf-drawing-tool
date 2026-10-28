import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/l10n/l10n.dart';

/// Persistent "Save failed" bar with a Retry action, shown while the last
/// save of the open document failed. Renders nothing otherwise.
class SaveFailureBanner extends ConsumerWidget {
  const SaveFailureBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = ref.watch(saveFailureProvider);
    if (failure == null) return const SizedBox.shrink();

    final palette = context.palette;
    final textStyle = AppTypography.bodyMedium.copyWith(
      color: palette.onDanger,
    );

    return Semantics(
      liveRegion: true,
      child: Material(
        color: palette.danger,
        elevation: 2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: palette.onDanger,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.editorSaveFailedMessage,
                  style: textStyle,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: palette.onDanger,
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                ),
                onPressed: () => ref.read(autoSaveProvider.notifier).retry(),
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

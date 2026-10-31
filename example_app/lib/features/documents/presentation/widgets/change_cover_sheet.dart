/// ElyaNotes Change Cover Sheet - bottom sheet around the cover grid
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' show Cover;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/l10n/l10n.dart';

/// Shows the cover picker for an existing notebook.
///
/// Resolves with the newly picked cover, or `null` when the sheet is closed
/// or the [current] cover is tapped again (nothing to write).
Future<Cover?> showChangeCoverSheet(
  BuildContext context, {
  required Cover current,
  required String title,
}) {
  return showModalBottomSheet<Cover>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          _ChangeCoverHeader(onClose: () => Navigator.pop(ctx)),
          SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.6,
            child: CoverGridView(
              selectedCover: current,
              title: title,
              onCoverSelected: (cover) =>
                  Navigator.pop(ctx, cover.id == current.id ? null : cover),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

class _ChangeCoverHeader extends StatelessWidget {
  const _ChangeCoverHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.libraryCover,
              style: AppTypography.titleLarge
                  .copyWith(color: context.palette.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: context.palette.textMuted,
            tooltip: l10n.commonClose,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

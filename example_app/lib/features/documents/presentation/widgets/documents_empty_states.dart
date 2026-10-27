/// ElyaNotes Documents Empty States
///
/// Empty-state widgets for the library sections.
library;

import 'package:drawing_core/drawing_core.dart' show CoverFamily;
import 'package:drawing_ui/drawing_ui.dart'
    show CoverPreviewWidget, ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/l10n/l10n.dart';

/// Empty state of the "All notes" section.
class DocumentsEmptyState extends StatelessWidget {
  const DocumentsEmptyState({super.key, this.onCreateNew});

  /// Shows the "New note" call to action when non-null.
  final VoidCallback? onCreateNew;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoverPreviewWidget(
                cover: CoverFamily.linenSand,
                width: 120,
                height: 160,
                showBorder: false,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.libraryEmptyTitle,
                style: AppTypography.headlineMedium
                    .copyWith(color: palette.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.libraryEmptyMessage,
                style:
                    AppTypography.bodyMedium.copyWith(color: palette.textMuted),
                textAlign: TextAlign.center,
              ),
              if (onCreateNew != null) ...[
                const SizedBox(height: AppSpacing.xl),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  child: AppButton(
                    label: l10n.libraryEmptyAction,
                    leadingIcon: ElyanotesIcons.libraryPlus,
                    onPressed: onCreateNew,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state of the favorites section.
class FavoritesEmptyState extends StatelessWidget {
  const FavoritesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: Icons.star_outline,
      title: l10n.libraryEmptyFavoritesTitle,
      description: l10n.libraryEmptyFavoritesMessage,
    );
  }
}

/// Empty state of a folder.
class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: Icons.folder_open,
      title: l10n.libraryEmptyFolderTitle,
      description: l10n.libraryEmptyFolderMessage,
    );
  }
}

/// Empty state of the trash.
class TrashEmptyState extends StatelessWidget {
  const TrashEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: Icons.delete_outline,
      title: l10n.libraryTrashEmptyTitle,
      description: l10n.libraryTrashEmptyMessage,
    );
  }
}

/// Empty search result.
class DocumentsEmptySearchResult extends ConsumerWidget {
  final String query;

  const DocumentsEmptySearchResult({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ElyanotesIcons.librarySearch,
              size: AppIconSize.emptyState,
              color: context.palette.textMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.libraryNoResultsTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: context.palette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.libraryNoResultsMessage(query),
              style: AppTypography.bodyMedium.copyWith(
                color: context.palette.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.libraryClearSearch,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              leadingIcon: ElyanotesIcons.libraryClose,
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          ],
        ),
      ),
    );
  }
}

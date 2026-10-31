/// ElyaNotes Selection Mode Header
///
/// Header shown in selection mode: select all, duplicate, move, delete.
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/bulk_result.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_delete.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/l10n/l10n.dart';

class SelectionModeHeader extends ConsumerWidget {
  final List<String> allDocumentIds;
  final List<String> allFolderIds;
  final bool isTrashSection;

  const SelectionModeHeader({
    super.key,
    this.allDocumentIds = const [],
    this.allFolderIds = const [],
    this.isTrashSection = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);
    final hasSelection = selectedDocs.isNotEmpty || selectedFolders.isNotEmpty;
    final totalSelected = selectedDocs.length + selectedFolders.length;
    final palette = context.palette;
    final l10n = context.l10n;

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: Row(
        children: [
          AppIconButton(
            icon: ElyanotesIcons.libraryClose,
            variant: AppIconButtonVariant.ghost,
            tooltip: l10n.commonClose,
            onPressed: () => exitSelectionMode(ref),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.librarySelectedCount(totalSelected),
              style: AppTypography.titleMedium.copyWith(color: palette.accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SelectAllButton(
            allDocumentIds: allDocumentIds,
            allFolderIds: allFolderIds,
          ),
          if (!isTrashSection) ...[
            AppIconButton(
              icon: ElyanotesIcons.libraryCopy,
              variant: AppIconButtonVariant.ghost,
              tooltip: l10n.commonDuplicate,
              onPressed: selectedDocs.isNotEmpty
                  ? () => _duplicateSelected(context, ref, selectedDocs)
                  : null,
            ),
            AppIconButton(
              icon: ElyanotesIcons.libraryMove,
              variant: AppIconButtonVariant.ghost,
              tooltip: l10n.commonMove,
              onPressed: hasSelection
                  ? () =>
                      _moveSelected(context, ref, selectedDocs, selectedFolders)
                  : null,
            ),
          ],
          AppIconButton(
            icon: ElyanotesIcons.libraryTrash,
            variant: AppIconButtonVariant.ghost,
            iconColor: hasSelection ? palette.danger : null,
            tooltip:
                isTrashSection ? l10n.libraryDeleteForever : l10n.commonDelete,
            onPressed: hasSelection
                ? () => deleteSelection(
                      context,
                      ref,
                      selectedDocs: selectedDocs,
                      selectedFolders: selectedFolders,
                      isTrashSection: isTrashSection,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateSelected(
      BuildContext context, WidgetRef ref, Set<String> selectedDocs) async {
    if (selectedDocs.isEmpty) return;

    // Check unified document limit before duplicating
    final totalCount = await ref.read(totalDocumentCountProvider.future);
    final access = ref.read(featureAccessProvider(
      FeatureAccessParams(
        feature: GatedFeature.createDocument,
        currentUsage: totalCount,
      ),
    ));
    if (!access.isAllowed) {
      if (!context.mounted) return;
      await UpgradePromptSheet.show(
        context,
        access: access,
        featureIcon: Icons.note_add_outlined,
        featureTitle: context.l10n.libraryDocumentLimitReached,
        onUpgrade: () {
          Navigator.pop(context);
          GoRouter.of(context).push(RouteNames.paywall);
        },
      );
      return;
    }

    final controller = ref.read(documentsControllerProvider.notifier);
    final result = await controller.duplicateDocuments(
      selectedDocs.toList(),
      copyTitle: context.l10n.libraryCopyTitle,
    );
    if (_keepOnlyFailedSelected(ref, result)) return;
    exitSelectionMode(ref);
    if (context.mounted) {
      AppToast.success(
        context,
        context.l10n.libraryDocumentsCopied(selectedDocs.length),
      );
    }
  }

  /// After a partial failure only the failed ids stay selected, so a retry
  /// does not repeat the items that already succeeded. The failure itself is
  /// shown by `LibraryErrorListener`. Returns whether anything failed.
  bool _keepOnlyFailedSelected(WidgetRef ref, BulkResult result) {
    if (!result.hasFailures) return false;
    ref.read(selectedDocumentsProvider.notifier).state = result.failed.toSet();
    // Bulk document actions ignore folders; drop them so the retry acts on
    // exactly the failed documents.
    ref.read(selectedFoldersProvider.notifier).state = {};
    return true;
  }

  Future<void> _moveSelected(BuildContext context, WidgetRef ref,
      Set<String> selectedDocs, Set<String> selectedFolders) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MoveToFolderDialog(
        documentIds: selectedDocs.toList(),
        folderIds: selectedFolders.toList(),
      ),
    );
    if (result == true) {
      ref.invalidate(foldersProvider);
      ref.invalidate(documentsProvider);
      exitSelectionMode(ref);
    }
  }
}

/// Select all button
class _SelectAllButton extends ConsumerWidget {
  final List<String> allDocumentIds;
  final List<String> allFolderIds;

  const _SelectAllButton({
    required this.allDocumentIds,
    required this.allFolderIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);

    final allDocsSelected =
        allDocumentIds.isEmpty || selectedDocs.length == allDocumentIds.length;
    final allFoldersSelected =
        allFolderIds.isEmpty || selectedFolders.length == allFolderIds.length;
    final allSelected = allDocsSelected &&
        allFoldersSelected &&
        (allDocumentIds.isNotEmpty || allFolderIds.isNotEmpty);

    final muted = context.palette.textMuted;
    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
        splashFactory: NoSplash.splashFactory,
        foregroundColor: muted,
      ),
      onPressed: () {
        if (allSelected) {
          ref.read(selectedDocumentsProvider.notifier).state = {};
          ref.read(selectedFoldersProvider.notifier).state = {};
        } else {
          ref.read(selectedDocumentsProvider.notifier).state =
              allDocumentIds.toSet();
          ref.read(selectedFoldersProvider.notifier).state =
              allFolderIds.toSet();
        }
      },
      icon: Icon(
        allSelected
            ? ElyanotesIcons.libraryCheckSquare
            : ElyanotesIcons.librarySquare,
        size: AppIconSize.md,
        color: muted,
      ),
      label: Text(
        context.l10n.librarySelectAll,
        style: AppTypography.labelLarge.copyWith(color: muted),
      ),
    );
  }
}

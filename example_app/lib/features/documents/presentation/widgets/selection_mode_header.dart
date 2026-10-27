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
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
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
            onPressed: () => _exitSelectionMode(ref),
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
              onPressed: hasSelection
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
                ? () => _deleteSelected(context, ref, selectedDocs)
                : null,
          ),
        ],
      ),
    );
  }

  void _exitSelectionMode(WidgetRef ref) {
    ref.read(selectionModeProvider.notifier).state = false;
    ref.read(selectedDocumentsProvider.notifier).state = {};
    ref.read(selectedFoldersProvider.notifier).state = {};
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
    try {
      await controller.duplicateDocuments(selectedDocs.toList());
      _exitSelectionMode(ref);
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.libraryDocumentsCopied(selectedDocs.length),
        );
      }
    } catch (_) {
      // Shown by LibraryErrorListener.
    }
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
      _exitSelectionMode(ref);
    }
  }

  Future<void> _deleteSelected(
      BuildContext context, WidgetRef ref, Set<String> selectedDocs) async {
    if (selectedDocs.isEmpty) return;

    final l10n = context.l10n;
    final count = selectedDocs.length;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: isTrashSection
          ? l10n.libraryDeleteForeverTitle
          : l10n.libraryDeleteDocumentsTitle,
      message: isTrashSection
          ? l10n.libraryDeleteDocumentsForeverMessage(count)
          : l10n.libraryTrashDocumentsMessage(count),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final controller = ref.read(documentsControllerProvider.notifier);
      try {
        if (isTrashSection) {
          await controller.permanentlyDeleteDocuments(selectedDocs.toList());
        } else {
          await controller.moveDocumentsToTrash(selectedDocs.toList());
        }
        _exitSelectionMode(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            isTrashSection
                ? context.l10n.libraryDocumentsDeleted(count)
                : context.l10n.libraryDocumentsTrashed(count),
          );
        }
      } catch (_) {
        // Shown by LibraryErrorListener.
      }
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

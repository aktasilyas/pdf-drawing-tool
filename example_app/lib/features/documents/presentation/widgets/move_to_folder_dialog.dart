/// ElyaNotes Move to Folder Dialog - Design system dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/move_to_folder_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_create_form.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_list.dart';
import 'package:example_app/l10n/l10n.dart';

/// Dialog for moving documents and folders
class MoveToFolderDialog extends ConsumerStatefulWidget {
  final List<String> documentIds;
  final List<String> folderIds;

  /// Parent for folders created from this dialog. Null creates root folders.
  /// The move flows leave it null.
  final String? parentFolderId;
  const MoveToFolderDialog({
    super.key,
    this.documentIds = const [],
    this.folderIds = const [],
    this.parentFolderId,
  });
  @override
  ConsumerState<MoveToFolderDialog> createState() => _MoveToFolderDialogState();
}

class _MoveToFolderDialogState extends ConsumerState<MoveToFolderDialog> {
  String? _selectedFolderId;
  bool _isCreatingFolder = false;

  bool get _isFolderMode =>
      widget.documentIds.isEmpty && widget.folderIds.isEmpty;
  bool get _isMovingFolder => widget.folderIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.palette.surface;
    final foldersAsync = ref.watch(foldersProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          // Keyboard-safe: SingleChildScrollView wrap
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildHeader(context),
              if (_isCreatingFolder)
                MoveToFolderCreateForm(
                  onCreate: _handleCreateFolder,
                  onCancel: () => setState(() => _isCreatingFolder = false),
                ),
              const AppDivider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: foldersAsync.when(
                  data: (folders) => _buildFolderList(folders),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildError(e),
                ),
              ),
              const AppDivider(),
              _buildActions(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = context.palette.textPrimary;
    final l10n = context.l10n;
    final title = _isFolderMode
        ? l10n.libraryFolderManagement
        : _isMovingFolder
            ? l10n.libraryMoveFolderTitle
            : l10n.libraryMoveToFolderTitle;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(children: [
        Expanded(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge
                  .copyWith(color: textPrimary, fontWeight: FontWeight.bold)),
        ),
        AppIconButton(
            icon: Icons.close,
            variant: AppIconButtonVariant.ghost,
            size: AppIconButtonSize.small,
            tooltip: l10n.commonClose,
            onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Widget _buildFolderList(List<Folder> folders) => MoveToFolderList(
        folders: MoveToFolderActions.targetsFor(folders, widget.folderIds),
        selectedFolderId: _selectedFolderId,
        isMovingFolder: _isMovingFolder,
        onSelected: (id) => setState(() => _selectedFolderId = id),
      );

  Widget _buildError(Object error) {
    final textSecondary = context.palette.textMuted;
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: AppIconSize.emptyState, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.libraryFoldersLoadFailed('$error'),
                style: AppTypography.bodyMedium.copyWith(color: textSecondary)),
          ])),
    );
  }

  Widget _buildActions() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        if (!_isCreatingFolder)
          AppButton(
              label: l10n.libraryNewFolder,
              leadingIcon: Icons.create_new_folder,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              onPressed: () => setState(() => _isCreatingFolder = true)),
        const Spacer(),
        if (_isFolderMode)
          AppButton(
              label: l10n.commonDone,
              onPressed: () => Navigator.pop(context, true))
        else ...[
          AppButton(
              label: l10n.commonCancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(context)),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
              label: l10n.commonMove,
              onPressed: _isMovingFolder || _selectedFolderId != null
                  ? _handleMove
                  : null),
        ],
      ]),
    );
  }

  Future<void> _handleCreateFolder(String name, int colorValue) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppToast.error(context, context.l10n.libraryFolderNameEmpty);
      return;
    }
    final id = await ref.read(moveToFolderActionsProvider).createFolder(
          name: trimmed,
          parentId: widget.parentFolderId,
          colorValue: colorValue,
        );
    if (id != null && mounted) {
      setState(() {
        _selectedFolderId = id;
        _isCreatingFolder = false;
      });
      AppToast.success(context, context.l10n.libraryFolderCreated(trimmed));
    }
    // Failures are shown by LibraryErrorListener.
  }

  Future<void> _handleMove() async {
    final success = await ref.read(moveToFolderActionsProvider).move(
          documentIds: widget.documentIds,
          folderIds: widget.folderIds,
          targetFolderId: _selectedFolderId,
        );
    // Failures are shown by LibraryErrorListener.
    if (success && mounted) Navigator.pop(context, true);
  }
}

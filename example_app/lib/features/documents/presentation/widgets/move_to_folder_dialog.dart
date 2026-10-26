/// ElyaNotes Move to Folder Dialog - Design system dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/inline_folder_color_row.dart';

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
  final _newFolderController = TextEditingController();
  int _selectedColorValue = AppColors.folderColors.first.toARGB32();

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

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
              if (_isCreatingFolder) _buildNewFolderSection(context),
              const AppDivider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: foldersAsync.when(
                  data: (folders) => _buildFolderList(context, folders),
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

    final title = _isFolderMode
        ? 'Klasör Yönetimi'
        : _isMovingFolder
            ? 'Klasörü Taşı'
            : 'Klasöre Taşı';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(children: [
        Text(title,
            style: AppTypography.titleLarge
                .copyWith(color: textPrimary, fontWeight: FontWeight.bold)),
        const Spacer(),
        AppIconButton(
            icon: Icons.close,
            variant: AppIconButtonVariant.ghost,
            size: AppIconButtonSize.small,
            tooltip: 'Kapat',
            onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Widget _buildNewFolderSection(BuildContext context) {
    final surfaceVariant = context.palette.surfaceElevated;
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final outlineColor = context.palette.border;
    final accentColor = context.palette.accent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: surfaceVariant,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.create_new_folder,
                  size: AppIconSize.sm, color: textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('Yeni Klasör',
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold, color: textPrimary)),
              const Spacer(),
              AppButton(
                  label: 'İptal',
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: () => setState(() {
                        _isCreatingFolder = false;
                        _newFolderController.clear();
                      })),
            ]),
            const SizedBox(height: AppSpacing.sm),
            // Klasör adı + önizleme ikonu
            Row(children: [
              Icon(Icons.folder,
                  color: Color(_selectedColorValue), size: AppIconSize.lg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: TextField(
                controller: _newFolderController,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(color: textPrimary),
                cursorColor: accentColor,
                decoration: InputDecoration(
                  hintText: 'Klasör adı girin',
                  hintStyle:
                      AppTypography.bodyMedium.copyWith(color: textSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: outlineColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: outlineColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: accentColor, width: 2)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onSubmitted: (_) => _handleCreateFolder(),
              )),
            ]),
            const SizedBox(height: AppSpacing.md),
            // Renk seçici
            Text('Renk',
                style: AppTypography.caption.copyWith(color: textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            InlineFolderColorRow(
              selectedColorValue: _selectedColorValue,
              onChanged: (v) => setState(() => _selectedColorValue = v),
            ),
            const SizedBox(height: AppSpacing.md),
            // Oluştur butonu
            AppButton(
                label: 'Oluştur',
                size: AppButtonSize.small,
                isExpanded: true,
                onPressed: _handleCreateFolder),
          ]),
    );
  }

  Widget _buildFolderList(BuildContext context, List<Folder> folders) {
    var available = folders;
    if (_isMovingFolder && widget.folderIds.isNotEmpty) {
      final id = widget.folderIds.first;
      available = folders.where((f) => f.id != id && f.parentId != id).toList();
    }
    if (available.isEmpty && !_isMovingFolder) {
      return const AppEmptyState(
          icon: Icons.folder_outlined,
          title: 'Henüz klasör yok',
          description: 'Yeni klasör oluşturarak başlayın');
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: available.length + 1,
      itemBuilder: (ctx, i) => i == 0
          ? _buildRootOption(context)
          : _buildFolderOption(context, available[i - 1]),
    );
  }

  Widget _buildRootOption(BuildContext context) {
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final accentColor = context.palette.accent;

    final sel = _selectedFolderId == null;
    return ListTile(
      leading:
          Icon(Icons.home_outlined, color: sel ? accentColor : textSecondary),
      title: Text(_isMovingFolder ? 'Ana Klasörler' : 'Belgeler (Klasörsüz)',
          style: AppTypography.bodyLarge.copyWith(
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              color: sel ? accentColor : textPrimary)),
      trailing: sel ? Icon(Icons.check, color: accentColor) : null,
      onTap: () => setState(() => _selectedFolderId = null),
    );
  }

  Widget _buildFolderOption(BuildContext context, Folder folder) {
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final accentColor = context.palette.accent;

    final sel = _selectedFolderId == folder.id;
    return ListTile(
      leading: Icon(Icons.folder,
          color: sel ? accentColor : Color(folder.colorValue)),
      title: Text(folder.name,
          style: AppTypography.bodyLarge
              .copyWith(color: sel ? accentColor : textPrimary)),
      subtitle: Text('${folder.documentCount} belge',
          style: AppTypography.caption.copyWith(color: textSecondary)),
      trailing: sel ? Icon(Icons.check, color: accentColor) : null,
      onTap: () => setState(() => _selectedFolderId = folder.id),
    );
  }

  Widget _buildError(Object error) {
    final textSecondary = context.palette.textMuted;
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: AppIconSize.emptyState, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text('Klasörler yüklenemedi: $error',
                style: AppTypography.bodyMedium.copyWith(color: textSecondary)),
          ])),
    );
  }

  Widget _buildActions() => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          if (!_isCreatingFolder)
            AppButton(
                label: 'Yeni Klasör',
                leadingIcon: Icons.create_new_folder,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                onPressed: () => setState(() => _isCreatingFolder = true)),
          const Spacer(),
          if (_isFolderMode)
            AppButton(
                label: 'Bitti', onPressed: () => Navigator.pop(context, true))
          else ...[
            AppButton(
                label: 'İptal',
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
                label: 'Taşı',
                onPressed: _isMovingFolder || _selectedFolderId != null
                    ? _handleMove
                    : null),
          ],
        ]),
      );

  Future<void> _handleCreateFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Klasör adı boş olamaz');
      return;
    }
    final controller = ref.read(foldersControllerProvider.notifier);
    final id = await controller.createFolder(
      name: name,
      parentId: widget.parentFolderId,
      colorValue: _selectedColorValue,
    );
    if (id != null && mounted) {
      ref.invalidate(foldersProvider);
      setState(() {
        _selectedFolderId = id;
        _isCreatingFolder = false;
        _newFolderController.clear();
        _selectedColorValue = AppColors.folderColors.first.toARGB32();
      });
      AppToast.success(context, 'Klasör "$name" oluşturuldu');
    }
    // Failures are shown by LibraryErrorListener.
  }

  Future<void> _handleMove() async {
    bool success = true;
    if (widget.documentIds.isNotEmpty) {
      success = await ref
          .read(documentsControllerProvider.notifier)
          .moveDocumentsToFolder(widget.documentIds, _selectedFolderId);
    }
    if (widget.folderIds.isNotEmpty && success) {
      final ctrl = ref.read(foldersControllerProvider.notifier);
      for (final fid in widget.folderIds) {
        success = await ctrl.moveFolder(
            folderId: fid, newParentId: _selectedFolderId);
        if (!success) break;
      }
    }
    // Failures are shown by LibraryErrorListener.
    if (success && mounted) Navigator.pop(context, true);
  }
}

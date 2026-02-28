/// ElyaNotes Move to Folder Dialog - Design system dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Dialog for moving documents and folders
class MoveToFolderDialog extends ConsumerStatefulWidget {
  final List<String> documentIds;
  final List<String> folderIds;
  const MoveToFolderDialog(
      {super.key, this.documentIds = const [], this.folderIds = const []});
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

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
            onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Widget _buildNewFolderSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

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
            _buildInlineColorPicker(),
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

  Widget _buildInlineColorPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppColors.folderColors.map((color) {
          final isSelected = color.toARGB32() == _selectedColorValue;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedColorValue = color.toARGB32()),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: AppIconSize.xs)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

    final sel = _selectedFolderId == null;
    return ListTile(
      leading: Icon(Icons.home_outlined,
          color: sel ? accentColor : textSecondary),
      title: Text(_isMovingFolder ? 'Ana Klasörler' : 'Belgeler (Klasörsüz)',
          style: AppTypography.bodyLarge.copyWith(
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              color: sel ? accentColor : textPrimary)),
      trailing: sel ? Icon(Icons.check, color: accentColor) : null,
      onTap: () => setState(() => _selectedFolderId = null),
    );
  }

  Widget _buildFolderOption(BuildContext context, Folder folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
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
    final id = await ref
        .read(foldersControllerProvider.notifier)
        .createFolder(name: name, colorValue: _selectedColorValue);
    if (id != null && mounted) {
      ref.invalidate(foldersProvider);
      setState(() {
        _selectedFolderId = id;
        _isCreatingFolder = false;
        _newFolderController.clear();
        _selectedColorValue = AppColors.folderColors.first.toARGB32();
      });
      AppToast.success(context, 'Klasör "$name" oluşturuldu');
    } else if (mounted) {
      AppToast.error(context, 'Klasör oluşturulamadı');
    }
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
    if (mounted) {
      success
          ? Navigator.pop(context, true)
          : AppToast.error(context, 'Taşıma başarısız');
    }
  }
}

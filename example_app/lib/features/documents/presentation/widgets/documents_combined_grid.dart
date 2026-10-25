import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';
import 'package:example_app/features/documents/presentation/widgets/library_grid_metrics.dart';

/// Grid view displaying folders followed by documents.
class DocumentsCombinedGridView extends ConsumerWidget {
  const DocumentsCombinedGridView({
    super.key,
    required this.folders,
    required this.documents,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final List<Folder> folders;
  final List<DocumentInfo> documents;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = Responsive.isPhone(context);
        final pad = LibraryGridMetrics.paneHorizontalPadding(isPhone);
        final metrics = LibraryGridMetrics.resolve(
          availableWidth: constraints.maxWidth - 2 * pad,
          isPhone: isPhone,
          textScaler: MediaQuery.textScalerOf(context),
        );

        final isSelectionMode = ref.watch(selectionModeProvider);
        final selectedDocuments = ref.watch(selectedDocumentsProvider);
        final selectedFolders = ref.watch(selectedFoldersProvider);

        // The top padding keeps the selected-tile backdrop (inflated by sm)
        // from being clipped by the viewport.
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            pad,
            AppSpacing.sm,
            pad,
            AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
          ),
          gridDelegate: metrics.delegate,
          itemCount: folders.length + documents.length,
          itemBuilder: (context, index) {
            if (index < folders.length) {
              final folder = folders[index];
              final isSelected = selectedFolders.contains(folder.id);
              return FolderCard(
                folder: folder,
                isSelectionMode: isSelectionMode,
                isSelected: isSelected,
                onTap: () => onFolderTap(folder),
                onMorePressed: () => onFolderMore(folder),
              );
            }

            final docIndex = index - folders.length;
            final doc = documents[docIndex];
            final isSelected = selectedDocuments.contains(doc.id);
            return DocumentCard(
              document: doc,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onTap: () => onDocumentTap(doc),
              onFavoriteToggle: () => ref
                  .read(documentsControllerProvider.notifier)
                  .toggleFavorite(doc.id),
              onMorePressed: () => onDocumentMore(doc),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';

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
        final width = constraints.maxWidth;
        // Card width constants for grid layout
        final cardWidth = width < 600 ? 160.0 : 180.0;
        final spacing = width < 600 ? AppSpacing.lg.toDouble() : AppSpacing.xl.toDouble();
        final padding = width < 600 ? AppSpacing.lg.toDouble() : AppSpacing.xxl.toDouble();
        final isPhone = width < 600;

        final isSelectionMode = ref.watch(selectionModeProvider);
        final selectedDocuments = ref.watch(selectedDocumentsProvider);
        final selectedFolders = ref.watch(selectedFoldersProvider);

        final gridDelegate = isPhone
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.75,
              )
            : SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: cardWidth,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.75,
              );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: GridView.builder(
            gridDelegate: gridDelegate,
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
          ),
        );
      },
    );
  }
}

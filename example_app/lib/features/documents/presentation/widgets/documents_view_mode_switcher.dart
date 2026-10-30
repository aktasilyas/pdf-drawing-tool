import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/document_sort.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_combined_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_list_view.dart';

/// Grid or list for the current [ViewMode], cross-faded on change.
class DocumentsViewModeSwitcher extends ConsumerWidget {
  const DocumentsViewModeSwitcher({
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
    final viewMode = ref.watch(viewModeProvider);
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppCurves.fade,
      switchOutCurve: AppCurves.fade,
      child: KeyedSubtree(
        key: ValueKey(viewMode),
        child: viewMode == ViewMode.grid
            ? DocumentsCombinedGridView(
                folders: folders,
                documents: documents,
                onFolderTap: onFolderTap,
                onDocumentTap: onDocumentTap,
                onFolderMore: onFolderMore,
                onDocumentMore: onDocumentMore,
              )
            : DocumentsCombinedListView(
                folders: folders,
                documents: documents,
                onFolderTap: onFolderTap,
                onDocumentTap: onDocumentTap,
                onFolderMore: onFolderMore,
                onDocumentMore: onDocumentMore,
              ),
      ),
    );
  }
}

/// Sorts documents by the sort menu state; "Favorileri üste sabitle" puts
/// favourites first. Watches the sort providers, so call it from `build`.
List<DocumentInfo> sortDocumentsByPreferences(
  WidgetRef ref,
  List<DocumentInfo> documents,
) =>
    sortDocuments(
      documents,
      option: ref.watch(sortOptionProvider),
      direction: ref.watch(sortDirectionProvider),
      pinFavorites: ref.watch(pinFavoritesProvider),
    );

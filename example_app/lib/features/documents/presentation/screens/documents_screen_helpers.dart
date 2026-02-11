import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/breadcrumb_navigation.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

import 'documents_screen.dart';

/// Mixin providing helper methods and widget builders for DocumentsScreen state.
mixin DocumentsScreenHelpers on ConsumerState<DocumentsScreen> {
  /// Opens a document by loading it and navigating to the editor.
  Future<void> openDocument(String documentId) async {
    final loadUseCase = ref.read(loadDocumentUseCaseProvider);
    final result = await loadUseCase(documentId);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Belge açılamadı: ${failure.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      (document) {
        final pdfPages = document.pages
            .where((p) =>
                p.background.type == core.BackgroundType.pdf &&
                p.background.pdfFilePath != null &&
                p.background.pdfPageIndex != null)
            .toList();

        if (pdfPages.isNotEmpty) {
          final pdfFilePath = pdfPages.first.background.pdfFilePath!;
          ref.read(currentPdfFilePathProvider.notifier).state = pdfFilePath;
          ref.read(totalPdfPagesProvider.notifier).state = pdfPages.length;
          ref.read(visiblePdfPageProvider.notifier).state = 0;
        }
        if (mounted) context.push('/editor/$documentId');
      },
    );
  }

  /// Shows dialog to create a new folder.
  void showCreateFolderDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const MoveToFolderDialog(documentIds: []),
    ).then((result) {
      if (result == true) ref.invalidate(foldersProvider);
    });
  }

  /// Builds the breadcrumb navigation widget for folder paths.
  Widget buildBreadcrumb(
    String? selectedFolderId,
    VoidCallback navigateToRoot,
    void Function(String) navigateToFolder,
  ) {
    if (selectedFolderId == null) return const SizedBox.shrink();

    final folderPathAsync = ref.watch(folderPathProvider(selectedFolderId));

    return folderPathAsync.when(
      data: (folders) {
        if (folders.isEmpty) return const SizedBox.shrink();
        final items = <BreadcrumbItem>[
          const BreadcrumbItem(folderId: null, label: 'Belgelerim'),
          ...folders.map(
            (f) => BreadcrumbItem(folderId: f.id, label: f.name),
          ),
        ];
        return BreadcrumbNavigation(
          items: items,
          onItemTap: (item) {
            if (item.folderId == null) {
              navigateToRoot();
            } else {
              navigateToFolder(item.folderId!);
            }
          },
          onBackPressed: () {
            if (folders.length > 1) {
              navigateToFolder(folders[folders.length - 2].id);
            } else {
              navigateToRoot();
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Handles folder tap for selection mode or navigation.
  void handleFolderTap(
    Folder folder,
    void Function(String) navigateToFolder,
  ) {
    final isSelectionMode = ref.read(selectionModeProvider);
    if (isSelectionMode) {
      final current = ref.read(selectedFoldersProvider);
      final updated = Set<String>.from(current);
      if (updated.contains(folder.id)) {
        updated.remove(folder.id);
      } else {
        updated.add(folder.id);
      }
      ref.read(selectedFoldersProvider.notifier).state = updated;
    } else {
      navigateToFolder(folder.id);
    }
  }

  /// Handles document tap for selection mode or opening.
  void handleDocumentTap(DocumentInfo doc) {
    final isSelectionMode = ref.read(selectionModeProvider);
    if (isSelectionMode) {
      final current = ref.read(selectedDocumentsProvider);
      final updated = Set<String>.from(current);
      if (updated.contains(doc.id)) {
        updated.remove(doc.id);
      } else {
        updated.add(doc.id);
      }
      ref.read(selectedDocumentsProvider.notifier).state = updated;
    } else {
      openDocument(doc.id);
    }
  }
}

/// Returns the display title for the given section and optional folder.
String getSectionTitle(
  WidgetRef ref,
  SidebarSection section,
  String? folderId,
) {
  switch (section) {
    case SidebarSection.documents:
      return 'Belgeler';
    case SidebarSection.favorites:
      return 'Sık Kullanılanlar';
    case SidebarSection.shared:
      return 'Paylaşılan';
    case SidebarSection.store:
      return 'Mağaza';
    case SidebarSection.trash:
      return 'Çöp';
    case SidebarSection.folder:
      if (folderId != null) {
        final folderAsync = ref.watch(folderByIdProvider(folderId));
        return folderAsync.when(
          data: (folder) => folder?.name ?? 'Klasör',
          loading: () => 'Klasör',
          error: (_, __) => 'Klasör',
        );
      }
      return 'Klasör';
  }
}

/// Returns the list of document IDs for the current section/folder view.
List<String> getCurrentDocumentIds(
  WidgetRef ref,
  SidebarSection section,
  String? folderId,
) {
  final documentsAsync = switch (section) {
    SidebarSection.documents => ref.watch(documentsProvider(null)),
    SidebarSection.favorites => ref.watch(favoriteDocumentsProvider),
    SidebarSection.trash => ref.watch(trashDocumentsProvider),
    SidebarSection.folder => ref.watch(documentsProvider(folderId)),
    _ => const AsyncValue<List<DocumentInfo>>.data([]),
  };
  final searchQuery = ref.watch(searchQueryProvider);
  return documentsAsync.when(
    data: (docs) {
      var filtered = docs;
      if (searchQuery.isNotEmpty) {
        filtered = docs
            .where((d) =>
                d.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      return filtered.map((d) => d.id).toList();
    },
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
}

/// Returns the list of folder IDs for the current section/folder view.
List<String> getCurrentFolderIds(
  WidgetRef ref,
  SidebarSection section,
  String? folderId,
) {
  final foldersAsync = ref.watch(foldersProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  return foldersAsync.when(
    data: (folders) {
      List<Folder> visible;
      if (section == SidebarSection.documents) {
        visible = folders.where((f) => f.parentId == null).toList();
      } else if (section == SidebarSection.folder) {
        visible = folders.where((f) => f.parentId == folderId).toList();
      } else {
        return <String>[];
      }
      if (searchQuery.isNotEmpty) {
        visible = visible
            .where((f) =>
                f.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      return visible.map((f) => f.id).toList();
    },
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
}

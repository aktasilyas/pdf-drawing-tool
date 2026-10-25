import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/repositories/page_trash_repository.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';

// Trash documents
final trashDocumentsProvider = FutureProvider<List<DocumentInfo>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getTrash();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (documents) => documents,
  );
});

// Page trash repository
final pageTrashRepositoryProvider = Provider<PageTrashRepository>((ref) {
  return GetIt.instance<PageTrashRepository>();
});

// Trashed pages
final trashedPagesProvider = FutureProvider<List<TrashedPage>>((ref) async {
  final repo = ref.watch(pageTrashRepositoryProvider);
  return repo.getTrashedPages();
});

/// Union type for trash items (documents + pages), sorted by deletedAt desc.
sealed class TrashItem {
  DateTime get deletedAt;
}

class TrashDocumentItem extends TrashItem {
  final DocumentInfo document;
  TrashDocumentItem(this.document);

  @override
  DateTime get deletedAt => document.deletedAt ?? document.updatedAt;
}

class TrashPageItem extends TrashItem {
  final TrashedPage page;
  TrashPageItem(this.page);

  @override
  DateTime get deletedAt => page.deletedAt;
}

// Combined trash items (documents + pages) sorted by deletion date
final trashItemsProvider = FutureProvider<List<TrashItem>>((ref) async {
  final docsAsync = ref.watch(trashDocumentsProvider);
  final pagesAsync = ref.watch(trashedPagesProvider);

  final docs = docsAsync.valueOrNull ?? [];
  final pages = pagesAsync.valueOrNull ?? [];

  final items = <TrashItem>[
    ...docs.map((d) => TrashDocumentItem(d)),
    ...pages.map((p) => TrashPageItem(p)),
  ];
  items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  return items;
});

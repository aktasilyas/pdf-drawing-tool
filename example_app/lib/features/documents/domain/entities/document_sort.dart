/// Library ordering of documents.
library;

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';

/// Returns a sorted copy of [documents] by [option] in [direction].
///
/// With [pinFavorites] (Settings and the sort menu: "Favorileri üste
/// sabitle") favourites come first; both groups keep the chosen order.
List<DocumentInfo> sortDocuments(
  List<DocumentInfo> documents, {
  required SortOption option,
  required SortDirection direction,
  bool pinFavorites = false,
}) {
  int byOption(DocumentInfo a, DocumentInfo b) {
    final result = switch (option) {
      SortOption.date => a.updatedAt.compareTo(b.updatedAt),
      SortOption.name => a.title.compareTo(b.title),
      SortOption.size => a.pageCount.compareTo(b.pageCount),
    };
    return direction == SortDirection.descending ? -result : result;
  }

  return List<DocumentInfo>.of(documents)
    ..sort((a, b) {
      if (pinFavorites && a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return byOption(a, b);
    });
}

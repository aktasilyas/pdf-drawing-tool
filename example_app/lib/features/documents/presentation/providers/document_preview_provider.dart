import 'package:drawing_core/drawing_core.dart' show PageBackground;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';

/// Identifies one stored version of a document for its library thumbnail.
typedef DocumentPreviewKey = ({String id, DateTime updatedAt});

/// First page background of a library tile. Keyed by id and `updatedAt`, so
/// rebuilding a tile reuses the result and an edited document reloads.
/// Failures resolve to null (the tile shows plain paper). Auto-disposed:
/// image backgrounds hold their bytes, so off-screen tiles release them.
final documentPreviewBackgroundProvider = FutureProvider.autoDispose
    .family<PageBackground?, DocumentPreviewKey>((ref, key) async {
  final result =
      await ref.watch(documentRepositoryProvider).getFirstPageBackground(
            key.id,
          );
  return result.fold((_) => null, (background) => background);
});

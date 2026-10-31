import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/usecases/change_cover_usecase.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// Builds [ChangeCoverUseCase] on the shared document repository. Plain
/// provider (not injectable), like the premium use cases.
final changeCoverUseCaseProvider = Provider<ChangeCoverUseCase>(
  (ref) => ChangeCoverUseCase(ref.watch(documentRepositoryProvider)),
);

/// "Change cover" operation of the documents controller.
mixin DocumentsCoverOperation on StateNotifier<AsyncValue<void>> {
  @protected
  Ref get ref;

  /// Returns true when the cover of [documentId] was changed.
  Future<bool> changeCover(String documentId, String coverId) async {
    final result = await ref.read(changeCoverUseCaseProvider)(
      documentId,
      coverId,
    );
    return result.fold(
      (failure) {
        reportLibraryFailure(ref, failure, LibraryAction.changeCover);
        return false;
      },
      (_) {
        // Tiles draw the cover from DocumentInfo.coverId.
        invalidateDocumentLists(
          ref,
          documents: true,
          favorites: true,
          recent: true,
        );
        return true;
      },
    );
  }
}

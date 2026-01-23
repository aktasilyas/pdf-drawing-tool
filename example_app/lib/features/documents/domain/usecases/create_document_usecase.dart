import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';

@injectable
class CreateDocumentUseCase {
  final DocumentRepository _documentRepository;
  final SubscriptionRepository _subscriptionRepository;

  CreateDocumentUseCase(
    this._documentRepository,
    this._subscriptionRepository,
  );

  Future<Either<Failure, DocumentInfo>> call({
    required String title,
    required String templateId,
    String? folderId,
  }) async {
    // Check document limit for free users
    final subscriptionResult = await _subscriptionRepository.getSubscription();
    
    return subscriptionResult.fold(
      (failure) => Left(failure),
      (subscription) async {
        // If free user, check document count limit
        if (subscription.isFree) {
          final documentsResult = await _documentRepository.getDocuments();
          return documentsResult.fold(
            (failure) => Left(failure),
            (documents) async {
              final nonTrashDocs = documents.where((d) => !d.isInTrash).length;
              if (nonTrashDocs >= FreeTierLimits.maxDocuments) {
                return const Left(
                  ValidationFailure(
                    'Ücretsiz sınıra ulaştınız. Premium\'a geçin.',
                  ),
                );
              }
              return _documentRepository.createDocument(
                title: title,
                templateId: templateId,
                folderId: folderId,
              );
            },
          );
        }

        // Premium user - no limits
        return _documentRepository.createDocument(
          title: title,
          templateId: templateId,
          folderId: folderId,
        );
      },
    );
  }
}

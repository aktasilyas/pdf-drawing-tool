import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';

@injectable
class CreateFolderUseCase {
  final FolderRepository _folderRepository;
  final SubscriptionRepository _subscriptionRepository;

  CreateFolderUseCase(
    this._folderRepository,
    this._subscriptionRepository,
  );

  Future<Either<Failure, Folder>> call({
    required String name,
    String? parentId,
    int? colorValue,
  }) async {
    // Check folder limit for free users
    final subscriptionResult = await _subscriptionRepository.getSubscription();
    
    return subscriptionResult.fold(
      (failure) => Left(failure),
      (subscription) async {
        // If free user, check folder count limit
        if (subscription.isFree) {
          final foldersResult = await _folderRepository.getFolders();
          return foldersResult.fold(
            (failure) => Left(failure),
            (folders) {
              if (folders.length >= FreeTierLimits.maxFolders) {
                return Future.value(
                  const Left(
                    ValidationFailure(
                      'Klasör sınırına ulaştınız. Premium\'a geçin.',
                    ),
                  ),
                );
              }
              return _folderRepository.createFolder(
                name: name,
                parentId: parentId,
                colorValue: colorValue,
              );
            },
          );
        }

        // Premium user - no limits
        return _folderRepository.createFolder(
          name: name,
          parentId: parentId,
          colorValue: colorValue,
        );
      },
    );
  }
}

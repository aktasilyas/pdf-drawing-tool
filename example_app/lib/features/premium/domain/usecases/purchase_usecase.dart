// Use case for purchasing a premium product.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';

class PurchaseUseCase {
  final SubscriptionRepository repository;

  const PurchaseUseCase(this.repository);

  Future<Either<Failure, Subscription>> call(String productId) {
    return repository.purchase(productId);
  }
}

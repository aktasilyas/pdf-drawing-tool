// Use case for restoring purchases.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';

class RestorePurchasesUseCase {
  final SubscriptionRepository repository;

  const RestorePurchasesUseCase(this.repository);

  Future<Either<Failure, Subscription>> call() {
    return repository.restorePurchases();
  }
}

// Use case for fetching the current subscription.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';

class CheckSubscriptionUseCase {
  final SubscriptionRepository repository;

  const CheckSubscriptionUseCase(this.repository);

  Future<Either<Failure, Subscription>> call() {
    return repository.getSubscription();
  }
}

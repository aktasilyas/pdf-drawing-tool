// Use case for checking a specific entitlement.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';

class HasEntitlementUseCase {
  final SubscriptionRepository repository;

  const HasEntitlementUseCase(this.repository);

  Future<Either<Failure, bool>> call(String entitlementId) {
    return repository.hasEntitlement(entitlementId);
  }
}

// Contract for premium subscription data operations.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/entities/entitlement.dart';
import 'package:example_app/features/premium/domain/entities/product.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Subscription>> getSubscription();
  Future<Either<Failure, bool>> hasEntitlement(String entitlementId);
  Future<Either<Failure, List<Entitlement>>> getEntitlements();
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Subscription>> purchase(String productId);
  Future<Either<Failure, Subscription>> restorePurchases();
  Stream<Subscription> watchSubscription();
  Future<Either<Failure, String?>> getManagementUrl();
}

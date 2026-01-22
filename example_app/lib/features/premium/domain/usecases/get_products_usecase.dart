// Use case for retrieving available premium products.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';

import 'package:example_app/features/premium/domain/entities/product.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';

class GetProductsUseCase {
  final SubscriptionRepository repository;

  const GetProductsUseCase(this.repository);

  Future<Either<Failure, List<Product>>> call() {
    return repository.getProducts();
  }
}

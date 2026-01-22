import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/premium/domain/entities/product.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/entities/entitlement.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';
import 'package:example_app/features/premium/domain/usecases/check_subscription_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/get_products_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/has_entitlement_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/purchase_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/restore_purchases_usecase.dart';

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({
    this.subscriptionResult = const Right<Failure, Subscription>(Subscription.freeUser),
    this.entitlementResult = const Right<Failure, bool>(false),
    this.productsResult = const Right<Failure, List<Product>>([]),
    this.purchaseResult = const Right<Failure, Subscription>(Subscription.freeUser),
    this.restoreResult = const Right<Failure, Subscription>(Subscription.freeUser),
  });

  final Either<Failure, Subscription> subscriptionResult;
  final Either<Failure, bool> entitlementResult;
  final Either<Failure, List<Product>> productsResult;
  final Either<Failure, Subscription> purchaseResult;
  final Either<Failure, Subscription> restoreResult;

  bool getSubscriptionCalled = false;
  String? hasEntitlementCalledWith;
  bool hasPurchaseCalled = false;
  bool restoreCalled = false;
  bool getProductsCalled = false;

  @override
  Future<Either<Failure, Subscription>> getSubscription() async {
    getSubscriptionCalled = true;
    return subscriptionResult;
  }

  @override
  Future<Either<Failure, bool>> hasEntitlement(String entitlementId) async {
    hasEntitlementCalledWith = entitlementId;
    return entitlementResult;
  }

  @override
  Future<Either<Failure, List<Entitlement>>> getEntitlements() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    getProductsCalled = true;
    return productsResult;
  }

  @override
  Future<Either<Failure, Subscription>> purchase(String productId) async {
    hasPurchaseCalled = true;
    return purchaseResult;
  }

  @override
  Future<Either<Failure, Subscription>> restorePurchases() async {
    restoreCalled = true;
    return restoreResult;
  }

  @override
  Future<Either<Failure, String?>> getManagementUrl() {
    throw UnimplementedError();
  }

  @override
  Stream<Subscription> watchSubscription() {
    return Stream.value(subscriptionResult.fold((_) => Subscription.freeUser, (value) => value));
  }
}

void main() {
  late _FakeSubscriptionRepository repository;

  setUp(() {
    repository = _FakeSubscriptionRepository(
      subscriptionResult: Right(
        const Subscription(
          tier: SubscriptionTier.premium,
          isActive: true,
        ),
      ),
      entitlementResult: const Right(true),
      productsResult: const Right([
        Product(
          id: 'monthly',
          title: 'Monthly',
          description: 'Monthly premium',
          price: '€9.99',
          currencyCode: 'EUR',
          type: ProductType.subscription,
          subscriptionPeriod: 'monthly',
        )
      ]),
      purchaseResult: Right(
        const Subscription(
          tier: SubscriptionTier.premiumPlus,
          isActive: true,
        ),
      ),
      restoreResult: Right(
        const Subscription(
          tier: SubscriptionTier.premium,
          isActive: true,
        ),
      ),
    );
  });

  test('CheckSubscriptionUseCase returns repository subscription', () async {
    final useCase = CheckSubscriptionUseCase(repository);
    final result = await useCase();
    expect(result.isRight(), true);
    expect(repository.getSubscriptionCalled, true);
  });

  test('HasEntitlementUseCase forwards entitlement id and result', () async {
    final useCase = HasEntitlementUseCase(repository);
    final result = await useCase('cloud_sync');
    expect(result.isRight(), true);
    expect(repository.hasEntitlementCalledWith, 'cloud_sync');
  });

  test('GetProductsUseCase returns product list', () async {
    final useCase = GetProductsUseCase(repository);
    final result = await useCase();
    expect(result.isRight(), true);
    expect(repository.getProductsCalled, true);
  });

  test('PurchaseUseCase returns purchase result and calls repository', () async {
    final useCase = PurchaseUseCase(repository);
    final result = await useCase('monthly');
    expect(repository.hasPurchaseCalled, true);
    expect(result.isRight(), true);
  });

  test('RestorePurchasesUseCase calls repository', () async {
    final useCase = RestorePurchasesUseCase(repository);
    final result = await useCase();
    expect(repository.restoreCalled, true);
    expect(result.isRight(), true);
  });
}

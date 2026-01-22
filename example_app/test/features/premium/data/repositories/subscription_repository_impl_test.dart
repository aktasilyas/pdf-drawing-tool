import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/premium/data/datasources/revenue_cat_datasource.dart';
import 'package:example_app/features/premium/data/repositories/subscription_repository_impl.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  late SubscriptionRepositoryImpl repository;
  late FakeRevenueCatDatasource datasource;

  const entitlementInfo = EntitlementInfo(
    'premium',
    true,
    true,
    '2024-01-01T00:00:00Z',
    '2023-01-01T00:00:00Z',
    'starnote_premium_monthly',
    false,
    expirationDate: '2025-01-01T00:00:00Z',
  );

  const entitlements = EntitlementInfos(
    {'premium': entitlementInfo},
    {'premium': entitlementInfo},
  );

  const customerInfo = CustomerInfo(
    entitlements,
    {},
    [],
    [],
    [],
    '2023-01-01T00:00:00Z',
    'user-id',
    {},
    '2024-01-01T00:00:00Z',
  );

  const storeProduct = StoreProduct(
    'starnote_premium_monthly',
    'Monthly premium access',
    'Premium Monthly',
    9.99,
    '₺9.99',
    'TRY',
    subscriptionPeriod: 'P1M',
  );

  const package = Package(
    'monthly',
    PackageType.monthly,
    storeProduct,
    const PresentedOfferingContext('default', null, null),
  );

  const offering = Offering(
    'default',
    'Default offering',
    {},
    [package],
    monthly: package,
  );

  const offerings = Offerings({'default': offering}, current: offering);

  setUp(() {
    datasource = FakeRevenueCatDatasource(
      customerInfo: customerInfo,
      offerings: offerings,
    );
    repository = SubscriptionRepositoryImpl(datasource);
  });

  test('getSubscription maps customer info to subscription', () async {
    final result = await repository.getSubscription();
    expect(result.isRight(), true);
    final subscription = result.getOrElse(() => Subscription.freeUser);
    expect(subscription.isPremium, true);
    expect(subscription.expiresAt, isNotNull);
  });

  test('getProducts returns mapped products', () async {
    final result = await repository.getProducts();
    expect(result.isRight(), true);
    final products = result.getOrElse(() => []);
    expect(products, isNotEmpty);
    expect(products.first.subscriptionPeriod, 'monthly');
  });

  test('hasEntitlement returns entitlement status', () async {
    final result = await repository.hasEntitlement('premium');
    expect(result.isRight(), true);
    expect(result.getOrElse(() => false), true);
  });
}

class FakeRevenueCatDatasource extends RevenueCatDatasource {
  FakeRevenueCatDatasource({
    required this.customerInfo,
    required this.offerings,
  });

  final CustomerInfo customerInfo;
  final Offerings offerings;

  @override
  Future<CustomerInfo> getCustomerInfo() async => customerInfo;

  @override
  Future<Offerings> getOfferings() async => offerings;

  @override
  Future<CustomerInfo> purchase(Package package) async => customerInfo;

  @override
  Future<CustomerInfo> restorePurchases() async => customerInfo;

  @override
  Stream<CustomerInfo> watchCustomerInfo() => Stream.value(customerInfo);
}

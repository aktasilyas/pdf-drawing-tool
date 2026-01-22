// RevenueCat-backed implementation of subscription repository.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/premium/domain/entities/entitlement.dart';
import 'package:example_app/features/premium/domain/entities/product.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:example_app/features/premium/data/datasources/revenue_cat_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final RevenueCatDatasource _datasource;

  SubscriptionRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, Subscription>> getSubscription() async {
    try {
      final info = await _datasource.getCustomerInfo();
      return Right(_mapCustomerInfo(info));
    } catch (_) {
      return Left(const PremiumFailure('Abonelik bilgisi alınamadı'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasEntitlement(String entitlementId) async {
    try {
      final info = await _datasource.getCustomerInfo();
      final entitlement = info.entitlements.all[entitlementId];
      return Right(entitlement?.isActive ?? false);
    } catch (_) {
      return Left(const PremiumFailure('Entitlement kontrolü başarısız'));
    }
  }

  @override
  Future<Either<Failure, List<Entitlement>>> getEntitlements() async {
    try {
      final info = await _datasource.getCustomerInfo();
      final entitlements = info.entitlements.all.values
          .map(
            (e) => Entitlement(
              id: e.identifier,
              isActive: e.isActive,
              expiresAt: _parseDateTime(e.expirationDate),
            ),
          )
          .toList();
      return Right(entitlements);
    } catch (_) {
      return Left(const PremiumFailure('Entitlement listesi alınamadı'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final offerings = await _datasource.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      final products = packages.map(_mapPackage).toList();
      return Right(products);
    } catch (_) {
      return Left(const PremiumFailure('Ürün listesi alınamadı'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> purchase(String productId) async {
    try {
      final package = await _findPackage(productId);
      if (package == null) {
        return Left(const PremiumFailure('Ürün bulunamadı'));
      }
      final info = await _datasource.purchase(package);
      return Right(_mapCustomerInfo(info));
    } catch (_) {
      return Left(PremiumFailure.purchaseFailed());
    }
  }

  @override
  Future<Either<Failure, Subscription>> restorePurchases() async {
    try {
      final info = await _datasource.restorePurchases();
      return Right(_mapCustomerInfo(info));
    } catch (_) {
      return Left(const PremiumFailure('Satın alımlar geri yüklenemedi'));
    }
  }

  @override
  Stream<Subscription> watchSubscription() {
    return _datasource.watchCustomerInfo().map(_mapCustomerInfo);
  }

  @override
  Future<Either<Failure, String?>> getManagementUrl() async {
    return const Right(null);
  }

  Future<Package?> _findPackage(String productId) async {
    final offerings = await _datasource.getOfferings();
    final packages = offerings.current?.availablePackages ?? [];
    for (final package in packages) {
      if (package.storeProduct.identifier == productId) {
        return package;
      }
    }
    return null;
  }

  Subscription _mapCustomerInfo(CustomerInfo info) {
    final activeEntitlements =
        info.entitlements.all.values.where((e) => e.isActive).toList();
    final entitlement = activeEntitlements.isNotEmpty
        ? activeEntitlements.first
        : null;

    final isActive = activeEntitlements.isNotEmpty;
    final tier = isActive ? SubscriptionTier.premium : SubscriptionTier.free;

    return Subscription(
      tier: tier,
      isActive: isActive,
      expiresAt: _parseDateTime(entitlement?.expirationDate),
      productId: entitlement?.productIdentifier,
      willRenew: entitlement?.willRenew ?? false,
    );
  }

  Product _mapPackage(Package package) {
    final product = package.storeProduct;
    final subscriptionPeriod = _mapPeriod(product);

    return Product(
      id: product.identifier,
      title: product.title,
      description: product.description,
      price: product.priceString,
      currencyCode: product.currencyCode,
      type:
          subscriptionPeriod == null ? ProductType.lifetime : ProductType.subscription,
      subscriptionPeriod: subscriptionPeriod,
    );
  }

  String? _mapPeriod(StoreProduct product) {
    final period = product.subscriptionPeriod;
    if (period == null) return null;
    if (period.contains('P1M')) return 'monthly';
    if (period.contains('P1Y')) return 'yearly';
    return null;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

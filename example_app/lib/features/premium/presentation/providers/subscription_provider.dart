// Riverpod providers for premium subscriptions.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/premium/data/datasources/revenue_cat_datasource.dart';
import 'package:example_app/features/premium/data/repositories/subscription_repository_impl.dart';
import 'package:example_app/features/premium/domain/entities/product.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';
import 'package:example_app/features/premium/domain/usecases/check_subscription_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/get_products_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/has_entitlement_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/purchase_usecase.dart';
import 'package:example_app/features/premium/domain/usecases/restore_purchases_usecase.dart';

final revenueCatDatasourceProvider = Provider((ref) => RevenueCatDatasource());

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepositoryImpl(ref.watch(revenueCatDatasourceProvider)),
);

final checkSubscriptionUseCaseProvider = Provider(
  (ref) => CheckSubscriptionUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final getProductsUseCaseProvider = Provider(
  (ref) => GetProductsUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final purchaseUseCaseProvider = Provider(
  (ref) => PurchaseUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final restorePurchasesUseCaseProvider = Provider(
  (ref) => RestorePurchasesUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final subscriptionProvider = StreamProvider<Subscription>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchSubscription();
});

final premiumProductsProvider = FutureProvider<List<Product>>((ref) async {
  final either = await ref.watch(getProductsUseCaseProvider).call();
  return either.fold(
    (failure) => throw failure,
    (products) => products,
  );
});

final hasEntitlementUseCaseProvider = Provider(
  (ref) => HasEntitlementUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final hasEntitlementProvider = FutureProvider.family<bool, String>((ref, entitlementId) async {
  final either = await ref.watch(hasEntitlementUseCaseProvider).call(entitlementId);
  return either.fold((failure) => false, (hasIt) => hasIt);
});

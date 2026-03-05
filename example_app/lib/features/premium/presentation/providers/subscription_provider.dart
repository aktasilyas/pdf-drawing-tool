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

/// Purchase operation state.
class PurchaseState {
  final bool isLoading;
  final String? error;
  final bool purchaseSuccess;

  const PurchaseState({
    this.isLoading = false,
    this.error,
    this.purchaseSuccess = false,
  });

  PurchaseState copyWith({
    bool? isLoading,
    String? error,
    bool? purchaseSuccess,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    );
  }
}

/// Manages purchase and restore operations with loading/error state.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final SubscriptionRepository _repo;

  PurchaseNotifier(this._repo) : super(const PurchaseState());

  /// Purchase a product by its store product ID.
  Future<void> purchase(String productId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      purchaseSuccess: false,
    );

    final either = await _repo.purchase(productId);
    either.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapError(failure.message),
      ),
      (subscription) => state = state.copyWith(
        isLoading: false,
        purchaseSuccess: subscription.isPremium,
      ),
    );
  }

  /// Restore previous purchases.
  Future<void> restore() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      purchaseSuccess: false,
    );

    final either = await _repo.restorePurchases();
    either.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: 'Satın almalar geri yüklenemedi. Lütfen tekrar deneyin.',
      ),
      (subscription) => state = state.copyWith(
        isLoading: false,
        purchaseSuccess: subscription.isPremium,
      ),
    );
  }

  String _mapError(String message) {
    if (message.contains('StoreProblem')) {
      return 'Mağaza bağlantısında sorun var. Lütfen tekrar deneyin.';
    }
    if (message.contains('Network')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return 'Satın alma işlemi başarısız. Lütfen tekrar deneyin.';
  }
}

/// Provider for managing purchase operations.
final purchaseStateProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return PurchaseNotifier(repo);
});

// Barrel exports for the premium feature.
// Domain
export 'domain/entities/subscription.dart';
export 'domain/entities/entitlement.dart';
export 'domain/entities/limits.dart';
export 'domain/entities/product.dart';
export 'domain/repositories/subscription_repository.dart';
export 'domain/usecases/check_subscription_usecase.dart';
export 'domain/usecases/has_entitlement_usecase.dart';
export 'domain/usecases/purchase_usecase.dart';
export 'domain/usecases/restore_purchases_usecase.dart';
export 'domain/usecases/get_products_usecase.dart';

// Data
export 'data/datasources/revenue_cat_datasource.dart';
export 'data/repositories/subscription_repository_impl.dart';

// Presentation
export 'presentation/providers/subscription_provider.dart';
export 'presentation/screens/paywall_screen.dart';
export 'presentation/widgets/feature_gate.dart';
export 'presentation/widgets/premium_badge.dart';

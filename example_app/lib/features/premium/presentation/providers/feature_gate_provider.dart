import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/services/feature_gate_service.dart';
import 'package:example_app/features/premium/presentation/providers/subscription_provider.dart';

/// Derives the current [SubscriptionTier] from the subscription stream.
/// Defaults to [SubscriptionTier.free] while loading or on error.
final currentTierProvider = Provider<SubscriptionTier>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.whenData((s) => s.tier).valueOrNull ?? SubscriptionTier.free;
});

/// Provides a [FeatureGateService] that reacts to tier changes.
final featureGateServiceProvider = Provider<FeatureGateService>((ref) {
  final tier = ref.watch(currentTierProvider);
  return FeatureGateService(tier);
});

/// Checks access for a specific feature with current usage.
///
/// Usage:
/// ```dart
/// final access = ref.watch(featureAccessProvider(
///   FeatureAccessParams(feature: GatedFeature.createNotebook, currentUsage: 3),
/// ));
/// ```
final featureAccessProvider =
    Provider.family<FeatureAccess, FeatureAccessParams>((ref, params) {
  final gate = ref.watch(featureGateServiceProvider);
  return gate.checkAccess(params.feature, currentUsage: params.currentUsage);
});

/// Parameters for [featureAccessProvider].
class FeatureAccessParams {
  final GatedFeature feature;
  final int currentUsage;

  const FeatureAccessParams({
    required this.feature,
    this.currentUsage = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureAccessParams &&
          feature == other.feature &&
          currentUsage == other.currentUsage;

  @override
  int get hashCode => Object.hash(feature, currentUsage);
}

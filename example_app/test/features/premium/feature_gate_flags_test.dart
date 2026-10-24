import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';
import 'package:example_app/features/premium/domain/services/feature_gate_service.dart';
import 'package:example_app/features/premium/presentation/providers/feature_gate_provider.dart';
import 'package:example_app/features/premium/presentation/providers/subscription_provider.dart';

class _MockRepo extends Mock implements SubscriptionRepository {}

void main() {
  test('unrestricted service allows every feature at any usage', () {
    final gate = FeatureGateService.unrestricted();
    for (final f in GatedFeature.values) {
      expect(gate.checkAccess(f, currentUsage: 100000).isAllowed, isTrue,
          reason: '$f');
    }
  });

  test('premium off: no RevenueCat access and unrestricted gate', () {
    final repo = _MockRepo();
    final c = ProviderContainer(overrides: [
      featureFlagsProvider.overrideWithValue(FeatureFlags.allOff),
      subscriptionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    final gate = c.read(featureGateServiceProvider);
    expect(
        gate
            .checkAccess(GatedFeature.createNotebook, currentUsage: 99)
            .isAllowed,
        isTrue);
    expect(c.read(currentTierProvider), isNot(SubscriptionTier.free));
    verifyZeroInteractions(repo);
  });

  test('premium on: tier-based gating via the subscription stream', () {
    final repo = _MockRepo();
    when(() => repo.watchSubscription())
        .thenAnswer((_) => const Stream.empty());
    final c = ProviderContainer(overrides: [
      featureFlagsProvider.overrideWithValue(FeatureFlags.allOn),
      subscriptionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    expect(c.read(currentTierProvider), SubscriptionTier.free);
    final gate = c.read(featureGateServiceProvider);
    expect(
        gate
            .checkAccess(GatedFeature.createNotebook, currentUsage: 3)
            .isAllowed,
        isFalse);
  });
}

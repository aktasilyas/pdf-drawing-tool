import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/subscription_repository.dart';
import 'package:example_app/features/premium/presentation/providers/subscription_provider.dart';

class _MockRepo extends Mock implements SubscriptionRepository {}

void main() {
  test('premium off: aiTierProvider is premiumPlus, RevenueCat untouched', () {
    final repo = _MockRepo();
    final c = ProviderContainer(overrides: [
      featureFlagsProvider.overrideWithValue(FeatureFlags.allOff),
      subscriptionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    expect(c.read(aiTierProvider), SubscriptionTier.premiumPlus);
    verifyZeroInteractions(repo);
  });

  test('premium on: aiTierProvider is free until a subscription arrives', () {
    final repo = _MockRepo();
    when(() => repo.watchSubscription())
        .thenAnswer((_) => const Stream.empty());
    final c = ProviderContainer(overrides: [
      featureFlagsProvider.overrideWithValue(FeatureFlags.allOn),
      subscriptionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    expect(c.read(aiTierProvider), SubscriptionTier.free);
  });
}

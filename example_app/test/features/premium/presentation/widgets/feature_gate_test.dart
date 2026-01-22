import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/premium/premium.dart';

Override _overrideHasEntitlementWithValue(bool value) {
  return hasEntitlementProvider.overrideWithProvider(
    (arg) => FutureProvider((ref) => value),
  );
}

Override _overrideHasEntitlementLoading() {
  final completer = Completer<bool>();

  return hasEntitlementProvider.overrideWithProvider(
    (arg) => FutureProvider((ref) => completer.future),
  );
}

void main() {
  testWidgets('FeatureGate renders child when entitlement granted', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _overrideHasEntitlementWithValue(true),
        ],
        child: const MaterialApp(
          home: FeatureGate(
            entitlementId: 'premium',
            child: Text('unlocked'),
          ),
        ),
      ),
    );

    expect(find.text('unlocked'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('FeatureGate shows locked child when entitlement missing', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _overrideHasEntitlementWithValue(false),
        ],
        child: MaterialApp(
          home: FeatureGate(
            entitlementId: 'premium',
            onLocked: () => tapped = true,
            lockedChild: const Text('locked'),
            child: const Text('unlocked'),
          ),
        ),
      ),
    );

    expect(find.text('locked'), findsOneWidget);
    await tester.tap(find.text('locked'));
    expect(tapped, true);
  });

  testWidgets('FeatureGate shows child while entitlement loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _overrideHasEntitlementLoading(),
        ],
        child: const MaterialApp(
          home: FeatureGate(
            entitlementId: 'premium',
            child: Text('loading child'),
          ),
        ),
      ),
    );

    expect(find.text('loading child'), findsOneWidget);
  });
}

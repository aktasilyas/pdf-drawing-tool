// Widget that shows premium/locked UI based on entitlement.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/premium/premium.dart';

class FeatureGate extends ConsumerWidget {
  final String entitlementId;
  final Widget child;
  final Widget? lockedChild;
  final VoidCallback? onLocked;

  const FeatureGate({
    required this.entitlementId,
    required this.child,
    this.lockedChild,
    this.onLocked,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(hasEntitlementProvider(entitlementId));

    return hasAccess.when(
      data: (granted) => granted ? child : _lockedWidget(context),
      loading: () => child,
      error: (_, __) => child,
    );
  }

  Widget _lockedWidget(BuildContext context) {
    return GestureDetector(
      onTap: onLocked ?? () => Navigator.pushNamed(context, PaywallScreen.routeName),
      child: lockedChild ?? const Icon(Icons.lock),
    );
  }
}

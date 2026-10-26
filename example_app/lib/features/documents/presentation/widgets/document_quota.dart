import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/premium/premium.dart';

/// Returns true when another document may be created. Otherwise shows the
/// upgrade sheet and returns false.
Future<bool> ensureDocumentQuota(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final totalCount = await container.read(totalDocumentCountProvider.future);
  final access = container.read(featureAccessProvider(
    FeatureAccessParams(
      feature: GatedFeature.createDocument,
      currentUsage: totalCount,
    ),
  ));

  if (!context.mounted) return false;
  if (access.isAllowed) return true;

  await UpgradePromptSheet.show(
    context,
    access: access,
    featureIcon: Icons.note_add_outlined,
    featureTitle: 'Belge Limitine Ulaştınız',
    onUpgrade: () {
      Navigator.pop(context);
      GoRouter.of(context).push(RouteNames.paywall);
    },
  );
  return false;
}

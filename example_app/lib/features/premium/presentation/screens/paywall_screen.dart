/// Paywall screen showing products, restore button and feature table.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/premium/premium.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const routeName = '/paywall';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StarNote Premium'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: PremiumBadge(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upgrade to Premium',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock cloud sync, unlimited documents and AI-powered helpers.',
              ),
              const SizedBox(height: 16),
              _buildProductList(context, ref),
              const SizedBox(height: 24),
              _buildFeatureComparison(ref),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _restorePurchases(context, ref),
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, WidgetRef ref) {
    final products = ref.watch(premiumProductsProvider);

    return products.when(
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((product) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.description),
                    trailing: Text(product.price),
                    onTap: () => _purchaseProduct(context, ref, product),
                  ),
                ))
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        (error is Failure ? error.message : 'Ürünler yüklenemedi'),
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  void _purchaseProduct(BuildContext context, WidgetRef ref, Product product) async {
    final result = await ref.read(purchaseUseCaseProvider).call(product.id);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma başarılı')),
      ),
    );
  }

  void _restorePurchases(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(restorePurchasesUseCaseProvider).call();

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alımlar geri yüklendi')),
      ),
    );
  }

  Widget _buildFeatureComparison(WidgetRef ref) {
    final rows = [
      {'label': 'Cloud Sync', 'entitlement': Entitlements.cloudSync},
      {'label': 'Unlimited Documents', 'entitlement': Entitlements.unlimitedDocuments},
      {'label': 'Premium Templates', 'entitlement': Entitlements.premiumTemplates},
      {'label': 'AI Features', 'entitlement': Entitlements.aiFeatures},
      {'label': 'Advanced Export', 'entitlement': Entitlements.advancedExport},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What you unlock',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...rows.map((row) => _buildFeatureRow(ref, row['label']!, row['entitlement']!)),
      ],
    );
  }

  Widget _buildFeatureRow(WidgetRef ref, String label, String entitlementId) {
    final status = ref.watch(hasEntitlementProvider(entitlementId));

    return status.when(
      data: (hasAccess) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(hasAccess ? Icons.check_circle : Icons.lock, color: hasAccess ? Colors.green : Colors.grey),
        title: Text(label),
      ),
      loading: () => const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircularProgressIndicator(strokeWidth: 2),
        title: Text('Checking…'),
      ),
      error: (_, __) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.error, color: Colors.red),
        title: Text(label),
      ),
    );
  }
}

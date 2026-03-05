import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/premium/presentation/providers/subscription_provider.dart';
import 'package:example_app/features/premium/presentation/widgets/plan_card.dart';

/// Product IDs matching RevenueCat / Store configuration.
abstract class PaywallProductIds {
  static const premiumMonthly = 'elyanotes_premium_monthly';
  static const premiumYearly = 'elyanotes_premium_yearly';
  static const proMonthly = 'elyanotes_pro_monthly';
  static const proYearly = 'elyanotes_pro_yearly';
}

/// Paywall screen showing 3 plan tiers with monthly/yearly toggle.
class PaywallPlaceholderScreen extends ConsumerStatefulWidget {
  const PaywallPlaceholderScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallPlaceholderScreen(),
    );
  }

  @override
  ConsumerState<PaywallPlaceholderScreen> createState() => _PaywallState();
}

class _PaywallState extends ConsumerState<PaywallPlaceholderScreen> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseState = ref.watch(purchaseStateProvider);

    ref.listen(purchaseStateProvider, (prev, next) {
      if (next.purchaseSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium aktivasyonu basarili!')),
        );
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomSheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBillingToggle(theme),
                      const SizedBox(height: AppSpacing.md),
                      _buildPlanCards(theme),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTrialCta(theme),
                      const SizedBox(height: AppSpacing.md),
                      _buildRestoreButton(theme),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (purchaseState.isLoading) _buildLoadingOverlay(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.star, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'ElyaNotes Premium',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleChip('Aylik', !_isYearly, theme),
          const SizedBox(width: 4),
          _toggleChip('Yillik — %44 tasarruf', _isYearly, theme),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _isYearly = label.startsWith('Y')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCards(ThemeData theme) {
    final plans = _getPlans();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: plans
                .map((p) =>
                    Expanded(child: PlanCard(plan: p, onPurchase: _onPurchase)))
                .toList(),
          );
        }
        return Column(
          children: plans
              .map((p) => PlanCard(plan: p, onPurchase: _onPurchase))
              .toList(),
        );
      },
    );
  }

  List<PlanData> _getPlans() {
    return [
      const PlanData(
        title: 'Free',
        features: [
          '3 defter, 3 PDF import',
          '5 dk ses kaydi',
          '15 AI mesaj/gun',
          'Temel cizim araclari',
          'Filiganli export',
        ],
        isCurrentPlan: true,
      ),
      PlanData(
        title: 'Premium',
        subtitle: 'Onerilen',
        price: _isYearly ? '\u20BA83/ay' : '\u20BA149/ay',
        priceSuffix: _isYearly ? '(\u20BA999/yil olarak faturalanir)' : null,
        productId: _isYearly
            ? PaywallProductIds.premiumYearly
            : PaywallProductIds.premiumMonthly,
        features: const [
          'Sinirsiz defter ve PDF',
          'Sinirsiz ses kaydi',
          '150 AI mesaj/gun',
          'DeepSeek V3 + Gemini Flash',
          'Gelismis PDF araclari',
          'Filigransiz export',
          'Bulut senkronizasyon',
        ],
        isHighlighted: true,
      ),
      PlanData(
        title: 'Pro',
        price: _isYearly ? '\u20BA167/ay' : '\u20BA299/ay',
        priceSuffix:
            _isYearly ? '(\u20BA1.999/yil olarak faturalanir)' : null,
        productId: _isYearly
            ? PaywallProductIds.proYearly
            : PaywallProductIds.proMonthly,
        features: const [
          "Premium'daki her sey",
          '1000 AI mesaj/gun',
          'GPT-5 mini + DeepSeek Reasoner',
          'Ses kaydini metne donusturme',
          'AI flashcard olusturma',
          'Oncelikli destek',
        ],
      ),
    ];
  }

  Widget _buildTrialCta(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _onPurchase(
          _isYearly
              ? PaywallProductIds.premiumYearly
              : PaywallProductIds.premiumMonthly,
        ),
        icon: const Icon(Icons.rocket_launch_outlined),
        label: const Text('7 gun ucretsiz dene'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(ThemeData theme) {
    return TextButton(
      onPressed: () {
        ref.read(purchaseStateProvider.notifier).restore();
      },
      child: Text(
        'Satin Almayi Geri Yukle',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Text(
      'Abonelik otomatik olarak yenilenir. Istediginiz zaman iptal '
      'edebilirsiniz. Odeme islemi App Store / Google Play uzerinden '
      'yapilir. Gizlilik politikasi ve kullanim sartlari gecerlidir.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _onPurchase(String productId) {
    ref.read(purchaseStateProvider.notifier).purchase(productId);
  }
}

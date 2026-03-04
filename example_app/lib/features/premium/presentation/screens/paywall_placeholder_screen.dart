import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Paywall screen showing 3 plan tiers with monthly/yearly toggle.
///
/// RevenueCat integration will be added later — buttons currently
/// show a "coming soon" snackbar.
class PaywallPlaceholderScreen extends StatefulWidget {
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
  State<PaywallPlaceholderScreen> createState() => _PaywallState();
}

class _PaywallState extends State<PaywallPlaceholderScreen> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
                  const SizedBox(height: AppSpacing.sm),
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ],
      ),
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
                .map((p) => Expanded(child: _PlanCard(plan: p)))
                .toList(),
          );
        }
        return Column(
          children: plans.map((p) => _PlanCard(plan: p)).toList(),
        );
      },
    );
  }

  List<_PlanData> _getPlans() {
    return [
      const _PlanData(
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
      _PlanData(
        title: 'Premium',
        subtitle: 'Onerilen',
        price: _isYearly ? '\u20BA83/ay' : '\u20BA149/ay',
        priceSuffix: _isYearly ? '(\u20BA999/yil olarak faturalanir)' : null,
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
      _PlanData(
        title: 'Pro',
        price: _isYearly ? '\u20BA167/ay' : '\u20BA299/ay',
        priceSuffix:
            _isYearly ? '(\u20BA1.999/yil olarak faturalanir)' : null,
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
        onPressed: () => _showComingSoon(),
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

  Widget _buildFooter(ThemeData theme) {
    return Text(
      'Istediginiz zaman iptal edebilirsiniz. Odeme islemi App Store / '
      'Google Play uzerinden yapilir.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satin alma yakinda aktif olacak!')),
    );
  }
}

class _PlanData {
  final String title;
  final String? subtitle;
  final String? price;
  final String? priceSuffix;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isHighlighted;

  const _PlanData({
    required this.title,
    this.subtitle,
    this.price,
    this.priceSuffix,
    required this.features,
    this.isCurrentPlan = false,
    this.isHighlighted = false,
  });
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final _PlanData plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = plan.isHighlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Card(
      margin: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: borderColor,
          width: plan.isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plan.subtitle != null) _buildBadge(theme),
            Text(
              plan.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (plan.price != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                plan.price!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (plan.priceSuffix != null)
                Text(
                  plan.priceSuffix!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            ...plan.features.map((f) => _featureRow(f, theme)),
            const SizedBox(height: AppSpacing.lg),
            _buildButton(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        plan.subtitle!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featureRow(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme) {
    if (plan.isCurrentPlan) {
      return const SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: Text('Mevcut Plan'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Satin alma yakinda aktif olacak!')),
          );
        },
        style: plan.isHighlighted
            ? null
            : FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
        child: Text("${plan.title}'a Gec"),
      ),
    );
  }
}

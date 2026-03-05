import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Data model for a subscription plan displayed on the paywall.
class PlanData {
  final String title;
  final String? subtitle;
  final String? price;
  final String? priceSuffix;
  final String? productId;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isHighlighted;

  const PlanData({
    required this.title,
    this.subtitle,
    this.price,
    this.priceSuffix,
    this.productId,
    required this.features,
    this.isCurrentPlan = false,
    this.isHighlighted = false,
  });
}

/// Card widget displaying a single subscription plan tier.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.onPurchase});
  final PlanData plan;
  final ValueChanged<String> onPurchase;

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
            _buildButton(theme),
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

  Widget _buildButton(ThemeData theme) {
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
        onPressed: plan.productId != null
            ? () => onPurchase(plan.productId!)
            : null,
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

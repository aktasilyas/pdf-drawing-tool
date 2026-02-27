import 'package:flutter/material.dart';

/// Temporary paywall placeholder showing 3 plan tiers.
///
/// Will be replaced with RevenueCat integration later.
class PaywallPlaceholderScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme),
          const Divider(height: 1),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlanCards(context, theme),
                const SizedBox(height: 16),
                Text(
                  'Satin alma yakinda aktif olacak.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
      child: Row(
        children: [
          Icon(Icons.star, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'StarNote Premium',
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

  Widget _buildPlanCards(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;
        const cards = [
          _PlanData(
            title: 'Free',
            features: [
              '15 AI mesaj/gun',
              'Gemini Flash',
              'Temel OCR',
            ],
            buttonLabel: 'Mevcut Plan',
            isCurrentPlan: true,
          ),
          _PlanData(
            title: 'Premium',
            subtitle: 'Onerilen',
            features: [
              '150 AI mesaj/gun',
              'GPT-4o mini',
              'Gorsel analiz',
              'Matematik cozme',
            ],
            buttonLabel: 'Yakinda — \u20BA149/ay',
            isHighlighted: true,
          ),
          _PlanData(
            title: 'Pro',
            features: [
              '1000 AI mesaj/gun',
              'GPT-4o',
              'Ileri analiz',
              'Flashcard',
            ],
            buttonLabel: 'Yakinda — \u20BA299/ay',
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards
                .map((p) => Expanded(
                      child: _buildCard(context, theme, p),
                    ))
                .toList(),
          );
        }
        return Column(
          children:
              cards.map((p) => _buildCard(context, theme, p)).toList(),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    _PlanData plan,
  ) {
    final isHighlighted = plan.isHighlighted;
    final borderColor = isHighlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Card(
      margin: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plan.subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              plan.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(child: Text(f,
                          style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: plan.isCurrentPlan
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(plan.buttonLabel),
                    )
                  : FilledButton(
                      onPressed: () => _showComingSoon(context),
                      style: isHighlighted
                          ? null
                          : FilledButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                      child: Text(plan.buttonLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Satin alma yakinda aktif olacak!'),
      ),
    );
  }
}

class _PlanData {
  final String title;
  final String? subtitle;
  final List<String> features;
  final String buttonLabel;
  final bool isCurrentPlan;
  final bool isHighlighted;

  const _PlanData({
    required this.title,
    this.subtitle,
    required this.features,
    required this.buttonLabel,
    this.isCurrentPlan = false,
    this.isHighlighted = false,
  });
}

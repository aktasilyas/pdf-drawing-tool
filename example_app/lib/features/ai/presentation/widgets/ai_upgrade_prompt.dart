import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/premium/presentation/screens/paywall_placeholder_screen.dart';

/// Reason for showing upgrade prompt.
enum AIUpgradeReason {
  dailyLimitReached,
  premiumModelRequested,
  advancedFeature,
}

/// Shows an upgrade prompt when AI limits are reached.
class AIUpgradePrompt extends StatelessWidget {
  const AIUpgradePrompt({
    super.key,
    required this.reason,
    this.onUpgrade,
    this.onDismiss,
  });

  final AIUpgradeReason reason;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  /// Show as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AIUpgradeReason reason,
    VoidCallback? onUpgrade,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AIUpgradePrompt(
        reason: reason,
        onUpgrade: onUpgrade ??
            () {
              Navigator.of(sheetContext).pop();
              PaywallPlaceholderScreen.show(context);
            },
        onDismiss: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(reason);

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.toolbarHeight, height: AppSpacing.toolbarHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome,
                  color: theme.colorScheme.onPrimary, size: AppIconSize.xl),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(config.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text(config.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.xl),
            ...config.features.map((f) => Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        size: AppIconSize.md,
                        color: theme.colorScheme.primary),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(f,
                        style: theme.textTheme.bodyMedium)),
                  ]),
                )),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.star),
                label: Text(config.ctaText),
                style: FilledButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onDismiss,
              child: Text(config.dismissText),
            ),
          ],
        ),
      ),
    );
  }

  _UpgradeConfig _getConfig(AIUpgradeReason reason) {
    return switch (reason) {
      AIUpgradeReason.dailyLimitReached => const _UpgradeConfig(
            title: 'Gunluk Limitine Ulastin',
            description: "Premium'a yukselterek daha fazla AI "
                'mesaji gonder ve guclu modellere eris.',
            features: [
              'Gunde 150 mesaj (15 yerine)',
              'GPT-4o mini ile daha akilli yanitlar',
              'Gelismis matematik cozumu',
              'Gorsel analiz',
            ],
            ctaText: "Premium'a Yukselt",
            dismissText: 'Yarin tekrar dene',
          ),
      AIUpgradeReason.premiumModelRequested => const _UpgradeConfig(
            title: 'Premium Model Gerekli',
            description:
                'Bu ozellik premium AI modelleri gerektirir.',
            features: [
              'GPT-4o ile ileri duzey analiz',
              'Karmasik matematik problemleri',
              'Daha dogru el yazisi tanima',
              'Oncelikli yanit suresi',
            ],
            ctaText: "Premium'a Yukselt",
            dismissText: 'Ucretsiz model ile devam',
          ),
      AIUpgradeReason.advancedFeature => const _UpgradeConfig(
            title: 'Pro Ozellik',
            description: 'Bu ozellik Pro abonelere ozeldir.',
            features: [
              'Sinirsiz AI mesaji',
              'GPT-4o ve o4-mini erisimi',
              'Flashcard olusturma',
              'Sinav hazirlik modu',
            ],
            ctaText: "Pro'ya Yukselt",
            dismissText: 'Daha sonra',
          ),
    };
  }
}

class _UpgradeConfig {
  final String title;
  final String description;
  final List<String> features;
  final String ctaText;
  final String dismissText;

  const _UpgradeConfig({
    required this.title,
    required this.description,
    required this.features,
    required this.ctaText,
    required this.dismissText,
  });
}

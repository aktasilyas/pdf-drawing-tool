import 'package:flutter/material.dart';

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
      builder: (_) => AIUpgradePrompt(
        reason: reason,
        onUpgrade: onUpgrade,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(reason);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(config.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(config.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ...config.features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f,
                        style: theme.textTheme.bodyMedium)),
                  ]),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.star),
                label: Text(config.ctaText),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            title: 'Günlük Limitine Ulaştın',
            description: "Premium'a yükselterek daha fazla AI "
                'mesajı gönder ve güçlü modellere eriş.',
            features: [
              'Günde 150 mesaj (15 yerine)',
              'GPT-4o mini ile daha akıllı yanıtlar',
              'Gelişmiş matematik çözümü',
              'Görsel analiz',
            ],
            ctaText: "Premium'a Yükselt",
            dismissText: 'Yarın tekrar dene',
          ),
      AIUpgradeReason.premiumModelRequested => const _UpgradeConfig(
            title: 'Premium Model Gerekli',
            description:
                'Bu özellik premium AI modelleri gerektirir.',
            features: [
              'GPT-4o ile ileri düzey analiz',
              'Karmaşık matematik problemleri',
              'Daha doğru el yazısı tanıma',
              'Öncelikli yanıt süresi',
            ],
            ctaText: "Premium'a Yükselt",
            dismissText: 'Ücretsiz model ile devam',
          ),
      AIUpgradeReason.advancedFeature => const _UpgradeConfig(
            title: 'Pro Özellik',
            description: 'Bu özellik Pro abonelere özeldir.',
            features: [
              'Sınırsız AI mesajı',
              'GPT-4o ve o4-mini erişimi',
              'Flashcard oluşturma',
              'Sınav hazırlık modu',
            ],
            ctaText: "Pro'ya Yükselt",
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

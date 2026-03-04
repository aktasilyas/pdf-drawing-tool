import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';

/// Contextual upgrade prompt shown as a bottom sheet.
/// Non-aggressive, informative tone: "Unlock more with Premium".
class UpgradePromptSheet extends StatelessWidget {
  const UpgradePromptSheet({
    super.key,
    required this.access,
    required this.featureIcon,
    required this.featureTitle,
    this.onUpgrade,
    this.onDismiss,
  });

  final FeatureAccess access;
  final IconData featureIcon;
  final String featureTitle;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  /// Show as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required FeatureAccess access,
    required IconData featureIcon,
    required String featureTitle,
    VoidCallback? onUpgrade,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(
        access: access,
        featureIcon: featureIcon,
        featureTitle: featureTitle,
        onUpgrade: onUpgrade ?? () => Navigator.pop(context),
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(theme),
            const SizedBox(height: AppSpacing.xl),
            _buildIcon(theme),
            const SizedBox(height: AppSpacing.md),
            _buildTitle(theme),
            const SizedBox(height: AppSpacing.sm),
            _buildDescription(theme),
            if (_hasUsageBar) ...[
              const SizedBox(height: AppSpacing.md),
              _buildUsageBar(theme),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildUpgradeButton(theme),
            const SizedBox(height: AppSpacing.sm),
            _buildDismissButton(theme),
          ],
        ),
      ),
    );
  }

  bool get _hasUsageBar =>
      access.currentUsage != null && access.maxUsage != null;

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        featureIcon,
        size: 32,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      featureTitle,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      access.upgradeMessage ??
          'Bu özellik Premium planla kullanılabilir.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUsageBar(ThemeData theme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: access.usageRatio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              access.isNearLimit
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${access.currentUsage} / ${access.maxUsage} kullanıldı',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onUpgrade,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: const Text("Premium'a Geç"),
      ),
    );
  }

  Widget _buildDismissButton(ThemeData theme) {
    return TextButton(
      onPressed: onDismiss,
      child: Text(
        'Şimdilik Değil',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Compact usage indicator showing daily AI message quota.
///
/// Displays as a thin progress bar with text like "5/15 mesaj".
/// Changes color from primary → orange → red as limit approaches.
class AIUsageBar extends ConsumerWidget {
  const AIUsageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(aiUsageProvider);
    final modelName = ref.watch(aiModelNameProvider);
    final theme = Theme.of(context);

    return usageAsync.when(
      data: (usage) {
        final used = usage.dailyMessagesUsed;
        final limit = usage.dailyMessagesLimit;
        final percent =
            limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

        final color = percent < 0.6
            ? theme.colorScheme.primary
            : percent < 0.85
                ? Colors.orange
                : theme.colorScheme.error;

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      modelName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$used / $limit mesaj',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 3,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

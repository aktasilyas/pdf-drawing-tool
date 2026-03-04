import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Tappable suggestion chips shown after AI responses.
class AISuggestionChips extends StatelessWidget {
  const AISuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: suggestions.map((suggestion) {
          return ActionChip(
            label: Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            onPressed: () => onTap(suggestion),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Displays the currently streaming AI response with a typing cursor.
class AIStreamingBubble extends StatelessWidget {
  const AIStreamingBubble({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                theme.colorScheme.secondary.withValues(alpha: 0.1),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: content.isEmpty
                  ? _buildLoadingDots(theme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: content,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(theme)
                                  .copyWith(
                            p: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildCursor(theme),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Düşünüyor',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(width: 4),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCursor(ThemeData theme) {
    return SizedBox(
      width: 8,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

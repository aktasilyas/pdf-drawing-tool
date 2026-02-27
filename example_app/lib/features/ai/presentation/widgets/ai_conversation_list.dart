import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Displays the list of past AI conversations.
class AIConversationList extends ConsumerWidget {
  const AIConversationList({
    super.key,
    required this.onConversationSelected,
    this.currentConversationId,
  });

  final ValueChanged<String> onConversationSelected;
  final String? currentConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(aiConversationsProvider);
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildHeader(theme),
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) =>
                  _buildList(conversations, theme, ref),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child:
                    Text('Hata: $e', style: theme.textTheme.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.history,
              size: AppIconSize.md, color: theme.colorScheme.primary),
          SizedBox(width: AppSpacing.sm),
          Text('Sohbet Gecmisi',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildList(
    List<AIConversation> conversations,
    ThemeData theme,
    WidgetRef ref,
  ) {
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          'Henuz sohbet yok',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final isActive = conv.id == currentConversationId;
        return _ConversationTile(
          conversation: conv,
          isActive: isActive,
          onTap: () => onConversationSelected(conv.id),
          onDelete: () async {
            final repo = ref.read(aiRepositoryProvider);
            await repo.deleteConversation(conv.id);
            refreshConversations(ref);
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final AIConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      selected: isActive,
      selectedTileColor:
          theme.colorScheme.primary.withValues(alpha: 0.1),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.xxs,
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        timeago.format(conversation.updatedAt, locale: 'tr'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, size: AppIconSize.sm + 2),
        onPressed: onDelete,
        visualDensity: VisualDensity.compact,
        tooltip: 'Sil',
      ),
      onTap: onTap,
    );
  }
}

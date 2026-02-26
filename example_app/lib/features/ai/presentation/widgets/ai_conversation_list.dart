import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

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

    return Container(
      width: 280,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.history,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Sohbet Geçmişi',
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
          'Henüz sohbet yok',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Sil',
      ),
      onTap: onTap,
    );
  }
}

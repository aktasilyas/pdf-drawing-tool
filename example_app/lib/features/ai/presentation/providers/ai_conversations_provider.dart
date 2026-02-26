import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Provider for the list of AI conversations.
final aiConversationsProvider =
    FutureProvider.autoDispose<List<AIConversation>>((ref) async {
  final repository = ref.watch(aiRepositoryProvider);
  return repository.getConversations();
});

/// Refresh conversations list.
void refreshConversations(WidgetRef ref) {
  ref.invalidate(aiConversationsProvider);
}

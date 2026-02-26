import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// Contract for AI data operations.
abstract class AIRepository {
  /// Send a message and receive streaming response chunks.
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  });

  /// Get all conversations for current user.
  Future<List<AIConversation>> getConversations();

  /// Get messages for a specific conversation.
  Future<List<AIMessage>> getMessages(String conversationId);

  /// Create a new conversation.
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  });

  /// Delete a conversation and all its messages.
  Future<void> deleteConversation(String conversationId);

  /// Get current user's AI usage statistics.
  Future<AIUsage> getUsage();

  /// Update conversation title.
  Future<void> updateConversationTitle(String conversationId, String title);
}

import 'package:drift/drift.dart';

import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// Local data source for AI conversations and messages using Drift.
class AILocalDataSource {
  final AppDatabase _db;

  AILocalDataSource(this._db);

  // ─── Conversations ──────────────────────────────────

  /// Get all conversations for a user, sorted by most recent.
  Future<List<AIConversation>> getConversations(String userId) async {
    final rows = await (_db.select(_db.aiConversationsLocal)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    return rows.map(_rowToConversation).toList();
  }

  /// Get a single conversation by ID.
  Future<AIConversation?> getConversation(String id) async {
    final row = await (_db.select(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return row != null ? _rowToConversation(row) : null;
  }

  /// Insert or update a conversation.
  Future<void> upsertConversation(AIConversation conversation) async {
    await _db.into(_db.aiConversationsLocal).insertOnConflictUpdate(
          AiConversationsLocalCompanion.insert(
            id: conversation.id,
            userId: conversation.userId,
            title: Value(conversation.title),
            documentId: Value(conversation.documentId),
            taskType: Value(conversation.taskType),
            totalInputTokens: Value(conversation.totalInputTokens),
            totalOutputTokens: Value(conversation.totalOutputTokens),
            messageCount: Value(conversation.messageCount),
            isPinned: Value(conversation.isPinned),
            isSynced: const Value(false),
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
          ),
        );
  }

  /// Delete a conversation and its messages.
  Future<void> deleteConversation(String conversationId) async {
    await (_db.delete(_db.aiMessagesLocal)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
    await (_db.delete(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .go();
  }

  /// Update conversation title.
  Future<void> updateTitle(String conversationId, String title) async {
    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsLocalCompanion(
      title: Value(title),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
  }

  // ─── Messages ────────────────────────────────────────

  /// Get all messages for a conversation.
  Future<List<AIMessage>> getMessages(String conversationId) async {
    final rows = await (_db.select(_db.aiMessagesLocal)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    return rows.map(_rowToMessage).toList();
  }

  /// Insert a message.
  Future<void> insertMessage(AIMessage message) async {
    await _db.into(_db.aiMessagesLocal).insertOnConflictUpdate(
          AiMessagesLocalCompanion.insert(
            id: message.id,
            conversationId: message.conversationId,
            role: message.role.name,
            content: message.content,
            model: Value(message.model),
            provider: Value(message.provider),
            inputTokens: Value(message.inputTokens),
            outputTokens: Value(message.outputTokens),
            hasImage: Value(message.hasImage),
            imagePath: Value(message.imagePath),
            isSynced: const Value(false),
            createdAt: message.createdAt,
          ),
        );

    await _incrementMessageCount(message.conversationId);
  }

  /// Get unsynced messages for cloud sync.
  Future<List<AIMessage>> getUnsyncedMessages() async {
    final rows = await (_db.select(_db.aiMessagesLocal)
          ..where((t) => t.isSynced.equals(false)))
        .get();

    return rows.map(_rowToMessage).toList();
  }

  /// Mark messages as synced.
  Future<void> markMessagesSynced(List<String> messageIds) async {
    await (_db.update(_db.aiMessagesLocal)
          ..where((t) => t.id.isIn(messageIds)))
        .write(const AiMessagesLocalCompanion(isSynced: Value(true)));
  }

  /// Mark a conversation as synced.
  Future<void> markConversationSynced(String conversationId) async {
    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(const AiConversationsLocalCompanion(isSynced: Value(true)));
  }

  // ─── Private Helpers ─────────────────────────────────

  Future<void> _incrementMessageCount(String conversationId) async {
    final conv = await getConversation(conversationId);
    if (conv == null) return;

    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsLocalCompanion(
      messageCount: Value(conv.messageCount + 1),
      updatedAt: Value(DateTime.now()),
    ));
  }

  AIConversation _rowToConversation(AiConversationsLocalData row) {
    return AIConversation(
      id: row.id,
      userId: row.userId,
      title: row.title,
      documentId: row.documentId,
      taskType: row.taskType,
      totalInputTokens: row.totalInputTokens,
      totalOutputTokens: row.totalOutputTokens,
      messageCount: row.messageCount,
      isPinned: row.isPinned,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  AIMessage _rowToMessage(AiMessagesLocalData row) {
    return AIMessage(
      id: row.id,
      conversationId: row.conversationId,
      role: MessageRole.values.firstWhere(
        (r) => r.name == row.role,
        orElse: () => MessageRole.user,
      ),
      content: row.content,
      model: row.model,
      provider: row.provider,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      hasImage: row.hasImage,
      imagePath: row.imagePath,
      createdAt: row.createdAt,
    );
  }
}

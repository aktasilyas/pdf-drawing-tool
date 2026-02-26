import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_local_datasource.dart';
import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// AI Repository implementation using local-first pattern.
///
/// Messages are saved to Drift (SQLite) first, then synced to Supabase.
class AIRepositoryImpl implements AIRepository {
  final AIRemoteDataSource _remoteDataSource;
  final AILocalDataSource _localDataSource;
  final SubscriptionTier _userTier;

  AIRepositoryImpl({
    required AIRemoteDataSource remoteDataSource,
    required AILocalDataSource localDataSource,
    required SubscriptionTier userTier,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _userTier = userTier;

  @override
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  }) async* {
    // 1. Save user message locally
    final userMsg = AIMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      conversationId: conversationId,
      role: MessageRole.user,
      content: message,
      hasImage: imageBase64 != null,
      createdAt: DateTime.now(),
    );
    await _localDataSource.insertMessage(userMsg);

    // 2. Stream from remote
    final buffer = StringBuffer();
    await for (final chunk in _remoteDataSource.chat(
      messages: [
        {'role': 'user', 'content': message},
      ],
      taskType: _mapTaskType(taskType),
      conversationId: conversationId,
      imageBase64: imageBase64,
    )) {
      buffer.write(chunk);
      yield chunk;
    }

    // 3. Save assistant message locally
    final assistantMsg = AIMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      createdAt: DateTime.now(),
    );
    await _localDataSource.insertMessage(assistantMsg);

    // 4. Fire-and-forget: sync to Supabase
    _syncMessageToCloud(userMsg);
    _syncMessageToCloud(assistantMsg);
  }

  @override
  Future<List<AIConversation>> getConversations() async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    // Local-first: read from Drift
    final local = await _localDataSource.getConversations(userId);
    if (local.isNotEmpty) return local;

    // Local empty → fetch from remote and cache
    try {
      final remote = await _remoteDataSource.getConversations();
      for (final json in remote) {
        final conv = AIConversation.fromJson(_mapKeys(json));
        await _localDataSource.upsertConversation(conv);
      }
      return _localDataSource.getConversations(userId);
    } catch (_) {
      return local;
    }
  }

  @override
  Future<List<AIMessage>> getMessages(String conversationId) async {
    // Local-first: read from Drift
    final local = await _localDataSource.getMessages(conversationId);
    if (local.isNotEmpty) return local;

    // Local empty → fetch from remote and cache
    try {
      final remote = await _remoteDataSource.getMessages(conversationId);
      for (final json in remote) {
        final msg = AIMessage.fromJson(_mapKeys(json));
        await _localDataSource.insertMessage(msg);
      }
      return _localDataSource.getMessages(conversationId);
    } catch (_) {
      return local;
    }
  }

  @override
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    // Create on remote first (to get server-generated ID)
    final data = await _remoteDataSource.createConversation(
      documentId: documentId,
      taskType: taskType,
    );
    final conversation = AIConversation.fromJson(_mapKeys(data));

    // Cache locally
    await _localDataSource.upsertConversation(conversation);

    return conversation;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    // Delete locally first
    await _localDataSource.deleteConversation(conversationId);
    // Then remote (fire-and-forget)
    try {
      await _remoteDataSource.deleteConversation(conversationId);
    } catch (_) {
      // Offline — will sync later
    }
  }

  @override
  Future<AIUsage> getUsage() async {
    final dailyCount = await _remoteDataSource.getDailyMessageCount();
    final monthlyTokens = await _remoteDataSource.getMonthlyTokenUsage();

    final limits = _getTierLimits();

    return AIUsage(
      dailyMessagesUsed: dailyCount,
      dailyMessagesLimit: limits['dailyMessages']!,
      monthlyTokensUsed: monthlyTokens['input']! + monthlyTokens['output']!,
      monthlyTokensLimit: limits['monthlyTokens']!,
    );
  }

  @override
  Future<void> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    await _localDataSource.updateTitle(conversationId, title);
    try {
      await Supabase.instance.client
          .from('ai_conversations')
          .update({'title': title})
          .eq('id', conversationId);
    } catch (_) {
      // Offline — local already updated
    }
  }

  // ─── Private Helpers ─────────────────────────────────

  Future<void> _syncMessageToCloud(AIMessage message) async {
    try {
      await _remoteDataSource.saveMessage(
        conversationId: message.conversationId,
        role: message.role.name,
        content: message.content,
        model: message.model,
        provider: message.provider,
        inputTokens: message.inputTokens,
        outputTokens: message.outputTokens,
        hasImage: message.hasImage,
        imagePath: message.imagePath,
      );
      await _localDataSource.markMessagesSynced([message.id]);
    } catch (_) {
      // Offline — sync later
    }
  }

  String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  Map<String, int> _getTierLimits() {
    switch (_userTier) {
      case SubscriptionTier.free:
        return {'dailyMessages': 15, 'monthlyTokens': 50000};
      case SubscriptionTier.premium:
        return {'dailyMessages': 150, 'monthlyTokens': 500000};
      case SubscriptionTier.premiumPlus:
        return {'dailyMessages': 1000, 'monthlyTokens': 5000000};
    }
  }

  String _mapTaskType(AITaskType type) {
    return switch (type) {
      AITaskType.chat => 'chat',
      AITaskType.mathSimple => 'math_simple',
      AITaskType.mathAdvanced => 'math_advanced',
      AITaskType.ocrSimple => 'ocr_simple',
      AITaskType.ocrComplex => 'ocr_complex',
      AITaskType.summarizeShort => 'summarize_short',
      AITaskType.summarizeLong => 'summarize_long',
    };
  }

  /// Convert snake_case Supabase keys to camelCase for freezed.
  Map<String, dynamic> _mapKeys(Map<String, dynamic> json) {
    return json.map((key, value) {
      final camelKey = key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (m) => m.group(1)!.toUpperCase(),
      );
      return MapEntry(camelKey, value);
    });
  }
}

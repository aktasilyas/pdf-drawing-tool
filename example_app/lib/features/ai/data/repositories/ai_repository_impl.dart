import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// AI Repository implementation using Supabase Edge Functions.
class AIRepositoryImpl implements AIRepository {
  final AIRemoteDataSource _remoteDataSource;
  final SubscriptionTier _userTier;

  AIRepositoryImpl({
    required AIRemoteDataSource remoteDataSource,
    required SubscriptionTier userTier,
  })  : _remoteDataSource = remoteDataSource,
        _userTier = userTier;

  @override
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  }) {
    return _remoteDataSource.chat(
      messages: [
        {'role': 'user', 'content': message},
      ],
      taskType: _mapTaskType(taskType),
      conversationId: conversationId,
      imageBase64: imageBase64,
    );
  }

  @override
  Future<List<AIConversation>> getConversations() async {
    final data = await _remoteDataSource.getConversations();
    return data
        .map((json) => AIConversation.fromJson(_mapKeys(json)))
        .toList();
  }

  @override
  Future<List<AIMessage>> getMessages(String conversationId) async {
    final data = await _remoteDataSource.getMessages(conversationId);
    return data.map((json) => AIMessage.fromJson(_mapKeys(json))).toList();
  }

  @override
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    final data = await _remoteDataSource.createConversation(
      documentId: documentId,
      taskType: taskType,
    );
    return AIConversation.fromJson(_mapKeys(data));
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _remoteDataSource.deleteConversation(conversationId);
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
    await Supabase.instance.client
        .from('ai_conversations')
        .update({'title': title})
        .eq('id', conversationId);
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

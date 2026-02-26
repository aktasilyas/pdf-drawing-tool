import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_conversation.freezed.dart';
part 'ai_conversation.g.dart';

/// Domain entity for an AI conversation (chat session).
@freezed
class AIConversation with _$AIConversation {
  const factory AIConversation({
    required String id,
    required String userId,
    @Default('Yeni Sohbet') String title,
    String? documentId,
    @Default('chat') String taskType,
    @Default(0) int totalInputTokens,
    @Default(0) int totalOutputTokens,
    @Default(0) int messageCount,
    @Default(false) bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AIConversation;

  factory AIConversation.fromJson(Map<String, dynamic> json) =>
      _$AIConversationFromJson(json);
}

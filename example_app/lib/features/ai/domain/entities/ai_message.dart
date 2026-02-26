import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_message.freezed.dart';
part 'ai_message.g.dart';

/// AI chat message role.
enum MessageRole {
  user,
  assistant,
  system,
}

/// Domain entity for a single AI chat message.
@freezed
class AIMessage with _$AIMessage {
  const factory AIMessage({
    required String id,
    required String conversationId,
    required MessageRole role,
    required String content,
    String? model,
    String? provider,
    @Default(0) int inputTokens,
    @Default(0) int outputTokens,
    @Default(false) bool hasImage,
    String? imagePath,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _AIMessage;

  factory AIMessage.fromJson(Map<String, dynamic> json) =>
      _$AIMessageFromJson(json);
}

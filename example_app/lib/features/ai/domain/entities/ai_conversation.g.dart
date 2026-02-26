// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIConversationImpl _$$AIConversationImplFromJson(Map<String, dynamic> json) =>
    _$AIConversationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? 'Yeni Sohbet',
      documentId: json['documentId'] as String?,
      taskType: json['taskType'] as String? ?? 'chat',
      totalInputTokens: (json['totalInputTokens'] as num?)?.toInt() ?? 0,
      totalOutputTokens: (json['totalOutputTokens'] as num?)?.toInt() ?? 0,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AIConversationImplToJson(
        _$AIConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'documentId': instance.documentId,
      'taskType': instance.taskType,
      'totalInputTokens': instance.totalInputTokens,
      'totalOutputTokens': instance.totalOutputTokens,
      'messageCount': instance.messageCount,
      'isPinned': instance.isPinned,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

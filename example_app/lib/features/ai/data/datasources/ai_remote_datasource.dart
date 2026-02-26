import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_exceptions.dart';

/// Remote data source for AI operations via Supabase Edge Functions.
class AIRemoteDataSource {
  final SupabaseClient _supabase;
  final String _supabaseUrl;
  final String _supabaseKey;

  AIRemoteDataSource(
    this._supabase, {
    required String supabaseUrl,
    required String supabaseKey,
  })  : _supabaseUrl = supabaseUrl,
        _supabaseKey = supabaseKey;

  /// Sends a chat message and returns streaming response chunks.
  ///
  /// Uses SSE (Server-Sent Events) to stream AI responses token by token.
  /// Each yielded String is a text delta to append to the UI.
  Stream<String> chat({
    required List<Map<String, dynamic>> messages,
    required String taskType,
    required String conversationId,
    String tier = 'free',
    String? imageBase64,
  }) async* {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '$_supabaseUrl/functions/v1/ai-chat',
    );

    final body = jsonEncode({
      'messages': messages,
      'taskType': taskType,
      'conversationId': conversationId,
      'tier': tier,
      if (imageBase64 != null) 'image': imageBase64,
    });

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'apikey': _supabaseKey,
      })
      ..body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode == 429) {
        final errorBody = await response.stream.bytesToString();
        final errorJson = jsonDecode(errorBody);
        throw AIRateLimitException(
          message: errorJson['message'] ?? 'Rate limit exceeded',
          remaining: errorJson['remaining'] ?? 0,
          resetAt: errorJson['resetAt'] != null
              ? DateTime.parse(errorJson['resetAt'])
              : null,
        );
      }

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw AIProviderException(
          'AI service error (${response.statusCode}): $errorBody',
        );
      }

      // Parse SSE stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data.isEmpty) continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;

            if (json['done'] == true) return;

            final content = json['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// Create a new conversation in Supabase.
  Future<Map<String, dynamic>> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase.from('ai_conversations').insert({
      'user_id': user.id,
      'document_id': documentId,
      'task_type': taskType,
    }).select().single();

    return response;
  }

  /// Get conversations for current user.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    return _supabase
        .from('ai_conversations')
        .select()
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);
  }

  /// Get messages for a conversation.
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    return _supabase
        .from('ai_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  /// Save a message to Supabase.
  Future<Map<String, dynamic>> saveMessage({
    required String conversationId,
    required String role,
    required String content,
    String? model,
    String? provider,
    int inputTokens = 0,
    int outputTokens = 0,
    bool hasImage = false,
    String? imagePath,
  }) async {
    final response = await _supabase.from('ai_messages').insert({
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'model': model,
      'provider': provider,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'has_image': hasImage,
      'image_path': imagePath,
    }).select().single();

    await _supabase.rpc('increment_token_usage', params: {
      'p_user_id': _supabase.auth.currentUser!.id,
      'p_date': DateTime.now().toIso8601String().split('T')[0],
      'p_model': model ?? 'unknown',
      'p_provider': provider ?? 'unknown',
      'p_input_tokens': inputTokens,
      'p_output_tokens': outputTokens,
      'p_request_count': 1,
    });

    return response;
  }

  /// Delete a conversation.
  Future<void> deleteConversation(String conversationId) async {
    await _supabase
        .from('ai_conversations')
        .delete()
        .eq('id', conversationId);
  }

  /// Get daily message count for current user.
  Future<int> getDailyMessageCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final result = await _supabase.rpc('get_daily_ai_message_count', params: {
      'p_user_id': user.id,
    });

    return (result as int?) ?? 0;
  }

  /// Get monthly token usage.
  Future<Map<String, int>> getMonthlyTokenUsage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'input': 0, 'output': 0};

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final result = await _supabase
        .from('ai_token_usage_daily')
        .select('input_tokens, output_tokens')
        .eq('user_id', user.id)
        .gte('date', monthStart.toIso8601String().split('T')[0]);

    int totalInput = 0;
    int totalOutput = 0;
    for (final row in result) {
      totalInput += (row['input_tokens'] as int?) ?? 0;
      totalOutput += (row['output_tokens'] as int?) ?? 0;
    }

    return {'input': totalInput, 'output': totalOutput};
  }
}

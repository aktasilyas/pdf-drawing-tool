import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/utils/logger.dart';
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
    // Mevcut session'ı al, expire olduysa refresh et
    var session = _supabase.auth.currentSession;
    if (session == null) {
      logger.e('[AI] Not authenticated — no active session');
      throw Exception('Not authenticated');
    }

    logger.d('[AI] Token expired=${session.isExpired}, '
        'expiresAt=${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}');

    // Token expire olduysa refresh dene
    if (session.isExpired) {
      logger.w('[AI] JWT expired, refreshing...');
      await _supabase.auth.refreshSession();
      session = _supabase.auth.currentSession;
      if (session == null) {
        logger.e('[AI] Session refresh failed — no new session');
        throw Exception('Session expired. Please sign in again.');
      }
      logger.i('[AI] Session refreshed successfully');
    }

    final uri = Uri.parse('$_supabaseUrl/functions/v1/ai-chat');

    logger.i('[AI] Sending request: taskType=$taskType, tier=$tier, '
        'messages=${messages.length}, hasImage=${imageBase64 != null}');

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
      final response = await client.send(request).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('[AI] HTTP request timed out after 30s');
              throw TimeoutException('AI request timed out', const Duration(seconds: 30));
            },
          );

      logger.i('[AI] Response status: ${response.statusCode}, '
          'model: ${response.headers['x-model']}, '
          'provider: ${response.headers['x-provider']}, '
          'remaining: ${response.headers['x-ratelimit-remaining']}');

      if (response.statusCode == 429) {
        final errorBody = await response.stream.bytesToString();
        logger.w('[AI] Rate limit hit: $errorBody');
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
        logger.e('[AI] Server error ${response.statusCode}: $errorBody');
        throw AIProviderException(
          'AI service error (${response.statusCode}): $errorBody',
        );
      }

      // Parse SSE stream with line buffering to handle chunk boundaries
      var sseBuffer = '';
      int chunkCount = 0;
      int yieldCount = 0;

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        chunkCount++;
        sseBuffer += chunk;

        // Process complete lines only (split on double newline for SSE)
        while (sseBuffer.contains('\n')) {
          final newlineIndex = sseBuffer.indexOf('\n');
          final line = sseBuffer.substring(0, newlineIndex).trim();
          sseBuffer = sseBuffer.substring(newlineIndex + 1);

          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final data = line.substring(6).trim();
          if (data.isEmpty) continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;

            if (json['done'] == true) {
              logger.i('[AI] Stream done. '
                  'Chunks: $chunkCount, yields: $yieldCount, '
                  'usage: ${json['usage']}');
              return;
            }

            final content = json['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yieldCount++;
              yield content;
            }
          } catch (e) {
            logger.w('[AI] Malformed SSE data: "$data", error: $e');
          }
        }
      }

      logger.w('[AI] Stream ended without done signal. '
          'Chunks: $chunkCount, yields: $yieldCount');
    } on TimeoutException {
      rethrow;
    } catch (e, st) {
      logger.e('[AI] Stream error', error: e, stackTrace: st);
      rethrow;
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

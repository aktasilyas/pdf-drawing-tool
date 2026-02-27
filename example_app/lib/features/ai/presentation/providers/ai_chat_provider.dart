import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// State for a single AI chat conversation.
class AIChatState {
  final List<AIMessage> messages;
  final bool isStreaming;
  final String streamingContent;
  final String? error;
  final String? conversationId;
  final bool isLoading;

  const AIChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamingContent = '',
    this.error,
    this.conversationId,
    this.isLoading = false,
  });

  AIChatState copyWith({
    List<AIMessage>? messages,
    bool? isStreaming,
    String? streamingContent,
    String? error,
    String? conversationId,
    bool? isLoading,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingContent: streamingContent ?? this.streamingContent,
      error: error,
      conversationId: conversationId ?? this.conversationId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for AI chat state management.
///
/// Handles sending messages, streaming responses, and canvas capture.
class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIRepository _repository;
  final CanvasCaptureService _captureService;
  StreamSubscription<String>? _streamSubscription;

  AIChatNotifier({
    required AIRepository repository,
    required CanvasCaptureService captureService,
  })  : _repository = repository,
        _captureService = captureService,
        super(const AIChatState());

  /// Initialize with a new or existing conversation.
  Future<void> initialize({String? existingConversationId}) async {
    await _streamSubscription?.cancel();

    if (existingConversationId != null) {
      state = AIChatState(
        isLoading: true,
        conversationId: existingConversationId,
      );
      try {
        final messages =
            await _repository.getMessages(existingConversationId);
        state = state.copyWith(messages: messages, isLoading: false);
      } catch (e) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      }
    } else {
      try {
        final conversation = await _repository.createConversation();
        state = state.copyWith(conversationId: conversation.id);
      } catch (e) {
        state = state.copyWith(error: 'Sohbet oluşturulamadı: $e');
      }
    }
  }

  /// Send a text message to the AI.
  Future<void> sendMessage(
    String text, {
    AITaskType taskType = AITaskType.chat,
  }) async {
    await _send(text: text, taskType: taskType);
  }

  /// Send a message with pre-captured image bytes (e.g. from selection).
  Future<void> sendWithImageBytes(
    String text,
    Uint8List imageBytes, {
    AITaskType taskType = AITaskType.ocrSimple,
  }) async {
    final imageBase64 = base64Encode(imageBytes);
    await _send(text: text, taskType: taskType, imageBase64: imageBase64);
  }

  /// Capture canvas and send with a prompt to the AI.
  Future<void> sendWithCanvas(
    String text, {
    required GlobalKey canvasBoundaryKey,
    AITaskType taskType = AITaskType.ocrSimple,
  }) async {
    state = state.copyWith(isLoading: true);

    final imageBase64 = await _captureService.captureAsBase64(
      canvasBoundaryKey,
    );

    if (imageBase64 == null) {
      state = state.copyWith(
        error: 'Canvas yakalanamadı',
        isLoading: false,
      );
      return;
    }

    await _send(text: text, taskType: taskType, imageBase64: imageBase64);
  }

  /// Core send logic with streaming.
  Future<void> _send({
    required String text,
    required AITaskType taskType,
    String? imageBase64,
  }) async {
    if (state.conversationId == null) {
      state = state.copyWith(error: 'Sohbet başlatılmadı');
      return;
    }

    // Cancel any existing stream
    await _streamSubscription?.cancel();

    // Add user message to UI immediately
    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: state.conversationId!,
      role: MessageRole.user,
      content: text,
      hasImage: imageBase64 != null,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      streamingContent: '',
      error: null,
      isLoading: false,
    );

    // Stream AI response
    final buffer = StringBuffer();

    try {
      final stream = _repository.sendMessage(
        conversationId: state.conversationId!,
        message: text,
        taskType: taskType,
        imageBase64: imageBase64,
      );

      _streamSubscription = stream.listen(
        (chunk) {
          buffer.write(chunk);
          state = state.copyWith(streamingContent: buffer.toString());
        },
        onDone: () {
          final assistantMessage = AIMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_ai',
            conversationId: state.conversationId!,
            role: MessageRole.assistant,
            content: buffer.toString(),
            createdAt: DateTime.now(),
          );

          state = state.copyWith(
            messages: [...state.messages, assistantMessage],
            isStreaming: false,
            streamingContent: '',
          );

          _autoTitleIfNeeded(text);
        },
        onError: (error) {
          state = state.copyWith(
            isStreaming: false,
            streamingContent: '',
            error: _mapError(error),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        streamingContent: '',
        error: _mapError(e),
      );
    }
  }

  /// Auto-generate a title from the first user message.
  ///
  /// Only runs once — when the conversation has exactly one user message
  /// (the first exchange). Truncates to 40 chars.
  void _autoTitleIfNeeded(String firstMessage) {
    // Only auto-title on the first user message
    final userMessages =
        state.messages.where((m) => m.role == MessageRole.user);
    if (userMessages.length != 1 || state.conversationId == null) return;

    final title = _generateTitle(firstMessage);
    _repository.updateConversationTitle(state.conversationId!, title);
  }

  String _generateTitle(String message) {
    var title = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (title.length > 40) {
      title = '${title.substring(0, 37)}...';
    }
    return title;
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Start a new conversation.
  Future<void> newConversation() async {
    await _streamSubscription?.cancel();
    state = const AIChatState();
    await initialize();
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('rate_limit') || msg.contains('429')) {
      return 'Günlük mesaj limitine ulaştınız. '
          "Yarın tekrar deneyin veya Premium'a yükseltin.";
    }
    if (msg.contains('unauthorized') || msg.contains('401')) {
      return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// Provider instance for AI chat.
///
/// Not autoDispose — sidebar open/close should preserve chat state.
/// Manually invalidated when leaving the editor screen.
final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  final captureService = ref.watch(canvasCaptureServiceProvider);
  return AIChatNotifier(
    repository: repository,
    captureService: captureService,
  );
});

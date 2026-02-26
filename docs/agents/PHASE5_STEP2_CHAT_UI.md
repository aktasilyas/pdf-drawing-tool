# PHASE 5 — STEP 2: Canvas Capture + AI Chat UI + Riverpod Providers

## ÖZET
Canvas'ı screenshot olarak yakalayıp AI'a gönderebilen, streaming yanıtları gösteren AI chat modal'ını oluştur. Bu step sonunda kullanıcı toolbar'daki AI butonuna basınca chat modal açılacak, mesaj yazabilecek, canvas screenshot gönderebilecek ve streaming yanıt görecek.

## BRANCH
```bash
git checkout feature/ai-integration-step1
# Aynı branch üzerinde devam — henüz merge etmedik
```

---

## MİMARİ KARARLAR

1. **Canvas capture** → `canvasBoundaryKeyProvider` zaten mevcut (drawing_ui), capture service example_app'te olacak
2. **AI state** → Riverpod StateNotifier/AsyncNotifier pattern (mevcut proje tarzı)
3. **Chat UI** → Full-screen modal bottom sheet (telefon) veya side panel (tablet) — başlangıç olarak modal
4. **Streaming** → StreamBuilder ile token-by-token text append
5. **Markdown/LaTeX** → flutter_markdown + flutter_math_fork ile rendering
6. **drawing_ui'ya dokunma** → AI UI tamamen example_app/features/ai/presentation/ altında

---

## @flutter-developer — İMPLEMENTASYON

### BÖLÜM A: Canvas Capture Service

**Önce oku:**
- `packages/drawing_ui/lib/src/providers/infinite_canvas_provider.dart` → `canvasBoundaryKeyProvider`
- `packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart` → RepaintBoundary kullanımı

**1) OLUŞTUR: `example_app/lib/features/ai/data/services/canvas_capture_service.dart`**

```dart
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the drawing canvas as a base64-encoded PNG image.
///
/// Uses RepaintBoundary to capture the canvas content.
/// The captured image is optimized for AI APIs:
/// - White background (not transparent)
/// - Max 1568px dimension (safe for all AI providers)
/// - PNG format for sharp stroke edges
class CanvasCaptureService {
  /// Capture the canvas and return a base64-encoded PNG string.
  ///
  /// [boundaryKey] is the GlobalKey of the RepaintBoundary wrapping the canvas.
  /// [pixelRatio] controls output resolution (2.0 → ~1024px on most devices).
  Future<String?> captureAsBase64(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Capture at specified pixel ratio
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      // Add white background (AI models work better with opaque backgrounds)
      final whiteBackground = await _addWhiteBackground(image);

      // Resize if too large (max 1568px — Claude's optimal limit)
      final resized = await _resizeIfNeeded(whiteBackground, maxDimension: 1568);

      // Encode to PNG bytes
      final byteData = await resized.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('CanvasCaptureService error: $e');
      return null;
    }
  }

  /// Adds a white background behind the captured image.
  /// AI models perform significantly better with dark strokes on white.
  Future<ui.Image> _addWhiteBackground(ui.Image original) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = Size(
      original.width.toDouble(),
      original.height.toDouble(),
    );

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Original image on top
    canvas.drawImage(original, Offset.zero, Paint());

    final picture = recorder.endRecording();
    return picture.toImage(original.width, original.height);
  }

  /// Resize image if any dimension exceeds [maxDimension].
  Future<ui.Image> _resizeIfNeeded(
    ui.Image image, {
    required int maxDimension,
  }) async {
    final maxSide = image.width > image.height ? image.width : image.height;
    if (maxSide <= maxDimension) return image;

    final scale = maxDimension / maxSide;
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    return picture.toImage(newWidth, newHeight);
  }
}
```

---

### BÖLÜM B: Riverpod Providers

**2) OLUŞTUR: `example_app/lib/features/ai/presentation/providers/ai_providers.dart`**

Bu dosya tüm AI-related provider'ları barrel export eder ve temel DI provider'ları tanımlar.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

export 'ai_chat_provider.dart';
export 'ai_usage_provider.dart';

// ─── Service Providers ──────────────────────────────────

final canvasCaptureServiceProvider = Provider<CanvasCaptureService>((ref) {
  return CanvasCaptureService();
});

final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  final supabase = Supabase.instance.client;
  return AIRemoteDataSource(supabase);
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final remote = ref.watch(aiRemoteDataSourceProvider);
  // TODO: Gerçek subscription tier'ı subscription provider'dan al
  // Şimdilik free tier — Step 6'da premium entegrasyonu yapılacak
  const tier = SubscriptionTier.free;
  return AIRepositoryImpl(
    remoteDataSource: remote,
    userTier: tier,
  );
});
```

**3) OLUŞTUR: `example_app/lib/features/ai/presentation/providers/ai_chat_provider.dart`**

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/ai/data/services/canvas_capture_service.dart';
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
    if (existingConversationId != null) {
      state = state.copyWith(
        isLoading: true,
        conversationId: existingConversationId,
      );
      try {
        final messages = await _repository.getMessages(existingConversationId);
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
          // Create assistant message from completed stream
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
      return 'Günlük mesaj limitine ulaştınız. Yarın tekrar deneyin veya Premium\'a yükseltin.';
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
final aiChatProvider =
    StateNotifierProvider.autoDispose<AIChatNotifier, AIChatState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  final captureService = ref.watch(canvasCaptureServiceProvider);
  return AIChatNotifier(
    repository: repository,
    captureService: captureService,
  );
});
```

**4) OLUŞTUR: `example_app/lib/features/ai/presentation/providers/ai_usage_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Provider for AI usage statistics (daily message count, quota).
final aiUsageProvider = FutureProvider.autoDispose<AIUsage>((ref) async {
  final repository = ref.watch(aiRepositoryProvider);
  return repository.getUsage();
});

/// Quick check: can the user send another AI message?
final canSendAIMessageProvider = Provider.autoDispose<bool>((ref) {
  final usage = ref.watch(aiUsageProvider);
  return usage.when(
    data: (data) => !data.isOverDailyLimit,
    loading: () => true, // Optimistic — allow while loading
    error: (_, __) => false,
  );
});

/// Remaining daily messages (for UI display).
final remainingAIMessagesProvider = Provider.autoDispose<int>((ref) {
  final usage = ref.watch(aiUsageProvider);
  return usage.when(
    data: (data) => data.remainingDaily,
    loading: () => -1,
    error: (_, __) => 0,
  );
});
```

---

### BÖLÜM C: AI Chat UI Widgets

**Önce dependency ekle (pubspec.yaml):**
```bash
cd example_app
flutter pub add flutter_markdown
flutter pub add flutter_math_fork
```

**5) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_chat_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// A single chat message bubble (user or assistant).
class AIChatBubble extends StatelessWidget {
  const AIChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  final AIMessage message;
  final bool isStreaming;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isUser) _buildAvatar(theme),
          if (!_isUser) const SizedBox(width: 8),
          Flexible(child: _buildBubble(theme, isDark)),
          if (_isUser) const SizedBox(width: 8),
          if (_isUser) _buildAvatar(theme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _isUser
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.secondary.withValues(alpha: 0.1),
      child: Icon(
        _isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: _isUser
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildBubble(ThemeData theme, bool isDark) {
    final bgColor = _isUser
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.1)
        : isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(_isUser ? 16 : 4),
          bottomRight: Radius.circular(_isUser ? 4 : 16),
        ),
      ),
      child: _isUser ? _buildUserContent(theme) : _buildAssistantContent(theme),
    );
  }

  Widget _buildUserContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.hasImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Canvas ekran görüntüsü',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Text(
          message.content,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAssistantContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.content,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyMedium,
            code: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (isStreaming) _buildTypingCursor(theme),
      ],
    );
  }

  Widget _buildTypingCursor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: 8,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
```

**6) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_input_bar.dart`**

```dart
import 'package:flutter/material.dart';

/// Input bar for AI chat — text field + canvas attach + send button.
class AIInputBar extends StatefulWidget {
  const AIInputBar({
    super.key,
    required this.onSend,
    this.onAttachCanvas,
    this.isStreaming = false,
    this.enabled = true,
    this.remainingMessages,
    this.modelName,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onAttachCanvas;
  final bool isStreaming;
  final bool enabled;
  final int? remainingMessages;
  final String? modelName;

  @override
  State<AIInputBar> createState() => _AIInputBarState();
}

class _AIInputBarState extends State<AIInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled || widget.isStreaming) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Usage indicator
            if (widget.remainingMessages != null || widget.modelName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (widget.modelName != null)
                      Text(
                        widget.modelName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    if (widget.remainingMessages != null)
                      Text(
                        '${widget.remainingMessages} mesaj kaldı',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.remainingMessages! <= 3
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            // Input row
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Canvas attach button
                  if (widget.onAttachCanvas != null)
                    IconButton(
                      onPressed: widget.enabled && !widget.isStreaming
                          ? widget.onAttachCanvas
                          : null,
                      icon: const Icon(Icons.center_focus_strong),
                      tooltip: 'Canvas ekran görüntüsü gönder',
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled && !widget.isStreaming,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: widget.isStreaming
                            ? 'Yanıt alınıyor...'
                            : 'Mesajınızı yazın...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Send button
                  IconButton.filled(
                    onPressed: _hasText && widget.enabled && !widget.isStreaming
                        ? _handleSend
                        : null,
                    icon: widget.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    tooltip: 'Gönder',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**7) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_streaming_bubble.dart`**

Streaming sırasında aktif olarak güncellenen bubble. Ayrı widget çünkü her chunk'ta sadece bu rebuild oluyor.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Displays the currently streaming AI response with a typing cursor.
class AIStreamingBubble extends StatelessWidget {
  const AIStreamingBubble({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                theme.colorScheme.secondary.withValues(alpha: 0.1),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: content.isEmpty
                  ? _buildLoadingDots(theme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: content,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildCursor(theme),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Düşünüyor',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(width: 4),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCursor(ThemeData theme) {
    return SizedBox(
      width: 8,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
```

**8) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_widgets.dart`** (barrel)

```dart
/// AI presentation widgets barrel export.
library;

export 'ai_chat_bubble.dart';
export 'ai_input_bar.dart';
export 'ai_streaming_bubble.dart';
```

---

### BÖLÜM D: AI Chat Modal

**9) OLUŞTUR: `example_app/lib/features/ai/presentation/screens/ai_chat_modal.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/drawing_ui.dart' show canvasBoundaryKeyProvider;

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_widgets.dart';

/// Full-screen AI chat modal.
///
/// Opened when the user taps the AI button in the toolbar.
/// Supports text chat and canvas screenshot analysis.
class AIChatModal extends ConsumerStatefulWidget {
  const AIChatModal({super.key});

  /// Show the AI chat modal as a full-screen modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIChatModal(),
    );
  }

  @override
  ConsumerState<AIChatModal> createState() => _AIChatModalState();
}

class _AIChatModalState extends ConsumerState<AIChatModal> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSend(String text) {
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleCanvasCapture() {
    final canvasKey = ref.read(canvasBoundaryKeyProvider);
    ref.read(aiChatProvider.notifier).sendWithCanvas(
      'Bu çizimi analiz et ve açıkla.',
      canvasBoundaryKey: canvasKey,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final remaining = ref.watch(remainingAIMessagesProvider);
    final theme = Theme.of(context);

    // Auto-scroll when streaming
    ref.listen(aiChatProvider, (prev, next) {
      if (next.isStreaming || next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(theme),
          const Divider(height: 1),

          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(chatState, theme),
          ),

          // Error banner
          if (chatState.error != null) _buildErrorBanner(chatState.error!, theme),

          // Input bar
          AIInputBar(
            onSend: _handleSend,
            onAttachCanvas: _handleCanvasCapture,
            isStreaming: chatState.isStreaming,
            enabled: remaining != 0,
            remainingMessages: remaining >= 0 ? remaining : null,
            modelName: 'Gemini Flash', // TODO: dinamik model ismi
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Kapat',
          ),
          const SizedBox(width: 4),
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'StarNote AI',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ref.read(aiChatProvider.notifier).newConversation();
            },
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Yeni sohbet',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AIChatState chatState, ThemeData theme) {
    if (chatState.messages.isEmpty && !chatState.isStreaming) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatState.messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        // Streaming bubble at the end
        if (index == chatState.messages.length && chatState.isStreaming) {
          return AIStreamingBubble(content: chatState.streamingContent);
        }
        // Regular message bubble
        return AIChatBubble(message: chatState.messages[index]);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'StarNote AI',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sorularınızı sorun, notlarınızı özetleyin\nveya canvas\'ı AI ile analiz edin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Quick actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickAction(
                  theme,
                  icon: Icons.calculate,
                  label: 'Denklemi çöz',
                  onTap: () => _handleSend('Bu denklemi adım adım çöz'),
                ),
                _buildQuickAction(
                  theme,
                  icon: Icons.summarize,
                  label: 'Notları özetle',
                  onTap: () => _handleSend('Bu notları özetle'),
                ),
                _buildQuickAction(
                  theme,
                  icon: Icons.center_focus_strong,
                  label: 'Canvas\'ı analiz et',
                  onTap: _handleCanvasCapture,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildErrorBanner(String error, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref.read(aiChatProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
```

---

### BÖLÜM E: DrawingScreen Entegrasyonu

**10) GÜNCELLE: DrawingScreen'de onAIPressed callback'ini AIChatModal.show ile bağla**

Drawing screen'de `onAIPressed` callback'i zaten toolbar'a geçiriliyor. Bunu AI chat modal'a bağlamak lazım.

`example_app/lib/` içinde DrawingScreen'i kullanan sayfa dosyasını bul (muhtemelen `document_drawing_page.dart` veya benzeri). `onAIPressed` parametresine şu callback'i ver:

```dart
onAIPressed: () => AIChatModal.show(context),
```

Import ekle:
```dart
import 'package:example_app/features/ai/presentation/screens/ai_chat_modal.dart';
```

NOT: Eğer `onAIPressed` DrawingScreen constructor'ında yoksa ve doğrudan toolbar'da tanımlıysa, `drawing_screen.dart` veya toolbar'ın bağlandığı yeri bul. Mevcut kodda `AdaptiveToolbar` → `onAIPressed` callback olarak geçiriliyor. Bu callback'i DrawingScreen üzerinden alıp dışarıya expose et, sonra example_app'ten bağla.

---

### BÖLÜM F: Doğrulama

**11) Build & Analyze:**
```bash
cd example_app
flutter pub get
flutter analyze
```

**12) Dosya yapısını doğrula:**
```
example_app/lib/features/ai/
├── data/
│   ├── datasources/
│   │   ├── ai_remote_datasource.dart    (Step 1'den)
│   │   └── ai_exceptions.dart           (Step 1'den)
│   ├── repositories/
│   │   └── ai_repository_impl.dart      (Step 1'den)
│   └── services/
│       └── canvas_capture_service.dart   ← YENİ
├── domain/
│   ├── entities/
│   │   ├── ai_conversation.dart         (Step 1'den)
│   │   ├── ai_entities.dart             (Step 1'den)
│   │   ├── ai_message.dart              (Step 1'den)
│   │   ├── ai_model_config.dart         (Step 1'den)
│   │   └── ai_usage.dart               (Step 1'den)
│   └── repositories/
│       └── ai_repository.dart           (Step 1'den)
└── presentation/
    ├── providers/
    │   ├── ai_providers.dart            ← YENİ (barrel + DI)
    │   ├── ai_chat_provider.dart        ← YENİ
    │   └── ai_usage_provider.dart       ← YENİ
    ├── screens/
    │   └── ai_chat_modal.dart           ← YENİ
    └── widgets/
        ├── ai_chat_bubble.dart          ← YENİ
        ├── ai_input_bar.dart            ← YENİ
        ├── ai_streaming_bubble.dart     ← YENİ
        └── ai_widgets.dart              ← YENİ (barrel)
```

---

## KURALLAR
- Her dosya max 300 satır
- drawing_ui'ya DOKUNMA — tüm AI UI example_app'te
- `canvasBoundaryKeyProvider` import'u `drawing_ui/drawing_ui.dart`'dan
- Mevcut tema/renk sistemini kullan, hardcoded renk yasak
- `withOpacity()` yerine `withValues(alpha:)` kullan (Flutter 3.27+)
- Widget'lar responsive olmalı — maxWidth: 600 constraint ile geniş ekranda ortalı

## TEST KRİTERLERİ
- [ ] `flutter analyze` temiz
- [ ] AI butonu tıklanınca modal açılıyor
- [ ] Mesaj yazıp gönderilebiliyor
- [ ] Streaming yanıt token-by-token görünüyor
- [ ] Canvas screenshot gönderme çalışıyor
- [ ] Hata durumunda banner gösteriliyor
- [ ] Rate limit aşılınca uyarı gösteriliyor
- [ ] Dark mode'da doğru renkler
- [ ] Empty state quick actions çalışıyor
- [ ] Yeni sohbet butonu çalışıyor
- [ ] Tablet ve telefonda responsive

## COMMIT
```
feat(ai): add AI chat UI — modal, streaming, canvas capture

- Add CanvasCaptureService (RepaintBoundary → base64 PNG)
- Add Riverpod providers: aiChatProvider, aiUsageProvider
- Add AIChatModal with full-screen bottom sheet
- Add AIChatBubble, AIStreamingBubble, AIInputBar widgets
- Markdown rendering for AI responses
- Canvas screenshot attach functionality
- Usage quota display in input bar
- Dark mode support
- Empty state with quick action chips
```

## SONRAKİ ADIM
Step 3: Drift local storage + conversation history + cloud sync

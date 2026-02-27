import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/drawing_ui.dart' show canvasBoundaryKeyProvider;

import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_widgets.dart';

/// Reusable AI chat content used by both the modal and sidebar.
///
/// Contains the header, usage bar, message list, input bar, error banner,
/// empty state, and quick actions.
class AIChatContent extends ConsumerStatefulWidget {
  const AIChatContent({super.key, required this.onClose});

  /// Called when the user taps the close button.
  final VoidCallback onClose;

  @override
  ConsumerState<AIChatContent> createState() => _AIChatContentState();
}

class _AIChatContentState extends ConsumerState<AIChatContent> {
  final _scrollController = ScrollController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeIfNeeded();
    });
  }

  void _initializeIfNeeded() {
    final state = ref.read(aiChatProvider);
    // Only initialize if there's no active conversation
    if (state.conversationId == null && !state.isLoading) {
      ref.read(aiChatProvider.notifier).initialize();
    }
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
    if (!ref.read(canSendAIMessageProvider)) {
      AIUpgradePrompt.show(context,
          reason: AIUpgradeReason.dailyLimitReached,
          onUpgrade: widget.onClose);
      return;
    }
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleCanvasCapture() {
    if (!ref.read(canSendAIMessageProvider)) {
      AIUpgradePrompt.show(context,
          reason: AIUpgradeReason.dailyLimitReached,
          onUpgrade: widget.onClose);
      return;
    }
    final canvasKey = ref.read(canvasBoundaryKeyProvider);
    ref.read(aiChatProvider.notifier).sendWithCanvas(
      'Bu çizimi analiz et ve açıkla.',
      canvasBoundaryKey: canvasKey,
    );
    _scrollToBottom();
  }

  void _handleConversationSelected(String id) {
    ref.read(aiChatProvider.notifier)
        .initialize(existingConversationId: id);
    if (MediaQuery.of(context).size.width < 600) {
      setState(() => _showHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final remaining = ref.watch(remainingAIMessagesProvider);
    final theme = Theme.of(context);

    // Auto-scroll when streaming + refresh usage when done
    ref.listen(aiChatProvider, (prev, next) {
      if (prev?.isStreaming == true && !next.isStreaming) {
        ref.invalidate(aiUsageProvider);
      }
      if (next.isStreaming ||
          next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          _buildHeader(theme),
          const AIUsageBar(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                if (_showHistory)
                  AIConversationList(
                    currentConversationId: chatState.conversationId,
                    onConversationSelected: _handleConversationSelected,
                  ),
                Expanded(child: _buildChatArea(chatState, theme)),
              ],
            ),
          ),
          if (chatState.error != null)
            _buildErrorBanner(chatState.error!, theme),
          AIInputBar(
            onSend: _handleSend,
            onAttachCanvas: _handleCanvasCapture,
            isStreaming: chatState.isStreaming,
            enabled: ref.watch(canSendAIMessageProvider),
            remainingMessages: remaining >= 0 ? remaining : null,
            modelName: ref.watch(aiModelNameProvider),
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
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Kapat',
          ),
          const SizedBox(width: 4),
          Icon(Icons.auto_awesome,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'StarNote AI',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () =>
                setState(() => _showHistory = !_showHistory),
            icon: const Icon(Icons.history),
            tooltip: 'Sohbet geçmişi',
          ),
          IconButton(
            onPressed: () {
              ref.read(aiChatProvider.notifier).newConversation();
              refreshConversations(ref);
            },
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Yeni sohbet',
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(AIChatState chatState, ThemeData theme) {
    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildMessageList(chatState);
  }

  Widget _buildMessageList(AIChatState chatState) {
    if (chatState.messages.isEmpty && !chatState.isStreaming) {
      return _buildEmptyState(Theme.of(context));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount:
          chatState.messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length &&
            chatState.isStreaming) {
          return AIStreamingBubble(
              content: chatState.streamingContent);
        }
        return AIChatBubble(message: chatState.messages[index]);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('StarNote AI', style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Sorularınızı sorun, notlarınızı özetleyin\n'
            "veya canvas'ı AI ile analiz edin.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _quickAction(theme, Icons.calculate, 'Denklemi çöz',
                  () => _handleSend('Bu denklemi adım adım çöz')),
              _quickAction(theme, Icons.summarize, 'Notları özetle',
                  () => _handleSend('Bu notları özetle')),
              _quickAction(theme, Icons.center_focus_strong,
                  "Canvas'ı analiz et", _handleCanvasCapture),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _quickAction(
      ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16), label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildErrorBanner(String error, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 16, color: theme.colorScheme.error),
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
            onPressed: () =>
                ref.read(aiChatProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

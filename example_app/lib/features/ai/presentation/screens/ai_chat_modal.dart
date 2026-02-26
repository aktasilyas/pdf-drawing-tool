import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/drawing_ui.dart' show canvasBoundaryKeyProvider;

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
      if (next.isStreaming ||
          next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _buildHeader(theme),
            const Divider(height: 1),
            Expanded(
              child: chatState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessageList(chatState),
            ),
          if (chatState.error != null)
            _buildErrorBanner(chatState.error!, theme),
            AIInputBar(
              onSend: _handleSend,
              onAttachCanvas: _handleCanvasCapture,
              isStreaming: chatState.isStreaming,
              enabled: remaining != 0,
              remainingMessages: remaining >= 0 ? remaining : null,
              modelName: 'Gemini Flash',
            ),
          ],
        ),
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
        if (index == chatState.messages.length && chatState.isStreaming) {
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
              'Sorularınızı sorun, notlarınızı özetleyin\n'
              "veya canvas'ı AI ile analiz edin.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickAction(
                  theme,
                  icon: Icons.calculate,
                  label: 'Denklemi çöz',
                  onTap: () =>
                      _handleSend('Bu denklemi adım adım çöz'),
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
                  label: "Canvas'ı analiz et",
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart' show canvasBoundaryKeyProvider;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_widgets.dart';

/// Main AI chat content — header, messages, input bar.
class AIChatContent extends ConsumerStatefulWidget {
  const AIChatContent({super.key, required this.onClose});
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
    final s = ref.read(aiChatProvider);
    if (s.conversationId == null && !s.isLoading) {
      ref.read(aiChatProvider.notifier).initialize();    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          reason: AIUpgradeReason.dailyLimitReached);
      return;
    }
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }
  void _handleCanvasCapture() {
    if (!ref.read(canSendAIMessageProvider)) {
      AIUpgradePrompt.show(context,
          reason: AIUpgradeReason.dailyLimitReached);
      return;
    }
    final canvasKey = ref.read(canvasBoundaryKeyProvider);
    ref.read(aiChatProvider.notifier).sendWithCanvas(
      'Bu cizimi analiz et ve acikla.',
      canvasBoundaryKey: canvasKey,
    );
    _scrollToBottom();
  }
  void _handleConversationSelected(String id) {
    ref.read(aiChatProvider.notifier)
        .initialize(existingConversationId: id);
    setState(() => _showHistory = false);
  }
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final theme = Theme.of(context);
    ref.listen(aiChatProvider, (prev, next) {
      if (prev?.isStreaming == true && !next.isStreaming) {
        ref.invalidate(aiUsageProvider);
        refreshConversations(ref);
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
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final historyPanel = AIConversationList(
                  currentConversationId: chatState.conversationId,
                  onConversationSelected: _handleConversationSelected,
                );
                if (isWide && _showHistory) {
                  return Row(children: [
                    SizedBox(
                        width: AppSpacing.sidebarWidth,
                        child: historyPanel),
                    Expanded(child: _buildChatArea(chatState, theme)),
                  ]);
                }
                if (_showHistory) return historyPanel;
                return _buildChatArea(chatState, theme);
              },
            ),
          ),
          if (chatState.error != null)
            _buildErrorBanner(chatState.error!, theme),
          AIInputBar(
            onSend: _handleSend,
            onAttachCanvas: _handleCanvasCapture,
            isStreaming: chatState.isStreaming,
            enabled: ref.watch(canSendAIMessageProvider),
            onLimitReached: () => AIUpgradePrompt.show(
              context,
              reason: AIUpgradeReason.dailyLimitReached,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(ThemeData theme) {
    final viewMode = ref.watch(aiChatViewModeProvider);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: AppIconSize.md),
            tooltip: 'Menu',
            onSelected: (value) {
              switch (value) {
                case 'sidebar':
                  ref.read(aiChatViewModeProvider.notifier).state =
                      AIChatViewMode.sidebar;
                case 'floating':
                  ref.read(aiChatViewModeProvider.notifier).state =
                      AIChatViewMode.floating;
                case 'close':
                  widget.onClose();
              }
            },
            itemBuilder: (context) => [
              _viewModeItem(
                value: 'sidebar', icon: Icons.view_sidebar,
                label: 'Sidebar gorunumu',
                isActive: viewMode == AIChatViewMode.sidebar,
              ),
              _viewModeItem(
                value: 'floating', icon: Icons.picture_in_picture,
                label: 'Yuzen pencere',
                isActive: viewMode == AIChatViewMode.floating,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'close',
                child: Row(children: [
                  Icon(Icons.close, size: AppIconSize.md),
                  SizedBox(width: AppSpacing.md),
                  const Text('Kapat'),
                ]),
              ),
            ],
          ),
          SizedBox(width: AppSpacing.xs),
          Text('StarNote AI',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: () =>
                setState(() => _showHistory = !_showHistory),
            icon: Icon(Icons.history, size: AppIconSize.md),
            tooltip: 'Sohbet gecmisi',
          ),
          TextButton.icon(
            onPressed: () {
              ref.read(aiChatProvider.notifier).newConversation();
              refreshConversations(ref);
            },
            icon: Icon(Icons.add_comment_outlined, size: AppIconSize.sm),
            label: const Text('Yeni Chat'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
  PopupMenuItem<String> _viewModeItem({
    required String value, required IconData icon,
    required String label, required bool isActive,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: AppIconSize.md),
        SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label)),
        if (isActive)
          Icon(Icons.check, size: AppIconSize.sm + 2,
              color: Theme.of(context).colorScheme.primary),
      ]),
    );
  }
  Widget _buildChatArea(AIChatState chatState, ThemeData theme) {
    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chatState.messages.isEmpty && !chatState.isStreaming) {
      return _buildEmptyState(theme);
    }
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount:
          chatState.messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isStreaming) {
          return AIStreamingBubble(content: chatState.streamingContent);
        }
        return AIChatBubble(message: chatState.messages[index]);
      },
    );
  }
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: AppIconSize.emptyState,
              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          SizedBox(height: AppSpacing.lg),
          Text('StarNote AI', style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Sorularinizi sorun, notlarinizi ozetleyin\n'
            "veya canvas'i AI ile analiz edin.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
  Widget _buildErrorBanner(String error, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.sm,
      ),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: AppIconSize.sm, color: theme.colorScheme.error),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(error, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            )),
          ),
          IconButton(
            icon: Icon(Icons.close, size: AppIconSize.sm),
            onPressed: () =>
                ref.read(aiChatProvider.notifier).clearError(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

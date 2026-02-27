import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            : theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5);

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
      child:
          _isUser ? _buildUserContent(theme) : _buildAssistantContent(theme),
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
                  Icon(Icons.image,
                      size: 14, color: theme.colorScheme.primary),
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
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (isStreaming) _buildTypingCursor(theme),
        if (!isStreaming && message.content.isNotEmpty)
          _buildCopyButton(theme),
      ],
    );
  }

  Widget _buildCopyButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _CopyButton(content: message.content),
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

/// Copy button with "copied" feedback.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.content});
  final String content;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return InkWell(
      onTap: _copied ? null : _handleCopy,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy,
              size: 14,
              color: _copied ? theme.colorScheme.primary : color,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Kopyalandi' : 'Kopyala',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _copied ? theme.colorScheme.primary : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

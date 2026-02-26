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
            color:
                theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Usage indicator
            if (widget.remainingMessages != null ||
                widget.modelName != null)
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
                        fillColor: theme
                            .colorScheme.surfaceContainerHighest
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
                    onPressed:
                        _hasText && widget.enabled && !widget.isStreaming
                            ? _handleSend
                            : null,
                    icon: widget.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
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

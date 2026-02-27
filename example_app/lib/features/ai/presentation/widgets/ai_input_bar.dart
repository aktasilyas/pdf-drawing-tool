import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Input bar for AI chat — attach menu + text field + send button.
class AIInputBar extends StatefulWidget {
  const AIInputBar({
    super.key,
    required this.onSend,
    this.onAttachCanvas,
    this.onLimitReached,
    this.isStreaming = false,
    this.enabled = true,
    this.pendingImage,
    this.onClearPendingImage,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onAttachCanvas;
  final VoidCallback? onLimitReached;
  final bool isStreaming;
  final bool enabled;
  final Uint8List? pendingImage;
  final VoidCallback? onClearPendingImage;

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

  bool get _canSend =>
      !widget.isStreaming &&
      widget.enabled &&
      (_hasText || widget.pendingImage != null);

  void _handleSend() {
    final text = _controller.text.trim();
    if (!_canSend) return;
    // Allow sending with just an image (text may be empty)
    widget.onSend(text);
    _controller.clear();
  }

  Widget _buildQuickChips(ThemeData theme) {
    final isEnabled = widget.enabled && !widget.isStreaming;
    void sendQuick(String t) { if (isEnabled) widget.onSend(t); }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          _chip(theme, 'Bunu coz', Icons.lightbulb_outline,
              isEnabled, () => sendQuick('Bunu coz')),
          _chip(theme, 'Bana anlat', Icons.chat_bubble_outline,
              isEnabled, () => sendQuick('Bana anlat')),
          _chip(theme, 'Ozetle', Icons.short_text,
              isEnabled, () => sendQuick('Ozetle')),
        ],
      ),
    );
  }

  Widget _chip(
    ThemeData theme,
    String label,
    IconData icon,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: AppIconSize.sm),
      label: Text(label, style: theme.textTheme.labelMedium),
      onPressed: isEnabled ? onTap : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      backgroundColor: Colors.transparent,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPendingImagePreview(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.memory(widget.pendingImage!,
              width: 56, height: 56, fit: BoxFit.cover),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Secim ekran goruntusu',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        IconButton(
          onPressed: widget.onClearPendingImage,
          icon: Icon(Icons.close, size: AppIconSize.sm),
          tooltip: 'Kaldir',
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }

  Widget _buildAttachButton(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add_circle_outline, size: AppIconSize.lg),
      tooltip: 'Ekle',
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
      enabled: !widget.isStreaming,
      onSelected: (value) {
        switch (value) {
          case 'canvas':
            widget.onAttachCanvas?.call();
          case 'image':
            // TODO: Image upload
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'canvas',
          child: Row(children: [
            Icon(Icons.center_focus_strong, size: AppIconSize.md),
            SizedBox(width: AppSpacing.md),
            const Text('Canvas ekran goruntusu'),
          ]),
        ),
        PopupMenuItem(
          value: 'image',
          child: Row(children: [
            Icon(Icons.image_outlined, size: AppIconSize.md),
            SizedBox(width: AppSpacing.md),
            const Text('Resim yukle'),
          ]),
        ),
      ],
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildAttachButton(theme),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.isStreaming,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: widget.isStreaming
                  ? 'Yanit aliniyor...'
                  : 'Mesajinizi yazin...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        IconButton.filled(
          onPressed: _canSend ? _handleSend : null,
          icon: widget.isStreaming
              ? SizedBox(
                  width: AppIconSize.sm + 2,
                  height: AppIconSize.sm + 2,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          tooltip: 'Gonder',
        ),
      ],
    );
  }

  Widget _buildUpgradeBanner(ThemeData theme) {
    return InkWell(
      onTap: widget.onLimitReached,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                size: AppIconSize.sm + 2, color: theme.colorScheme.error),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Gunluk limit doldu — Premium ile devam et',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: AppIconSize.xs + 2, color: theme.colorScheme.error),
          ],
        ),
      ),
    );
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
            if (widget.enabled) _buildQuickChips(theme),
            if (widget.pendingImage != null)
              _buildPendingImagePreview(theme),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: widget.enabled
                  ? _buildInputRow(theme)
                  : _buildUpgradeBanner(theme),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Yapay zeka hata yapabilir.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

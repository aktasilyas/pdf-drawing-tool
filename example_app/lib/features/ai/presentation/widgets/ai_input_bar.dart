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
          child: Text('Seçim ekran görüntüsü',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        IconButton(
          onPressed: widget.onClearPendingImage,
          icon: Icon(Icons.close, size: AppIconSize.sm),
          tooltip: 'Kaldır',
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
            const Text('Canvas ekran görüntüsü'),
          ]),
        ),
        PopupMenuItem(
          value: 'image',
          child: Row(children: [
            Icon(Icons.image_outlined, size: AppIconSize.md),
            SizedBox(width: AppSpacing.md),
            const Text('Resim yükle'),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.isStreaming
                  ? 'Yanıt alınıyor...'
                  : 'Mesajınızı yazın...',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _canSend
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: IconButton(
              onPressed: _canSend ? _handleSend : null,
              padding: EdgeInsets.zero,
              iconSize: AppIconSize.sm + 2,
              icon: widget.isStreaming
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      color: _canSend
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                    ),
              tooltip: 'Gönder',
            ),
          ),
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
                'Günlük limit doldu — Premium ile devam et',
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
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

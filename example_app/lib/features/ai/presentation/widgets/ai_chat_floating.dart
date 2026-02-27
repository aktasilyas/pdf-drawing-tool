import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/ai/presentation/providers/ai_sidebar_provider.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_content.dart';

/// Draggable and resizable floating AI chat window.
///
/// Positioned as an overlay on top of the canvas. The user can drag
/// the header to reposition and drag the bottom-right corner to resize.
class AIFloatingChat extends ConsumerStatefulWidget {
  const AIFloatingChat({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<AIFloatingChat> createState() => _AIFloatingChatState();
}

class _AIFloatingChatState extends ConsumerState<AIFloatingChat> {
  Offset? _offset;
  Size _size = const Size(
    kAIFloatingDefaultWidth,
    kAIFloatingDefaultHeight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _offset ??= _defaultOffset();
  }

  Offset _defaultOffset() {
    final screen = MediaQuery.of(context).size;
    return Offset(
      screen.width - kAIFloatingDefaultWidth - AppSpacing.lg,
      screen.height - kAIFloatingDefaultHeight - AppSpacing.lg,
    );
  }

  void _clampOffset() {
    final screen = MediaQuery.of(context).size;
    final dx = _offset!.dx.clamp(0.0, screen.width - _size.width);
    final dy = _offset!.dy.clamp(0.0, screen.height - _size.height);
    _offset = Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: _offset!.dx,
      top: _offset!.dy,
      width: _size.width,
      height: _size.height,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset = _offset! + details.delta;
            _clampOffset();
          });
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Stack(
              children: [
                AIChatContent(onClose: widget.onClose),
                _buildResizeHandle(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle(ThemeData theme) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _size = Size(
              (_size.width + details.delta.dx)
                  .clamp(kAIFloatingMinWidth, double.infinity),
              (_size.height + details.delta.dy)
                  .clamp(kAIFloatingMinHeight, double.infinity),
            );
            _clampOffset();
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  Icons.open_in_full,
                  size: AppIconSize.xs + 2,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Header bar for AI chat — menu, title, history toggle, new chat button.
class AIChatHeader extends ConsumerWidget {
  const AIChatHeader({
    super.key,
    required this.onClose,
    required this.onToggleHistory,
    required this.onNewChat,
  });

  final VoidCallback onClose;
  final VoidCallback onToggleHistory;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(aiChatViewModeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        return Row(
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
                    onClose();
                }
              },
              itemBuilder: (context) => [
                _viewModeItem(
                  context,
                  value: 'sidebar', icon: Icons.view_sidebar,
                  label: 'Sidebar gorunumu',
                  isActive: viewMode == AIChatViewMode.sidebar,
                ),
                _viewModeItem(
                  context,
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
            Flexible(
              child: Text('ElyaNotes AI',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            IconButton(
              onPressed: onToggleHistory,
              icon: Icon(Icons.history, size: AppIconSize.md),
              tooltip: 'Sohbet gecmisi',
            ),
            if (isCompact)
              IconButton(
                onPressed: onNewChat,
                icon: Icon(Icons.add_comment_outlined,
                    size: AppIconSize.md),
                tooltip: 'Yeni Chat',
              )
            else
              TextButton.icon(
                onPressed: onNewChat,
                icon: Icon(Icons.add_comment_outlined,
                    size: AppIconSize.sm),
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
        );
      }),
    );
  }

  PopupMenuItem<String> _viewModeItem(
    BuildContext context, {
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
}

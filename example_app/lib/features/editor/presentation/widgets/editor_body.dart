import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/ai/presentation/providers/ai_sidebar_provider.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_floating.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_sidebar.dart';
import 'package:example_app/features/editor/presentation/widgets/save_failure_banner.dart';

/// Editor body that passes the AI sidebar into [DrawingScreen]'s layout.
///
/// The sidebar renders below the toolbar (inside DrawingScreen's Expanded area),
/// not spanning the full height.
class EditorBody extends ConsumerWidget {
  const EditorBody({
    super.key,
    required this.documentTitle,
    required this.canvasMode,
    required this.onHomePressed,
    required this.onRenameDocument,
    required this.onDeleteDocument,
    required this.onDocumentChanged,
  });

  final String documentTitle;
  final CanvasMode canvasMode;
  final VoidCallback onHomePressed;
  final VoidCallback onRenameDocument;
  final VoidCallback onDeleteDocument;
  final ValueChanged<dynamic> onDocumentChanged;

  void _toggleAI(WidgetRef ref, bool isOpen) {
    ref.read(aiSidebarOpenProvider.notifier).state = !isOpen;
  }

  void _closeAI(WidgetRef ref) {
    ref.read(aiSidebarOpenProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiEnabled = ref.watch(featureFlagsProvider).aiChat;
    final isAIOpen = aiEnabled && ref.watch(aiSidebarOpenProvider);
    final viewMode = ref.watch(aiChatViewModeProvider);
    final isSidebar = aiEnabled && viewMode == AIChatViewMode.sidebar;

    final drawingScreen = DrawingScreen(
      documentTitle: documentTitle,
      canvasMode: canvasMode,
      onHomePressed: onHomePressed,
      onRenameDocument: onRenameDocument,
      onDeleteDocument: onDeleteDocument,
      onAIPressed: aiEnabled ? () => _toggleAI(ref, isAIOpen) : null,
      onDocumentChanged: onDocumentChanged,
      externalLeftSidebar:
          isSidebar ? AIChatSidebar(onClose: () => _closeAI(ref)) : null,
      isExternalLeftSidebarOpen: isSidebar && isAIOpen,
      externalLeftSidebarWidth: kAISidebarWidth,
      onExternalLeftSidebarClose: () => _closeAI(ref),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        drawingScreen,
        if (aiEnabled && !isSidebar && isAIOpen)
          AIFloatingChat(onClose: () => _closeAI(ref)),
        const Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: SafeArea(child: SaveFailureBanner()),
        ),
      ],
    );
  }
}

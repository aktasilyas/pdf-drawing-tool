import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/features/ai/presentation/providers/ai_sidebar_provider.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_floating.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_chat_sidebar.dart';

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
    final isAIOpen = ref.watch(aiSidebarOpenProvider);
    final viewMode = ref.watch(aiChatViewModeProvider);
    final isSidebar = viewMode == AIChatViewMode.sidebar;

    final drawingScreen = DrawingScreen(
      documentTitle: documentTitle,
      canvasMode: canvasMode,
      onHomePressed: onHomePressed,
      onRenameDocument: onRenameDocument,
      onDeleteDocument: onDeleteDocument,
      onAIPressed: () => _toggleAI(ref, isAIOpen),
      onDocumentChanged: onDocumentChanged,
      externalLeftSidebar: isSidebar
          ? AIChatSidebar(onClose: () => _closeAI(ref))
          : null,
      isExternalLeftSidebarOpen: isSidebar && isAIOpen,
      externalLeftSidebarWidth: kAISidebarWidth,
      onExternalLeftSidebarClose: () => _closeAI(ref),
    );

    if (!isSidebar && isAIOpen) {
      return Stack(
        children: [
          drawingScreen,
          AIFloatingChat(onClose: () => _closeAI(ref)),
        ],
      );
    }

    return drawingScreen;
  }
}

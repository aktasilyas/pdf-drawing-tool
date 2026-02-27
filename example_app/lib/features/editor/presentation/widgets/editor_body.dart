import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/features/ai/presentation/providers/ai_sidebar_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAISidebarOpen = ref.watch(aiSidebarOpenProvider);

    return DrawingScreen(
      documentTitle: documentTitle,
      canvasMode: canvasMode,
      onHomePressed: onHomePressed,
      onRenameDocument: onRenameDocument,
      onDeleteDocument: onDeleteDocument,
      onAIPressed: () {
        ref.read(aiSidebarOpenProvider.notifier).state = !isAISidebarOpen;
      },
      onDocumentChanged: onDocumentChanged,
      externalLeftSidebar: AIChatSidebar(
        onClose: () =>
            ref.read(aiSidebarOpenProvider.notifier).state = false,
      ),
      isExternalLeftSidebarOpen: isAISidebarOpen,
      externalLeftSidebarWidth: kAISidebarWidth,
      onExternalLeftSidebarClose: () =>
          ref.read(aiSidebarOpenProvider.notifier).state = false,
    );
  }
}

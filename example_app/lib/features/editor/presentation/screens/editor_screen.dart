import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/features/editor/presentation/providers/editor_paper_format.dart';
import 'package:example_app/features/editor/presentation/providers/editor_session.dart';
import 'package:example_app/features/editor/presentation/providers/pdf_relink_handler.dart';
import 'package:example_app/features/editor/presentation/widgets/active_editor_leave_scope.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_body.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_dialogs.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_leave_guard.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_load_error_view.dart';

class EditorScreen extends ConsumerWidget {
  final String documentId;

  const EditorScreen({super.key, required this.documentId});

  static const _loadingScaffold = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentLoaderProvider(documentId));

    return documentAsync.when(
      loading: () => _loadingScaffold,
      error: (error, stack) {
        logger.w('Editor load failed: $error');
        return EditorLoadErrorView(
          onRetry: () => ref.invalidate(documentLoaderProvider(documentId)),
          // No session was started yet, so there is nothing to clean up.
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/documents'),
        );
      },
      data: (document) {
        // Initialize document ONLY on first load (not on every rebuild)
        // Rebuilds happen on keyboard show/hide, MediaQuery changes, etc.
        // Re-initializing would overwrite in-memory changes (texts, strokes)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentDoc = ref.read(documentProvider);
          if (currentDoc.id == document.id) return; // Already loaded

          startEditorSession(ref.read, document);

          // Set page trash callback for soft-delete support
          ref.read(pageTrashCallbackProvider.notifier).state =
              pageTrashCallbackFor(ref.read, document.id);

          // Lets the editor drop a trash entry again (undo of a page delete).
          ref.read(pageTrashDiscardCallbackProvider.notifier).state =
              pageTrashDiscardCallbackFor(ref.read);

          // "Locate PDF…" on pages whose source PDF went missing (#449).
          ref.read(pdfSourceRelinkProvider.notifier).state =
              pdfRelinkHandlerFor(ref.read, context);

          // PDF export uses the notebook's paper size (#454). The root
          // container outlives this screen; `ref` must not be used after an
          // await, as the user may already have left.
          final root = ProviderScope.containerOf(context, listen: false);
          unawaited(loadExportPaperFormat(root.read, document.id));

          // Initialize canvas transform for limited mode (notebook/notepad)
          final canvasMode = document.canvasMode;
          if (!canvasMode.isInfinite) {
            final screenSize = MediaQuery.of(context).size;
            final currentPage = document.currentPage;
            if (currentPage != null) {
              final pageSize =
                  Size(currentPage.size.width, currentPage.size.height);

              ref.read(canvasTransformProvider.notifier).initializeForPage(
                    viewportSize: screenSize,
                    pageSize: pageSize,
                  );
            }
          }
        });

        // Listen to document changes for auto-save (NO INVALIDATE HERE!)
        ref.listen<DrawingDocument>(documentProvider, (previous, next) {
          if (previous != null) {
            onEditorDocumentChanged(ref.read, previous, next);
          }
        });

        // Do not build the canvas until the loaded document has been applied
        // to documentProvider (the session starts in the post-frame callback).
        final appliedId = ref.watch(documentProvider.select((d) => d.id));
        if (appliedId != document.id) return _loadingScaffold;

        // Get canvasMode from document (based on documentType)
        final canvasMode = document.canvasMode;

        return ActiveEditorLeaveScope(
          leave: () => _handleBack(context, ref),
          child: EditorLeaveGuard(
            onLeave: () => _handleBack(context, ref),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              // NO AppBar - DrawingScreen handles everything
              body: EditorBody(
                documentTitle:
                    ref.watch(documentProvider.select((d) => d.title)),
                canvasMode: canvasMode,
                onHomePressed: () => _handleBack(context, ref),
                onRenameDocument: () => _showRenameDialog(context, ref),
                onDeleteDocument: () => _showDeleteConfirmation(context, ref),
                onDocumentChanged: (doc) {
                  if (doc is DrawingDocument) {
                    ref.read(currentDocumentProvider.notifier).state = doc;
                    ref.read(autoSaveProvider.notifier).documentChanged(doc);
                    ref.read(hasUnsavedChangesProvider.notifier).state = true;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Saves and leaves the editor. Returns false when the save failed and the
  /// editor stayed open.
  Future<bool> _handleBack(BuildContext context, WidgetRef ref) async {
    // Write only pending or failed edits: a notebook that was only read
    // keeps its modified date (#467). Stay in the editor when the save
    // failed: leaving would drop the unsaved changes. The banner offers Retry.
    if (!await saveBeforeLeavingEditor(ref.read)) return false;

    // Navigate FIRST - this destroys EditorScreen and auto-disposes
    // documentLoaderProvider (which is autoDispose). We must NOT invalidate
    // documentLoaderProvider while the widget is still alive, because
    // Riverpod emits the stale cached value before the fresh fetch completes,
    // causing the guard to initialize with old data and block the fresh data.
    if (context.mounted) {
      context.go('/documents');
    }

    // Invalidate non-autoDispose providers AFTER navigation
    closeEditorSession(ref.read, ref.invalidate);
    if (ref.read(featureFlagsProvider).aiChat) {
      ref.invalidate(aiChatProvider);
      ref.invalidate(aiSidebarOpenProvider);
    }
    return true;
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => RenameDocumentDialog(
        initialTitle: ref.read(documentProvider).title,
      ),
    );
    if (title != null) {
      ref.read(documentProvider.notifier).updateTitle(title);
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const MoveToTrashDialog(),
    );
    if (confirmed != true) return;
    // Saves first; a failed save keeps the editor open with its Retry banner.
    if (!await moveOpenDocumentToTrash(ref.read, documentId)) return;
    if (context.mounted) context.go('/documents');
    closeEditorSession(ref.read, ref.invalidate);
    if (ref.read(featureFlagsProvider).aiChat) {
      ref.invalidate(aiChatProvider);
      ref.invalidate(aiSidebarOpenProvider);
    }
  }
}

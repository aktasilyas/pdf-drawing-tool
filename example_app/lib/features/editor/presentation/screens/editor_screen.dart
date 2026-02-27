import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_body.dart';

class EditorScreen extends ConsumerWidget {
  final String documentId;

  const EditorScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentLoaderProvider(documentId));

    return documentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Belge yüklenemedi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      ),
      data: (document) {
        // Initialize document ONLY on first load (not on every rebuild)
        // Rebuilds happen on keyboard show/hide, MediaQuery changes, etc.
        // Re-initializing would overwrite in-memory changes (texts, strokes)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentDoc = ref.read(documentProvider);
          if (currentDoc.id == document.id) return; // Already loaded

          ref.read(documentProvider.notifier).updateDocument(document);
          ref.read(currentDocumentProvider.notifier).state = document;
          ref.read(pageManagerProvider.notifier).initializeFromDocument(
            document.pages,
            currentIndex: document.currentPageIndex,
          );

          // Set page trash callback for soft-delete support
          ref.read(pageTrashCallbackProvider.notifier).state =
              (pageIndex, page) async {
            await ref
                .read(documentsControllerProvider.notifier)
                .movePageToTrash(
                  documentId: document.id,
                  documentTitle: document.title,
                  pageIndex: pageIndex,
                  pageData: page.toJson(),
                );
          };

          // Initialize canvas transform for limited mode (notebook/notepad)
          final canvasMode = document.canvasMode;
          if (!canvasMode.isInfinite) {
            final screenSize = MediaQuery.of(context).size;
            final currentPage = document.currentPage;
            if (currentPage != null) {
              final pageSize = Size(currentPage.size.width, currentPage.size.height);

              ref.read(canvasTransformProvider.notifier).initializeForPage(
                viewportSize: screenSize,
                pageSize: pageSize,
              );
            }
          }
        });

        // Listen to document changes for auto-save (NO INVALIDATE HERE!)
        ref.listen<DrawingDocument>(documentProvider, (previous, next) {
          // Only trigger save if document actually changed (same ID, different content)
          if (previous != null && previous != next && previous.id == next.id) {
            ref.read(currentDocumentProvider.notifier).state = next;
            ref.read(autoSaveProvider.notifier).documentChanged(next);
            ref.read(hasUnsavedChangesProvider.notifier).state = true;
          }
        });

        // Get canvasMode from document (based on documentType)
        final canvasMode = document.canvasMode;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          // NO AppBar - DrawingScreen handles everything
          body: EditorBody(
            documentTitle: document.title,
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
        );
      },
    );
  }

  Future<void> _handleBack(BuildContext context, WidgetRef ref) async {
    final currentDoc = ref.read(documentProvider);

    // Always save current state before leaving (cancels any pending timer)
    await ref.read(autoSaveProvider.notifier).saveNow(currentDoc);

    // Navigate FIRST - this destroys EditorScreen and auto-disposes
    // documentLoaderProvider (which is autoDispose). We must NOT invalidate
    // documentLoaderProvider while the widget is still alive, because
    // Riverpod emits the stale cached value before the fresh fetch completes,
    // causing the guard to initialize with old data and block the fresh data.
    if (context.mounted) {
      context.go('/documents');
    }

    // Invalidate non-autoDispose providers AFTER navigation
    ref.invalidate(documentProvider);
    ref.invalidate(pageManagerProvider);
    ref.invalidate(autoSaveProvider);
    ref.invalidate(hasUnsavedChangesProvider);
    ref.invalidate(pageTrashCallbackProvider);
    ref.invalidate(aiChatProvider);
    ref.invalidate(aiSidebarOpenProvider);

    // PDF state'lerini sıfırla
    ref.read(visiblePdfPageProvider.notifier).state = null;
    ref.read(currentPdfFilePathProvider.notifier).state = null;
    ref.read(totalPdfPagesProvider.notifier).state = 0;
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final document = ref.read(documentProvider);
    final controller = TextEditingController(text: document.title);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        title: Text('Yeniden Adlandır', style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Belge Adı',
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(documentProvider.notifier).updateTitle(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(documentProvider.notifier).updateTitle(newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        title: Text('Çöpe Taşı',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Bu belge çöpe taşınacak. Daha sonra geri yükleyebilirsiniz.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await ref
                  .read(documentsControllerProvider.notifier)
                  .moveToTrash(documentId);
              if (result && context.mounted) {
                context.go('/documents');
              }
            },
            child: const Text('Çöpe Taşı'),
          ),
        ],
      ),
    );
  }
}

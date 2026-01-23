import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart' hide PDFExportDialog;
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/features/editor/presentation/widgets/pdf_export_dialog.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String documentId;

  const EditorScreen({super.key, required this.documentId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _documentInitialized = false;

  @override
  Widget build(BuildContext context) {
    final documentAsync = ref.watch(documentLoaderProvider(widget.documentId));

    return documentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Hata')),
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
        // Initialize document in provider once
        if (!_documentInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(documentProvider.notifier).updateDocument(document);
            ref.read(currentDocumentProvider.notifier).state = document;
          });
          _documentInitialized = true;
        }
        return _EditorContent(
          initialDocument: document,
        );
      },
    );
  }
}

class _EditorContent extends ConsumerWidget {
  final DrawingDocument initialDocument;

  const _EditorContent({
    required this.initialDocument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(autoSaveProvider);
    final hasUnsaved = ref.watch(hasUnsavedChangesProvider);
    final currentDoc = ref.watch(documentProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    // Listen to document changes for auto-save
    ref.listen<DrawingDocument>(documentProvider, (previous, next) {
      if (previous != next) {
        ref.read(currentDocumentProvider.notifier).state = next;
        ref.read(autoSaveProvider.notifier).documentChanged(next);
        ref.read(hasUnsavedChangesProvider.notifier).state = true;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context, ref),
          ),
          title: Row(
            children: [
              Expanded(child: Text(currentDoc.title)),
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (hasUnsaved)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.circle, size: 8, color: Colors.orange),
                ),
            ],
          ),
          actions: [
            // Undo
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo
                  ? () => ref.read(historyManagerProvider.notifier).undo()
                  : null,
            ),
            // Redo
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo
                  ? () => ref.read(historyManagerProvider.notifier).redo()
                  : null,
            ),
            // More menu
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Yeniden Adlandır'),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Text('PDF Olarak Dışa Aktar'),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Text('Paylaş'),
                ),
              ],
            ),
          ],
        ),
        // DrawingScreen is self-contained and uses providers internally
        body: const DrawingScreen(),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context, WidgetRef ref) async {
    final hasUnsaved = ref.read(hasUnsavedChangesProvider);
    final currentDoc = ref.read(documentProvider);
    
    if (hasUnsaved) {
      // Force save before leaving
      ref.read(autoSaveProvider.notifier).saveNow(currentDoc);
      // Wait a bit for save to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (context.mounted) {
      context.pop();
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    final currentDoc = ref.read(documentProvider);
    
    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref, currentDoc);
        break;
      case 'export_pdf':
        _showExportDialog(context, currentDoc);
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşma özelliği yakında eklenecek')),
        );
        break;
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, DrawingDocument document) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Belge Adı'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                // Update document title via provider
                ref.read(documentProvider.notifier).updateTitle(newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, DrawingDocument document) {
    showDialog(
      context: context,
      builder: (context) => PDFExportDialog(totalPages: document.pageCount),
    );
  }
}

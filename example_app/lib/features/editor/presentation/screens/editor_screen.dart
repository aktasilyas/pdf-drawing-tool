import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_ui/drawing_ui.dart';
import '../providers/editor_provider.dart';
import '../widgets/pdf_export_dialog.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String documentId;

  const EditorScreen({super.key, required this.documentId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
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
      data: (document) => _EditorContent(
        document: document,
        onDocumentChanged: (doc) {
          ref.read(currentDocumentProvider.notifier).state = doc;
          ref.read(autoSaveProvider.notifier).documentChanged(doc);
          ref.read(hasUnsavedChangesProvider.notifier).state = true;
        },
      ),
    );
  }
}

class _EditorContent extends ConsumerStatefulWidget {
  final DrawingDocument document;
  final ValueChanged<DrawingDocument> onDocumentChanged;

  const _EditorContent({
    required this.document,
    required this.onDocumentChanged,
  });

  @override
  ConsumerState<_EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends ConsumerState<_EditorContent> {
  DrawingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = DrawingController(document: widget.document);
    _controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller != null) {
      widget.onDocumentChanged(_controller!.document);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(autoSaveProvider);
    final hasUnsaved = ref.watch(hasUnsavedChangesProvider);
    final currentDoc = ref.watch(currentDocumentProvider) ?? widget.document;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
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
              onPressed: _controller?.canUndo ?? false
                  ? () => _controller?.undo()
                  : null,
            ),
            // Redo
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _controller?.canRedo ?? false
                  ? () => _controller?.redo()
                  : null,
            ),
            // More menu
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
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
        body: _controller != null
            ? DrawingScreen(
                controller: _controller,
                showToolbar: true,
                showPageNavigator: currentDoc.pageCount > 1,
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final hasUnsaved = ref.read(hasUnsavedChangesProvider);
    final currentDoc = ref.read(currentDocumentProvider) ?? widget.document;
    
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

  void _handleMenuAction(BuildContext context, String action) {
    final currentDoc = ref.read(currentDocumentProvider) ?? widget.document;
    
    switch (action) {
      case 'rename':
        _showRenameDialog(context, currentDoc);
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

  void _showRenameDialog(BuildContext context, DrawingDocument document) {
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
                // Update document title
                final updatedDoc = document.copyWith(title: newTitle);
                widget.onDocumentChanged(updatedDoc);
                if (_controller != null) {
                  _controller!.document = updatedDoc;
                }
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

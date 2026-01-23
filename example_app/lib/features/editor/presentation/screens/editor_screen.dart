import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart' hide PDFExportDialog;
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/features/editor/presentation/widgets/pdf_export_dialog.dart';
import 'package:intl/intl.dart';

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
        // Initialize document AND PageManager with document's pages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(documentProvider.notifier).updateDocument(document);
          ref.read(currentDocumentProvider.notifier).state = document;
          // FIX: Initialize PageManager with document's pages
          ref.read(pageManagerProvider.notifier).initializeFromDocument(document.pages);
        });

        // Listen to document changes for auto-save
        ref.listen<DrawingDocument>(documentProvider, (previous, next) {
          if (previous != next) {
            ref.read(currentDocumentProvider.notifier).state = next;
            ref.read(autoSaveProvider.notifier).documentChanged(next);
            ref.read(hasUnsavedChangesProvider.notifier).state = true;
          }
        });

        return Scaffold(
          // NO AppBar - DrawingScreen handles everything
          body: DrawingScreen(
            documentTitle: document.title,
            onHomePressed: () => _handleBack(context, ref),
            onTitlePressed: () => _showDocumentMenu(context, ref, document),
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
    final hasUnsaved = ref.read(hasUnsavedChangesProvider);
    final currentDoc = ref.read(documentProvider);

    if (hasUnsaved) {
      // Force save before leaving
      ref.read(autoSaveProvider.notifier).saveNow(currentDoc);
      // Wait a bit for save to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (context.mounted) {
      context.go('/documents');
    }
  }

  void _showDocumentMenu(BuildContext context, WidgetRef ref, DrawingDocument document) {
    final currentDoc = ref.watch(documentProvider);
    final isSaving = ref.watch(autoSaveProvider);
    final hasUnsaved = ref.watch(hasUnsavedChangesProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document info header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentDoc.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSaving)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (hasUnsaved)
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.orange,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Son düzenleme: ${_formatDate(currentDoc.updatedAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Menu items
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Yeniden Adlandır'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, currentDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF Olarak Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                _showExportDialog(context, ref, currentDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Paylaş'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paylaşma özelliği yakında eklenecek'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(
                'Çöpe Taşı',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dakika önce';
    if (diff.inDays < 1) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    
    return DateFormat('dd.MM.yyyy').format(date);
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, DrawingDocument document) {
    final controller = TextEditingController(text: document.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Belge Adı',
            border: OutlineInputBorder(),
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

  void _showExportDialog(BuildContext context, WidgetRef ref, DrawingDocument document) {
    showDialog(
      context: context,
      builder: (context) => PDFExportDialog(
        totalPages: document.pageCount,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çöpe Taşı'),
        content: const Text(
          'Bu belge çöpe taşınacak. Daha sonra geri yükleyebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement move to trash
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Çöpe taşıma özelliği yakında eklenecek'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Çöpe Taşı'),
          ),
        ],
      ),
    );
  }
}

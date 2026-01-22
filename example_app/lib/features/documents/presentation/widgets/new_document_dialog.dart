import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/documents_strings.dart';
import '../providers/documents_provider.dart';
import '../../domain/entities/template.dart';

class NewDocumentDialog extends ConsumerStatefulWidget {
  const NewDocumentDialog({super.key});

  @override
  ConsumerState<NewDocumentDialog> createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends ConsumerState<NewDocumentDialog> {
  final _titleController = TextEditingController();
  Template _selectedTemplate = Template.all.first;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text(DocumentsStrings.createNewDocument),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: DocumentsStrings.documentTitle,
                hintText: 'Başlıksız Belge',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            
            const SizedBox(height: 24),
            
            // Template selection
            Text(
              DocumentsStrings.selectTemplate,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Template grid
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: Template.all.length,
                itemBuilder: (context, index) {
                  final template = Template.all[index];
                  final isSelected = template.id == _selectedTemplate.id;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTemplate = template;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Template preview
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.description_outlined,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          
                          // Template name
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(7),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  template.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                if (template.isPremium)
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text(DocumentsStrings.cancel),
        ),
        
        FilledButton(
          onPressed: _isCreating ? null : _createDocument,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(DocumentsStrings.create),
        ),
      ],
    );
  }

  Future<void> _createDocument() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final title = _titleController.text.trim().isEmpty
          ? 'Başlıksız Belge'
          : _titleController.text.trim();

      final folderId = ref.read(currentFolderIdProvider);
      
      await ref.read(documentsProvider(folderId: folderId).notifier).createDocument(
            title: title,
            templateId: _selectedTemplate.id,
            folderId: folderId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

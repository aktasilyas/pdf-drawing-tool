import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/template.dart';
import 'package:example_app/features/documents/presentation/constants/documents_strings.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Shows the new document bottom sheet
void showNewDocumentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const NewDocumentSheet(),
  );
}

class NewDocumentSheet extends ConsumerStatefulWidget {
  const NewDocumentSheet({super.key});

  @override
  ConsumerState<NewDocumentSheet> createState() => _NewDocumentSheetState();
}

class _NewDocumentSheetState extends ConsumerState<NewDocumentSheet> {
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.6, // 60% of screen height
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DocumentsStrings.createNewDocument,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Document title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: DocumentsStrings.documentTitle,
              hintText: 'Başlıksız Belge',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            autofocus: true,
          ),
          
          const SizedBox(height: 24),
          
          // Template selection header
          Text(
            DocumentsStrings.selectTemplate,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Template grid - expanded
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: Template.all.length,
              itemBuilder: (context, index) {
                final template = Template.all[index];
                return _TemplateCard(
                  template: template,
                  isSelected: template.id == _selectedTemplate.id,
                  onTap: () {
                    setState(() {
                      _selectedTemplate = template;
                    });
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.pop(context),
                child: const Text(DocumentsStrings.cancel),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isCreating ? null : _createDocument,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text(DocumentsStrings.create),
              ),
            ],
          ),
        ],
      ),
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
      
      await ref.read(documentsControllerProvider.notifier).createDocument(
            title: title,
            templateId: _selectedTemplate.id,
            folderId: folderId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge oluşturuldu: $title'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

/// Template card with visual preview
class _TemplateCard extends StatelessWidget {
  final Template template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            // Template preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CustomPaint(
                    painter: _TemplatePreviewPainter(template.type),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            
            // Template name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      template.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (template.isPremium) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.workspace_premium,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for template previews
class _TemplatePreviewPainter extends CustomPainter {
  final TemplateType type;

  _TemplatePreviewPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    switch (type) {
      case TemplateType.blank:
        // Just white background, no lines
        break;
        
      case TemplateType.thinLined:
        // Thin horizontal lines
        final spacing = size.height / 12;
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint..strokeWidth = 0.5,
          );
        }
        break;
        
      case TemplateType.thickLined:
        // Thick horizontal lines
        final spacing = size.height / 8;
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint..strokeWidth = 1.5,
          );
        }
        break;
        
      case TemplateType.smallGrid:
        // Small grid
        final spacing = size.width / 10;
        // Vertical lines
        for (var x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            paint..strokeWidth = 0.5,
          );
        }
        // Horizontal lines
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint..strokeWidth = 0.5,
          );
        }
        break;
        
      case TemplateType.largeGrid:
        // Large grid
        final spacing = size.width / 5;
        // Vertical lines
        for (var x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            paint..strokeWidth = 1,
          );
        }
        // Horizontal lines
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint..strokeWidth = 1,
          );
        }
        break;
        
      case TemplateType.dotted:
        // Dots
        final spacing = size.width / 8;
        paint.strokeCap = StrokeCap.round;
        for (var x = spacing; x < size.width; x += spacing) {
          for (var y = spacing; y < size.height; y += spacing) {
            canvas.drawCircle(
              Offset(x, y),
              1.5,
              paint..style = PaintingStyle.fill,
            );
          }
        }
        break;
        
      case TemplateType.cornell:
        // Cornell note template
        paint.strokeWidth = 1;
        
        // Left margin line (for cue column)
        final leftMargin = size.width * 0.25;
        canvas.drawLine(
          Offset(leftMargin, 0),
          Offset(leftMargin, size.height * 0.8),
          paint..color = Colors.red.shade300,
        );
        
        // Bottom section line (for summary)
        final bottomLine = size.height * 0.8;
        canvas.drawLine(
          Offset(0, bottomLine),
          Offset(size.width, bottomLine),
          paint..color = Colors.red.shade300,
        );
        
        // Horizontal lines in main area
        paint.color = Colors.grey.shade300;
        final lineSpacing = size.height / 10;
        for (var y = lineSpacing; y < bottomLine; y += lineSpacing) {
          canvas.drawLine(
            Offset(leftMargin + 4, y),
            Offset(size.width, y),
            paint..strokeWidth = 0.5,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Keep old class for backward compatibility but redirect
class NewDocumentDialog extends ConsumerStatefulWidget {
  const NewDocumentDialog({super.key});

  @override
  ConsumerState<NewDocumentDialog> createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends ConsumerState<NewDocumentDialog> {
  @override
  void initState() {
    super.initState();
    // Close this dialog and open the sheet instead
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      showNewDocumentSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

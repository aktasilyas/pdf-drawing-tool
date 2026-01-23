import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/template.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Shows the new document bottom sheet
void showNewDocumentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NewDocumentSheet(),
  );
}

class NewDocumentSheet extends ConsumerStatefulWidget {
  const NewDocumentSheet({super.key});

  @override
  ConsumerState<NewDocumentSheet> createState() => _NewDocumentSheetState();
}

class _NewDocumentSheetState extends ConsumerState<NewDocumentSheet> {
  final _titleController = TextEditingController(text: 'Adsız Not Defteri');
  DocumentType _selectedDocumentType = DocumentType.notebook;
  Template _selectedTemplate = Template.all.first;
  String _paperColor = 'Sarı kağıt';
  bool _isPortrait = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and settings
                        _buildHeader(),

                        const SizedBox(height: 24),

                        // Document type selector
                        _buildDocumentTypeSelector(),

                        const SizedBox(height: 24),

                        // Template sections (only for types that support templates)
                        if (_selectedDocumentType.showsTemplateSelection) ...[
                          _buildTemplateSection(
                          'Temel',
                          Template.all.where((t) =>
                              t.type == TemplateType.blank ||
                              t.type == TemplateType.thinLined ||
                              t.type == TemplateType.thickLined ||
                              t.type == TemplateType.dotted ||
                              t.type == TemplateType.smallGrid ||
                              t.type == TemplateType.largeGrid).toList(),
                        ),

                          const SizedBox(height: 24),

                          _buildTemplateSection(
                            'Yazım Kağıtları',
                            Template.all.where((t) => t.type == TemplateType.cornell).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isCreating ? null : _createDocument,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('${_selectedDocumentType.displayName} Oluştur'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title input
        const Text(
          'Başlık',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Adsız Not Defteri',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        const SizedBox(height: 16),

        // Quick options row
        Row(
          children: [
            // Paper color dropdown
            Expanded(
              child: _buildDropdownButton(
                value: _paperColor,
                items: ['Beyaz kağıt', 'Sarı kağıt', 'Gri kağıt'],
                onChanged: (value) {
                  setState(() {
                    _paperColor = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // Orientation toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildOrientationButton(Icons.phone_android, true),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  _buildOrientationButton(Icons.stay_current_landscape, false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentTypeSelector() {
    // Kullanılabilir tipler (şimdilik sadece 3 tane)
    final availableTypes = [
      DocumentType.notebook,
      DocumentType.whiteboard,
      DocumentType.quickNote,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doküman Tipi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: availableTypes.map((type) {
            final isSelected = type == _selectedDocumentType;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDocumentType = type;
                  // Update title placeholder
                  if (_titleController.text == 'Adsız Not Defteri' ||
                      _titleController.text.startsWith('Adsız')) {
                    _titleController.text = 'Adsız ${type.displayName}';
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconForType(type),
                      size: 20,
                      color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIconForType(DocumentType type) {
    switch (type) {
      case DocumentType.notebook:
        return Icons.description_outlined;
      case DocumentType.whiteboard:
        return Icons.grid_on;
      case DocumentType.quickNote:
        return Icons.edit_note;
      case DocumentType.image:
        return Icons.image_outlined;
      case DocumentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentType.textDocument:
        return Icons.article_outlined;
    }
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrientationButton(IconData icon, bool isPortraitBtn) {
    final isSelected = _isPortrait == isPortraitBtn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isPortrait = isPortraitBtn;
          });
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection(String title, List<Template> templates) {
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.expand_more, size: 20),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = (width - 48) / 5; // 5 cards per row with spacing
            final cardHeight = cardWidth * 1.3;

            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: templates.map((template) {
                return SizedBox(
                  width: cardWidth,
                  child: _TemplateCard(
                    template: template,
                    isSelected: template.id == _selectedTemplate.id,
                    paperColor: _paperColor,
                    isPortrait: _isPortrait,
                    onTap: () {
                      setState(() {
                        _selectedTemplate = template;
                      });
                    },
                    height: cardHeight,
                  ),
                );
              }).toList(),
            );
          },
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
          ? 'Adsız Not Defteri'
          : _titleController.text.trim();

      final folderId = ref.read(currentFolderIdProvider);

      // Log selections for debugging
      debugPrint('📝 Creating document:');
      debugPrint('  Type: ${_selectedDocumentType.displayName}');
      debugPrint('  Title: $title');
      debugPrint('  Template: ${_selectedTemplate.name}');
      debugPrint('  Paper Color: $_paperColor');
      debugPrint('  Orientation: ${_isPortrait ? "Portrait" : "Landscape"}');

      await ref.read(documentsControllerProvider.notifier).createDocument(
            title: title,
            templateId: _selectedTemplate.id,
            folderId: folderId,
            paperColor: _paperColor,
            isPortrait: _isPortrait,
            documentType: _selectedDocumentType.name,
          );

      if (mounted) {
        Navigator.pop(context);
        
        final orientation = _isPortrait ? 'Dikey' : 'Yatay';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title oluşturuldu ($_paperColor, $orientation)'),
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
            behavior: SnackBarBehavior.floating,
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
  final double height;
  final String paperColor;
  final bool isPortrait;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
    required this.height,
    required this.paperColor,
    required this.isPortrait,
  });

  Color get _getPaperColor {
    switch (paperColor) {
      case 'Beyaz kağıt':
        return const Color(0xFFFFFFFF);
      case 'Sarı kağıt':
        return const Color(0xFFFFFDE7);
      case 'Gri kağıt':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFFFFDE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Template preview
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: height * 0.75,
            decoration: BoxDecoration(
              color: _getPaperColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: _TemplatePreviewPainter(template.type),
                size: Size.infinite,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Template name
          Text(
            template.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Premium badge if needed
          if (template.isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.workspace_premium,
                size: 12,
                color: Colors.amber.shade700,
              ),
            ),
        ],
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
        final spacing = size.height / 15;
        paint.color = Colors.grey.shade300;
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(4, y),
            Offset(size.width - 4, y),
            paint..strokeWidth = 0.5,
          );
        }
        break;

      case TemplateType.thickLined:
        // Thick horizontal lines
        final spacing = size.height / 10;
        paint.color = Colors.grey.shade300;
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(
            Offset(4, y),
            Offset(size.width - 4, y),
            paint..strokeWidth = 1.2,
          );
        }
        break;

      case TemplateType.smallGrid:
        // Small grid
        final spacing = size.width / 12;
        paint.color = Colors.grey.shade300;
        paint.strokeWidth = 0.4;
        // Vertical lines
        for (var x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        // Horizontal lines
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;

      case TemplateType.largeGrid:
        // Large grid
        final spacing = size.width / 6;
        paint.color = Colors.grey.shade300;
        paint.strokeWidth = 0.8;
        // Vertical lines
        for (var x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        // Horizontal lines
        for (var y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;

      case TemplateType.dotted:
        // Dots
        final spacing = size.width / 10;
        paint.color = Colors.grey.shade400;
        paint.style = PaintingStyle.fill;
        for (var x = spacing; x < size.width; x += spacing) {
          for (var y = spacing; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 1.2, paint);
          }
        }
        break;

      case TemplateType.cornell:
        // Cornell note template
        paint.strokeWidth = 1;
        paint.color = Colors.red.shade300;

        // Left margin line (for cue column)
        final leftMargin = size.width * 0.28;
        canvas.drawLine(
          Offset(leftMargin, 4),
          Offset(leftMargin, size.height * 0.75),
          paint,
        );

        // Bottom section line (for summary)
        final bottomLine = size.height * 0.75;
        canvas.drawLine(
          Offset(4, bottomLine),
          Offset(size.width - 4, bottomLine),
          paint,
        );

        // Horizontal lines in main area
        paint.color = Colors.grey.shade300;
        paint.strokeWidth = 0.5;
        final lineSpacing = size.height / 12;
        for (var y = lineSpacing; y < bottomLine; y += lineSpacing) {
          canvas.drawLine(
            Offset(leftMargin + 4, y),
            Offset(size.width - 4, y),
            paint,
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

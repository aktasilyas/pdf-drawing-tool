import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/template.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Dropdown menü item'ları
enum NewDocumentOption {
  notebook,    // 📓 Not Defteri - şablon seçimi göster
  whiteboard,  // 🔲 Beyaz Tahta - şablon seçimi göster  
  quickNote,   // ✏️ Hızlı Not - direkt aç
  importPdf,   // 📄 PDF İçe Aktar - dosya seç, direkt aç
  importImage, // 🖼️ Resim İçe Aktar - dosya seç, direkt aç
}

/// Yeni doküman dropdown menüsünü gösterir
void showNewDocumentDropdown(BuildContext context, GlobalKey buttonKey) {
  final RenderBox button = buttonKey.currentContext!.findRenderObject() as RenderBox;
  final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
  
  showMenu<NewDocumentOption>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy + button.size.height + 4,
      position.dx + button.size.width,
      position.dy + button.size.height + 300,
    ),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    items: [
      _buildMenuItem(NewDocumentOption.notebook, Icons.book_outlined, 'Not Defteri'),
      _buildMenuItem(NewDocumentOption.whiteboard, Icons.space_dashboard_outlined, 'Beyaz Tahta'),
      _buildMenuItem(NewDocumentOption.quickNote, Icons.note_outlined, 'Hızlı Not'),
      const PopupMenuDivider(height: 1),
      _buildMenuItem(NewDocumentOption.importPdf, Icons.picture_as_pdf_outlined, 'PDF İçe Aktar'),
      _buildMenuItem(NewDocumentOption.importImage, Icons.image_outlined, 'Resim İçe Aktar'),
    ],
  ).then((value) {
    if (value == null) return;
    _handleNewDocumentOption(context, value);
  });
}

PopupMenuItem<NewDocumentOption> _buildMenuItem(
  NewDocumentOption option, 
  IconData icon, 
  String label,
) {
  return PopupMenuItem<NewDocumentOption>(
    value: option,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    height: 44,
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF616161),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

void _handleNewDocumentOption(BuildContext context, NewDocumentOption option) {
  switch (option) {
    case NewDocumentOption.notebook:
      // Şablon seçimi ile aç
      showNewDocumentSheet(context, documentType: DocumentType.notebook);
      break;
    case NewDocumentOption.whiteboard:
      // Şablon seçimi ile aç (sadece kağıt rengi)
      showNewDocumentSheet(context, documentType: DocumentType.whiteboard);
      break;
    case NewDocumentOption.quickNote:
      // Direkt aç - varsayılan ayarlar
      _createQuickNote(context);
      break;
    case NewDocumentOption.importPdf:
      // PDF dosya seçici
      _importPdf(context);
      break;
    case NewDocumentOption.importImage:
      // Resim dosya seçici
      _importImage(context);
      break;
  }
}

void _createQuickNote(BuildContext context) {
  // TODO: Direkt canvas aç, varsayılan ayarlarla
  // DocumentType.quickNote, blank background, white paper
}

void _importPdf(BuildContext context) {
  // TODO: file_picker ile PDF seç
}

void _importImage(BuildContext context) {
  // TODO: file_picker ile resim seç
}

/// Shows the new document bottom sheet
void showNewDocumentSheet(BuildContext context, {DocumentType? documentType}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => NewDocumentSheet(
      initialDocumentType: documentType,
    ),
  );
}

class NewDocumentSheet extends ConsumerStatefulWidget {
  final DocumentType? initialDocumentType;
  
  const NewDocumentSheet({
    super.key,
    this.initialDocumentType,
  });

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
  void initState() {
    super.initState();
    _updateTitlePlaceholder();
    
    // initialDocumentType varsa onu kullan
    if (widget.initialDocumentType != null) {
      _selectedDocumentType = widget.initialDocumentType!;
      _updateTitlePlaceholder();
      
      // Whiteboard seçilince blank template'e geç
      if (_selectedDocumentType == DocumentType.whiteboard) {
        _selectedTemplate = Template.all.firstWhere(
          (t) => t.type == TemplateType.blank,
          orElse: () => Template.all.first,
        );
      }
    }
  }

  void _updateTitlePlaceholder() {
    final placeholder = switch (_selectedDocumentType) {
      DocumentType.notebook => 'Adsız Not Defteri',
      DocumentType.whiteboard => 'Adsız Beyaz Tahta',
      DocumentType.quickNote => 'Hızlı Not',
      _ => 'Adsız Doküman',
    };
    _titleController.text = placeholder;
  }

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

                        // Template sections (dinamik - doküman tipine göre)
                        if (_selectedDocumentType == DocumentType.whiteboard) ...[
                          // Whiteboard: Sadece blank
                          _buildTemplateSection(
                            'Şablon',
                            Template.all.where((t) => t.type == TemplateType.blank).toList(),
                            showWhiteboardNote: true,
                          ),
                        ] else ...[
                          // Notebook: Tüm şablonlar
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
                          : const Text('Not Defteri Oluştur'),
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

  Widget _buildTemplateSection(String title, List<Template> templates, {bool showWhiteboardNote = false}) {
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
        
        // Whiteboard için açıklama
        if (showWhiteboardNote)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Beyaz tahta sonsuz bir canvas\'tır. Çizgi deseni olmaz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
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
      debugPrint('  Title: $title');
      debugPrint('  Template: ${_selectedTemplate.name}');
      debugPrint('  Paper Color: $_paperColor');
      debugPrint('  Orientation: ${_isPortrait ? "Portrait" : "Landscape"}');

      // #region agent log
      debugPrint('🔍 [DEBUG] _createDocument - selectedDocumentType: $_selectedDocumentType');
      debugPrint('🔍 [DEBUG] _createDocument - templateId: ${_selectedTemplate.id}');
      // #endregion

      await ref.read(documentsControllerProvider.notifier).createDocument(
            title: title,
            templateId: _selectedTemplate.id,
            folderId: folderId,
            paperColor: _paperColor,
            isPortrait: _isPortrait,
            documentType: _selectedDocumentType,
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

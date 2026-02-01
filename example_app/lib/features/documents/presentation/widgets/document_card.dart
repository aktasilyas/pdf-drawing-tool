import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

class DocumentCard extends ConsumerWidget {
  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMorePressed;
  final bool isSelectionMode;
  final bool isSelected;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onMorePressed,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (!isSelectionMode) {
          // Enter selection mode and select this document
          ref.read(selectionModeProvider.notifier).state = true;
          ref.read(selectedDocumentsProvider.notifier).state = {document.id};
        } else if (onLongPress != null) {
          onLongPress!();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height dynamically
          final availableHeight = constraints.maxHeight;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail container - takes most of the space
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _getPaperColor(document.paperColor),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Thumbnail or template preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _buildThumbnail(ref),
                      ),

                      // Selection overlay (when in selection mode)
                      if (isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),

                      // Selection checkbox (top left in selection mode)
                      if (isSelectionMode)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),

                      // Page count badge (for PDF/multi-page)
                      if (document.pageCount > 1)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${document.pageCount} sayfa',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Favorite star (top right) - hidden in selection mode
                      if (!isSelectionMode)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: onFavoriteToggle,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              document.isFavorite
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 16,
                              color: document.isFavorite
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info section - fixed minimum height
              SizedBox(
                height: availableHeight * 0.18, // 18% of total height for info
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with dropdown
                      Flexible(
                        child: GestureDetector(
                          onTap: onMorePressed,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  document.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Date
                      Text(
                        _formatDate(document.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getPaperColor(String paperColor) {
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

  Widget _buildThumbnail(WidgetRef ref) {
    // Cover önizlemesi - hasCover varsa ve coverId null değilse
    if (document.hasCover && document.coverId != null) {
      final cover = core.CoverRegistry.byId(document.coverId!);
      if (cover != null) {
        return CoverPreviewWidget(
          cover: cover,
          title: document.title,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    
    // PDF veya Image için ilk sayfayı göster
    if (document.documentType == core.DocumentType.pdf || 
        document.documentType == core.DocumentType.image) {
      return _buildFirstPagePreview(ref);
    }
    
    // Şablon önizlemesi
    return _buildTemplatePlaceholder();
  }

  Widget _buildFirstPagePreview(WidgetRef ref) {
    return FutureBuilder<core.DrawingDocument?>(
      future: _loadDocument(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildTemplatePlaceholder();
        }

        final doc = snapshot.data!;
        if (doc.pages.isEmpty) {
          return _buildTemplatePlaceholder();
        }

        final firstPage = doc.pages.first;
        
        // PDF için lazy render
        if (firstPage.background.type == core.BackgroundType.pdf &&
            firstPage.background.pdfFilePath != null &&
            firstPage.background.pdfPageIndex != null) {
          return _buildPdfPreview(ref, firstPage);
        }

        // Image için (pdfData içinde base64 olarak saklanıyor)
        if (firstPage.background.pdfData != null) {
          return _buildImagePreview(firstPage);
        }

        return _buildTemplatePlaceholder();
      },
    );
  }

  Widget _buildPdfPreview(WidgetRef ref, core.Page page) {
    final cacheKey = '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
    final renderAsync = ref.watch(pdfPageRenderProvider(cacheKey));

    return renderAsync.when(
      data: (bytes) {
        if (bytes != null) {
          return Stack(
            children: [
              // White background for PDF
              Container(color: Colors.white),
              // PDF content
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // PDF indicator (book icon overlay)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
        return _buildTemplatePlaceholder();
      },
      loading: () => Container(
        color: Colors.grey[100],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.error_outline, size: 32, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildImagePreview(core.Page page) {
    return Stack(
      children: [
        Image.memory(
          page.background.pdfData!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildTemplatePlaceholder(),
        ),
        // Image indicator
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.image,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<core.DrawingDocument?> _loadDocument(WidgetRef ref) async {
    try {
      final loadUseCase = ref.read(loadDocumentUseCaseProvider);
      final result = await loadUseCase(document.id);
      return result.fold(
        (failure) => null,
        (doc) => doc,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildTemplatePlaceholder() {
    // Notebook için spiral defter görünümü
    if (document.documentType == core.DocumentType.notebook) {
      return Stack(
        children: [
          // Template pattern
          CustomPaint(
            painter: _TemplatePatternPainter(document.templateId),
            size: Size.infinite,
          ),
          // Spiral binding effect (left side)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  8,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Diğer tipler için basit pattern
    return CustomPaint(
      painter: _TemplatePatternPainter(document.templateId),
      size: Size.infinite,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TemplatePatternPainter extends CustomPainter {
  final String templateId;

  _TemplatePatternPainter(this.templateId);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;

    // Draw grid/lined pattern based on template
    switch (templateId) {
      case 'small_grid':
      case 'large_grid':
        _drawGrid(canvas, size, paint, templateId == 'small_grid' ? 10 : 20);
        break;
      case 'thin_lined':
      case 'thick_lined':
        _drawLines(canvas, size, paint, templateId == 'thin_lined' ? 15 : 25);
        break;
      case 'dotted':
        _drawDots(canvas, size, paint);
        break;
      default:
        // Blank - no pattern
        break;
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint, double spacing) {
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 15.0;
    paint.style = PaintingStyle.fill;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

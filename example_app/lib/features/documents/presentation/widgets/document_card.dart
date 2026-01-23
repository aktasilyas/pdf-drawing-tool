import 'package:flutter/material.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';

class DocumentCard extends StatelessWidget {
  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMorePressed;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                      color: const Color(0xFFE0E0E0),
                      width: 1,
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
                        child: _buildThumbnail(),
                      ),

                      // Favorite star (top right) - smaller on mobile
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            document.isFavorite
                                ? Icons.star
                                : Icons.star_outline,
                            size: 18,
                            color: document.isFavorite
                                ? const Color(0xFFFFB300)
                                : const Color(0xFFBDBDBD),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: Color(0xFF999999),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Date
                      Text(
                        _formatDate(document.updatedAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
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

  Widget _buildThumbnail() {
    if (document.thumbnailPath != null) {
      return Image.asset(
        document.thumbnailPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildTemplatePlaceholder(),
      );
    }
    return _buildTemplatePlaceholder();
  }

  Widget _buildTemplatePlaceholder() {
    // Show template pattern based on templateId
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

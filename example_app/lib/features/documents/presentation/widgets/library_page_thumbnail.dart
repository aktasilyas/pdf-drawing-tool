import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart' show CoverGeometry;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/document_thumbnail_painter.dart';

/// Page thumbnail for documents without a cover (PDF, image, whiteboard,
/// notebook without cover).
///
/// The page keeps its own aspect, is contained in the cover board rect and
/// sits on the board's bottom edge so baselines line up across a row.
class LibraryPageThumbnail extends StatelessWidget {
  const LibraryPageThumbnail({super.key, required this.document});

  final DocumentInfo document;

  /// Key of the page rect, for tests.
  static const pageKey = Key('library_page_thumbnail_page');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isWhiteboard = document.documentType == core.DocumentType.whiteboard;

    return LayoutBuilder(
      builder: (context, constraints) {
        final board = CoverGeometry.of(constraints.biggest).cover;
        final pageRect = _pageRect(board);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: pageRect,
              child: Container(
                key: pageKey,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isWhiteboard
                      ? palette.paper
                      : DocumentPaperColors.fromName(document.paperColor),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: palette.border),
                ),
                child: _content(palette),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Largest page of the document's aspect that fits [board], bottom-centred.
  Rect _pageRect(Rect board) {
    final short = document.paperWidthMm < document.paperHeightMm
        ? document.paperWidthMm
        : document.paperHeightMm;
    final long = document.paperWidthMm < document.paperHeightMm
        ? document.paperHeightMm
        : document.paperWidthMm;
    final aspect = document.isPortrait ? short / long : long / short;

    var width = board.width;
    var height = width / aspect;
    if (height > board.height) {
      height = board.height;
      width = height * aspect;
    }
    return Rect.fromLTWH(
      board.left + (board.width - width) / 2,
      board.bottom - height,
      width,
      height,
    );
  }

  Widget _content(AppPalette palette) {
    switch (document.documentType) {
      case core.DocumentType.pdf:
      case core.DocumentType.image:
        return DocumentPreview(document: document);
      case core.DocumentType.whiteboard:
        return CustomPaint(
          painter: WhiteboardGridPainter(
            dotColor: palette.textPrimary.withValues(alpha: 0.08),
          ),
          size: Size.infinite,
        );
      default:
        return CustomPaint(
          painter: DocumentThumbnailPainter(document.templateId),
          size: Size.infinite,
        );
    }
  }
}

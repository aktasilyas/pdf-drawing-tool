import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart'
    show CoverGeometry, pdfPathResolverProvider;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/document_thumbnail_painter.dart';

/// Page thumbnail for documents without a cover (PDF, image, whiteboard,
/// notebook without cover).
///
/// The page keeps its own aspect and is fitted inside the cover board rect,
/// centred on both axes, so every tile in a row shares one box and the
/// title baselines line up. Portrait pages fill the board; landscape pages
/// float centred with the same soft shadow.
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
        final pageRect = LibraryPageThumbnail.pageRect(
          document,
          constraints.biggest,
        );
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
                  boxShadow: [
                    BoxShadow(
                      color: palette.textPrimary.withValues(alpha: 0.10),
                      blurRadius: AppSpacing.sm,
                      offset: const Offset(0, AppSpacing.xxs),
                    ),
                  ],
                ),
                child: document.thumbnailPath == null
                    ? _content()
                    : _InkThumbnail(
                        stored: document.thumbnailPath!,
                        fallback: _content,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Largest page of [d]'s aspect that fits the cover board of [box],
  /// centred in it.
  static Rect pageRect(DocumentInfo d, Size box) {
    final board = CoverGeometry.of(box).cover;
    final short = math.min(d.paperWidthMm, d.paperHeightMm);
    final long = math.max(d.paperWidthMm, d.paperHeightMm);
    final aspect = d.isPortrait ? short / long : long / short;

    var width = board.width;
    var height = width / aspect;
    if (height > board.height) {
      height = board.height;
      width = height * aspect;
    }
    return Rect.fromLTWH(
      board.left + (board.width - width) / 2,
      board.top + (board.height - height) / 2,
      width,
      height,
    );
  }

  // Pages stay light in dark mode, so the dots use the light palette.
  static final Color _dotColor =
      AppPalette.light.textPrimary.withValues(alpha: 0.24);

  Widget _content() {
    switch (document.documentType) {
      case core.DocumentType.pdf:
      case core.DocumentType.image:
        return DocumentPreview(document: document);
      case core.DocumentType.whiteboard:
        return CustomPaint(
          painter: WhiteboardGridPainter(
            dotColor: _dotColor,
            spacing: AppSpacing.md,
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

/// Builds the image provider of a stored library thumbnail path. Overridable
/// in tests.
final libraryThumbnailImageProvider =
    Provider<ImageProvider Function(String stored)>((ref) {
  final paths = ref.watch(pdfPathResolverProvider);
  return (stored) => FileImage(File(paths.resolve(stored)));
});

/// Stored ink thumbnail of a document. [fallback] is only built when the
/// image fails to load, so the content readers behind it stay idle.
class _InkThumbnail extends ConsumerWidget {
  const _InkThumbnail({required this.stored, required this.fallback});

  final String stored;
  final Widget Function() fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageFor = ref.watch(libraryThumbnailImageProvider);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cacheWidth = width.isFinite && width > 0
            ? (width * pixelRatio).ceil()
            : null;
        final base = imageFor(stored);
        return Image(
          image: cacheWidth == null
              ? base
              : ResizeImage(base, width: cacheWidth),
          // The page rect already has the page aspect; cover avoids
          // hairline gaps from rounding.
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback(),
        );
      },
    );
  }
}

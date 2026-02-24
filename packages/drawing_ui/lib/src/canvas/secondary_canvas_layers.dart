import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/interleaved_object_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Builds the content layers for the secondary canvas.
///
/// Mirrors the primary canvas layer stack (background, images, strokes,
/// shapes, texts, sticky notes) using the given [page] data.
/// All layers are read-only (no active stroke, selection, etc.).
Widget buildSecondaryCanvasLayers({
  required core.Page page,
  required core.CanvasMode canvasMode,
  required FlutterStrokeRenderer renderer,
  required ImageCacheManager imageCacheManager,
  required WidgetRef ref,
  CanvasColorScheme? colorScheme,
}) {
  final pageSize = Size(page.size.width, page.size.height);
  final isPdf = page.background.type == core.BackgroundType.pdf;
  final isLimited = !canvasMode.isInfinite;

  // Collect all visible layer content
  final allStrokes = <core.Stroke>[];
  final allShapes = <core.Shape>[];
  final allTexts = <core.TextElement>[];
  final allImages = <core.ImageElement>[];
  final allStickyNotes = <core.StickyNote>[];
  final allElementOrder = <String>[];

  for (final layer in page.layers) {
    if (!layer.isVisible) continue;
    allStrokes.addAll(layer.strokes);
    allShapes.addAll(layer.shapes);
    allTexts.addAll(layer.texts);
    allImages.addAll(layer.images);
    allStickyNotes.addAll(layer.stickyNotes);
    allElementOrder.addAll(layer.elementOrder);
  }

  return Stack(
    clipBehavior: Clip.none,
    children: [
      // ═════════════════════════════════════════════════════════════════
      // LAYER 0: Page Container (limited mode)
      // ═════════════════════════════════════════════════════════════════
      if (isLimited) ...[
        // Page shadow (non-PDF only)
        if (canvasMode.showPageShadow && !isPdf)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: pageSize.width,
                height: pageSize.height,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // PDF background
        if (isPdf)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: _buildPdfBackground(page, ref),
            ),
          ),

        // Pattern background (non-PDF)
        if (!isPdf)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: Container(
                    width: pageSize.width,
                    height: pageSize.height,
                    decoration: BoxDecoration(
                      color: colorScheme?.effectiveBackground(
                              page.background.color) ??
                          Color(page.background.color),
                      border: canvasMode.pageBorderWidth > 0
                          ? Border.all(
                              color: Color(canvasMode.pageBorderColor),
                              width: canvasMode.pageBorderWidth,
                            )
                          : null,
                    ),
                    child: CustomPaint(
                      painter: PageBackgroundPatternPainter(
                        background: page.background,
                        colorScheme: colorScheme,
                      ),
                      size: pageSize,
                      isComplex: true,
                      willChange: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],

      // ─────────────────────────────────────────────────────────────────
      // LAYER 1: Strokes
      // ─────────────────────────────────────────────────────────────────
      if (allStrokes.isNotEmpty)
        RepaintBoundary(
          child: CustomPaint(
            size: pageSize,
            painter: CommittedStrokesPainter(
              strokes: allStrokes,
              renderer: renderer,
            ),
            isComplex: true,
            willChange: false,
          ),
        ),

      // ─────────────────────────────────────────────────────────────────
      // LAYER 2: Shapes
      // ─────────────────────────────────────────────────────────────────
      if (allShapes.isNotEmpty)
        RepaintBoundary(
          child: CustomPaint(
            size: pageSize,
            painter: ShapePainter(shapes: allShapes),
            isComplex: true,
            willChange: false,
          ),
        ),

      // ─────────────────────────────────────────────────────────────────
      // LAYER 3: Images + Texts (interleaved by creation order)
      // ─────────────────────────────────────────────────────────────────
      if (allImages.isNotEmpty || allTexts.isNotEmpty)
        RepaintBoundary(
          child: CustomPaint(
            size: pageSize,
            painter: InterleavedObjectPainter(
              images: allImages,
              texts: allTexts,
              cacheManager: imageCacheManager,
              elementOrder: allElementOrder,
            ),
            isComplex: true,
            willChange: false,
          ),
        ),

      // ─────────────────────────────────────────────────────────────────
      // LAYER 3.5: Sticky Notes
      // ─────────────────────────────────────────────────────────────────
      if (allStickyNotes.isNotEmpty)
        RepaintBoundary(
          child: CustomPaint(
            size: pageSize,
            painter: StickyNotePainter(
              stickyNotes: allStickyNotes,
              renderer: renderer,
            ),
            isComplex: true,
            willChange: false,
          ),
        ),
    ],
  );
}

/// Builds the PDF background for the secondary canvas.
Widget _buildPdfBackground(core.Page page, WidgetRef ref) {
  final bg = page.background;
  final pageSize = Size(page.size.width, page.size.height);

  // In-memory pdfData (immediate render)
  if (bg.pdfData != null) {
    return _pdfImage(bg.pdfData!, pageSize);
  }

  // Lazy load from cache
  if (bg.pdfFilePath != null && bg.pdfPageIndex != null) {
    final cacheKey = '${bg.pdfFilePath}|${bg.pdfPageIndex}';
    final cache = ref.watch(pdfPageCacheProvider);
    final bytes = cache[cacheKey];
    if (bytes != null) {
      return _pdfImage(bytes, pageSize);
    }
  }

  // Placeholder
  return Container(
    width: pageSize.width,
    height: pageSize.height,
    color: Colors.white,
    child: Center(
      child: PhosphorIcon(StarNoteIcons.pdfFile,
          size: 32, color: Colors.grey.shade300),
    ),
  );
}

/// Renders a PDF page from bytes.
Widget _pdfImage(Uint8List bytes, Size pageSize) {
  return Container(
    width: pageSize.width,
    height: pageSize.height,
    color: Colors.white,
    child: Image.memory(
      bytes,
      width: pageSize.width,
      height: pageSize.height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
    ),
  );
}

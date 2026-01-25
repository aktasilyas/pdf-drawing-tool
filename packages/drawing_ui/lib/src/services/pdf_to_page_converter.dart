import 'package:flutter/foundation.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:pdfx/pdfx.dart';
import 'pdf_page_renderer.dart';

/// Options for PDF to Page conversion.
class PDFConversionOptions {
  /// Whether to include PDF annotations (not yet implemented).
  final bool includeAnnotations;

  /// Whether to preserve PDF links (not yet implemented).
  final bool preserveLinks;

  /// Whether to embed rendered PDF images as page background.
  final bool embedImages;

  const PDFConversionOptions({
    this.includeAnnotations = false,
    this.preserveLinks = false,
    this.embedImages = true,
  });

  /// Creates a copy with new values.
  PDFConversionOptions copyWith({
    bool? includeAnnotations,
    bool? preserveLinks,
    bool? embedImages,
  }) {
    return PDFConversionOptions(
      includeAnnotations: includeAnnotations ?? this.includeAnnotations,
      preserveLinks: preserveLinks ?? this.preserveLinks,
      embedImages: embedImages ?? this.embedImages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFConversionOptions &&
          includeAnnotations == other.includeAnnotations &&
          preserveLinks == other.preserveLinks &&
          embedImages == other.embedImages;

  @override
  int get hashCode =>
      Object.hash(includeAnnotations, preserveLinks, embedImages);
}

/// Service for converting PDF pages to Drawing Page models.
class PDFToPageConverter {
  /// Default render options for PDF pages.
  final PDFRenderOptions defaultRenderOptions;

  /// PDF page renderer.
  final PDFPageRenderer _renderer;

  PDFToPageConverter({
    PDFRenderOptions? defaultRenderOptions,
    PDFPageRenderer? renderer,
  })  : defaultRenderOptions = defaultRenderOptions ??
            const PDFRenderOptions(
              quality: RenderQuality
                  .high, // 288 DPI - yüksek kalite (A4: ~2380x3368 px)
              devicePixelRatio: 1.5, // 1.5x scale - dengeli kalite/boyut
            ),
        _renderer = renderer ?? PDFPageRenderer();

  /// Calculates PageSize from PDF dimensions in points.
  PageSize calculatePageSize({
    required double pdfWidth,
    required double pdfHeight,
  }) {
    if (pdfWidth <= 0 || pdfHeight <= 0) {
      throw ArgumentError(
        'PDF dimensions must be positive: width=$pdfWidth, height=$pdfHeight',
      );
    }

    return PageSize(width: pdfWidth, height: pdfHeight);
  }

  /// Creates a default white background.
  PageBackground createDefaultBackground() {
    return const PageBackground(type: BackgroundType.blank, color: 0xFFFFFFFF);
  }

  /// Creates a background with a custom color.
  PageBackground createBackgroundWithColor(int color) {
    return PageBackground(type: BackgroundType.blank, color: color);
  }

  /// Determines the page index to use.
  ///
  /// If [targetIndex] is provided, uses that.
  /// Otherwise, derives from [pdfPageNumber] (1-based → 0-based).
  int determinePageIndex({
    required int? targetIndex,
    required int pdfPageNumber,
  }) {
    if (pdfPageNumber < 1) {
      throw ArgumentError('PDF page number must be >= 1: $pdfPageNumber');
    }

    return targetIndex ?? (pdfPageNumber - 1);
  }

  /// Generates a page name from PDF page number.
  String generatePageName({
    required int pdfPageNumber,
    String? documentTitle,
  }) {
    if (documentTitle != null && documentTitle.isNotEmpty) {
      return '$documentTitle - Page $pdfPageNumber';
    }
    return 'PDF Page $pdfPageNumber';
  }

  /// Validates a list of page numbers against total page count.
  bool validatePageNumbers({
    required List<int> pageNumbers,
    required int totalPages,
  }) {
    if (pageNumbers.isEmpty) {
      return false;
    }

    for (final pageNumber in pageNumbers) {
      if (pageNumber < 1 || pageNumber > totalPages) {
        return false;
      }
    }

    return true;
  }

  /// Generates a range of page numbers.
  List<int> generatePageRange(int start, int end) {
    if (start > end) {
      return [];
    }

    return List.generate(end - start + 1, (index) => start + index);
  }

  /// Creates an empty Page with given properties.
  Page createEmptyPage({
    required int index,
    required double width,
    required double height,
    String? name,
    PageBackground? background,
  }) {
    // Note: name parameter is not used as Page model doesn't have a name field
    return Page(
      id: 'page_${DateTime.now().millisecondsSinceEpoch}_$index',
      index: index,
      size: PageSize(width: width, height: height),
      background: background ?? createDefaultBackground(),
      layers: [
        Layer.empty('Layer 1')
      ], // FIX: PDF pages need at least one layer for drawing
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Converts a single PDF page to a Drawing Page.
  ///
  /// The PDF page is rendered and embedded as the page background.
  /// 
  /// If [useLazyLoading] is true (default), the page will not be rendered immediately.
  /// The page will be marked as PDF type with just the page index, and rendering
  /// happens on-demand when the page is displayed.
  Future<Page?> convertPage(
    PdfDocument document,
    int pageNumber, {
    int? targetPageIndex,
    PDFRenderOptions? renderOptions,
    PDFConversionOptions? conversionOptions,
    bool useLazyLoading = true, // Enable lazy loading by default
  }) async {
    try {
      // Validate page number
      if (!_renderer.isValidPageNumber(pageNumber, document.pagesCount)) {
        return null;
      }

      // Get PDF page size
      final pdfPageSize = await _renderer.getPageSize(document, pageNumber);
      if (pdfPageSize == null) {
        return null;
      }

      // Calculate page properties
      final pageSize = calculatePageSize(
        pdfWidth: pdfPageSize.width,
        pdfHeight: pdfPageSize.height,
      );

      final pageIndex = determinePageIndex(
        targetIndex: targetPageIndex,
        pdfPageNumber: pageNumber,
      );

      // Create base page
      final page = createEmptyPage(
        index: pageIndex,
        width: pageSize.width,
        height: pageSize.height,
        name: generatePageName(pdfPageNumber: pageNumber),
      );

      final options = conversionOptions ?? const PDFConversionOptions();
      if (!options.embedImages) {
        return page;
      }

      // ═══════════════════════════════════════════════════════════════════
      // LAZY LOADING MODE - Don't render now, placeholder for lazy loading
      // ═══════════════════════════════════════════════════════════════════
      if (useLazyLoading) {
        // NOTE: In lazy loading mode, we don't have pdfFilePath here.
        // The file path is set during import in PDFImportService.
        // This mode is not used when useLazyLoading=true in the new system.
        // Return page without PDF background - will be set by import service.
        debugPrint('⚡ PDF page $pageNumber prepared for lazy loading (not rendered yet)');
        return page;
      }

      // ═══════════════════════════════════════════════════════════════════
      // IMMEDIATE MODE - Render now (fallback for compatibility)
      // ═══════════════════════════════════════════════════════════════════
      final renderedImage = await _renderer.renderPage(
        document,
        pageNumber,
        options: renderOptions ?? defaultRenderOptions,
      );

      if (renderedImage != null) {
        // Create PDF background with rendered image data
        final pdfBackground = PageBackground(
          type: BackgroundType.pdf,
          color: 0xFFFFFFFF,
          pdfData: renderedImage,
          pdfPageIndex: pageNumber,
        );

        // Debug logging
        debugPrint(
            '📄 PDF page $pageNumber rendered immediately, bytes: ${renderedImage.lengthInBytes}');

        return page.copyWith(background: pdfBackground);
      }

      return page;
    } catch (e) {
      return null;
    }
  }

  /// Converts multiple PDF pages to Drawing Pages.
  ///
  /// Returns a list of successfully converted pages.
  /// 
  /// If [useLazyLoading] is true (default), pages are not rendered immediately.
  Future<List<Page>> convertPages(
    PdfDocument document,
    List<int> pageNumbers, {
    PDFRenderOptions? renderOptions,
    PDFConversionOptions? conversionOptions,
    bool useLazyLoading = true,
  }) async {
    // Validate all page numbers
    if (!validatePageNumbers(
      pageNumbers: pageNumbers,
      totalPages: document.pagesCount,
    )) {
      return [];
    }

    final convertedPages = <Page>[];

    for (final pageNumber in pageNumbers) {
      final page = await convertPage(
        document,
        pageNumber,
        renderOptions: renderOptions,
        conversionOptions: conversionOptions,
        useLazyLoading: useLazyLoading,
      );

      if (page != null) {
        convertedPages.add(page);
      }
    }

    return convertedPages;
  }

  /// Converts all pages in a PDF document.
  Future<List<Page>> convertAllPages(
    PdfDocument document, {
    PDFRenderOptions? renderOptions,
    PDFConversionOptions? conversionOptions,
    bool useLazyLoading = true,
  }) async {
    final pageNumbers = generatePageRange(1, document.pagesCount);
    return convertPages(
      document,
      pageNumbers,
      renderOptions: renderOptions,
      conversionOptions: conversionOptions,
      useLazyLoading: useLazyLoading,
    );
  }
}

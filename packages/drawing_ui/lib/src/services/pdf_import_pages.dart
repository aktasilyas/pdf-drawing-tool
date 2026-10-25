import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'pdf_import_models.dart';
import 'pdf_page_renderer.dart';
import 'pdf_to_page_converter.dart';

/// Generates the 1-based page numbers from [start] to [end] (inclusive).
List<int> generatePdfPageRange({required int start, required int end}) {
  if (start > end) return [];
  return List.generate(end - start + 1, (index) => start + index);
}

/// Optimal batch size for processing [totalPages] with [availableMemory]
/// bytes (10 MB per page estimate, at most 50).
int optimalPdfBatchSize({
  required int totalPages,
  required int availableMemory,
}) {
  const int maxBatchSize = 50;
  const int avgPageMemory = 10 * 1024 * 1024; // 10MB per page estimate

  final memoryBasedBatch = (availableMemory / avgPageMemory).floor();
  final batchSize = memoryBasedBatch.clamp(1, maxBatchSize);

  return batchSize > totalPages ? totalPages : batchSize;
}

/// Whether every 1-based page number lies within [totalPages]; an empty
/// selection is invalid.
bool isValidPdfPageSelection(List<int> pageNumbers, {required int totalPages}) {
  if (pageNumbers.isEmpty) return false;
  return pageNumbers.every((n) => n >= 1 && n <= totalPages);
}

/// Gets page numbers to import based on [config].
List<int> pdfImportPageNumbers(PDFImportConfig config, int totalPages) {
  switch (config.pageSelection) {
    case PDFPageSelection.all:
      return generatePdfPageRange(start: 1, end: totalPages);

    case PDFPageSelection.range:
      return generatePdfPageRange(
        start: config.startPage!,
        end: config.endPage!,
      );

    case PDFPageSelection.selected:
      return List.from(config.selectedPages!);
  }
}

/// Returns a new, not yet written file under `<app documents>/pdfs/`.
Future<File> newImportedPdfFile() async {
  final appDir = await getApplicationDocumentsDirectory();
  final pdfDir = Directory('${appDir.path}/pdfs');
  if (!await pdfDir.exists()) {
    await pdfDir.create(recursive: true);
  }

  final pdfId = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
  return File('${pdfDir.path}/$pdfId.pdf');
}

/// Builds lazy pages (size + file path only, no rendering) for
/// [pageNumbers] of [document]. Pages that cannot be read are skipped.
/// [onPageProcessed] runs after every page, skipped or not.
Future<List<Page>> buildLazyPdfPages(
  PdfDocument document,
  List<int> pageNumbers, {
  required String pdfFilePath,
  required void Function() onPageProcessed,
}) async {
  final pages = <Page>[];

  for (final pageNumber in pageNumbers) {
    PdfPage? pdfPage;
    try {
      pdfPage = await document.getPage(pageNumber);

      final page = Page(
        id: 'page_${DateTime.now().millisecondsSinceEpoch}_$pageNumber',
        index: pageNumber - 1,
        size: PageSize(width: pdfPage.width, height: pdfPage.height),
        background: PageBackground.pdfLazy(
          pageIndex: pageNumber,
          pdfFilePath: pdfFilePath,
        ),
        layers: [Layer.empty('Layer 1')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      pages.add(page);
    } catch (e) {
      debugPrint('Warning: Could not load PDF page $pageNumber: $e');
      // Skip the broken page and continue.
    } finally {
      try {
        await pdfPage?.close();
      } catch (_) {}
    }

    onPageProcessed();
  }

  return pages;
}

/// Renders [pageNumbers] of [document] now (legacy immediate mode).
/// [onPageProcessed] runs after every page.
Future<List<Page>> convertPdfPagesImmediately(
  PdfDocument document,
  List<int> pageNumbers, {
  required PDFToPageConverter converter,
  required PDFRenderOptions renderOptions,
  required bool embedImages,
  required void Function() onPageProcessed,
}) async {
  final pages = <Page>[];

  for (final pageNumber in pageNumbers) {
    final page = await converter.convertPage(
      document,
      pageNumber,
      renderOptions: renderOptions,
      conversionOptions: PDFConversionOptions(
        embedImages: embedImages,
      ),
      useLazyLoading: false, // Force immediate rendering
    );

    if (page != null) {
      pages.add(page);
    }

    onPageProcessed();
  }

  return pages;
}

import 'dart:io';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:drawing_ui/src/utils/drawing_log.dart';

/// A source PDF opened once and kept for all of its pages in an export.
abstract class PdfSource {
  /// Renders page [index] as a JPEG, or null when it cannot be rendered.
  Future<Uint8List?> renderJpeg(int index, double scale);

  Future<void> close();
}

/// Opens the source PDF at a path; null when the file is missing/unreadable.
typedef PdfSourceOpener = Future<PdfSource?> Function(String path);

/// One [PdfSource] per path, opened lazily and closed after the export.
///
/// A source that fails to open (damaged file) counts as missing, so its
/// pages are reported instead of failing the whole export (#463).
class PdfSourcePool {
  PdfSourcePool(this._open);

  final PdfSourceOpener _open;
  final _sources = <String, PdfSource?>{};

  Future<PdfSource?> get(String path) async {
    if (_sources.containsKey(path)) return _sources[path];
    PdfSource? source;
    try {
      source = await _open(path);
    } catch (e) {
      DrawingLog.w('PDF export: could not open source PDF', e);
    }
    return _sources[path] = source;
  }

  /// Renders page [index] of the PDF at [path] as a JPEG; null when the file
  /// is missing or damaged or the page cannot be rendered (#463).
  Future<Uint8List?> renderJpeg(String path, int index, double scale) async {
    final source = await get(path);
    if (source == null) return null;
    try {
      return await source.renderJpeg(index, scale);
    } catch (e) {
      DrawingLog.w('PDF export: could not render source page $index', e);
      return null;
    }
  }

  Future<void> closeAll() async {
    for (final s in _sources.values) {
      try {
        await s?.close();
      } catch (_) {}
    }
    _sources.clear();
  }
}

/// Longest side, in pixels, of a source-PDF page render in an export.
///
/// Same cap as the on-screen and thumbnail renderers
/// (`PDFPageRenderer.maxRenderSide`, `PdfBackgroundRasterizer.maxSidePx`).
const double maxPdfSourceRenderSide = 4096;

/// Pixel size for rendering a [width] x [height] pt page at [scale],
/// scaled down (aspect ratio kept) so the longest side is at most [maxSide].
({double width, double height}) cappedPdfRenderSize(
  double width,
  double height,
  double scale, {
  double maxSide = maxPdfSourceRenderSide,
}) {
  final w = width * scale;
  final h = height * scale;
  final longest = w > h ? w : h;
  if (longest <= maxSide || longest <= 0) return (width: w, height: h);
  final factor = maxSide / longest;
  return (width: w * factor, height: h * factor);
}

/// One page of a source PDF, as seen by [PageRenderingPdfSource].
abstract class PdfRenderPage {
  /// Page size in points.
  double get width;
  double get height;

  /// Renders the page as a JPEG of [width] x [height] pixels.
  Future<Uint8List?> renderJpeg(double width, double height);

  Future<void> close();
}

/// [PdfSource] that renders pages capped at [maxPdfSourceRenderSide] and
/// reports a page that cannot be rendered as null instead of throwing.
class PageRenderingPdfSource implements PdfSource {
  PageRenderingPdfSource({
    required Future<PdfRenderPage> Function(int index) getPage,
    required Future<void> Function() close,
  })  : _getPage = getPage,
        _close = close;

  final Future<PdfRenderPage> Function(int index) _getPage;
  final Future<void> Function() _close;

  @override
  Future<Uint8List?> renderJpeg(int index, double scale) async {
    PdfRenderPage? page;
    try {
      page = await _getPage(index);
      final size = cappedPdfRenderSize(page.width, page.height, scale);
      return await page.renderJpeg(size.width, size.height);
    } catch (e) {
      DrawingLog.w('PDF export: could not render source page $index', e);
      return null;
    } finally {
      try {
        await page?.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() => _close();
}

/// Default opener backed by pdfx.
Future<PdfSource?> openPdfxSource(String path) async {
  if (!await File(path).exists()) return null;
  final doc = await pdfx.PdfDocument.openFile(path);
  return PageRenderingPdfSource(
    getPage: (index) async => _PdfxRenderPage(await doc.getPage(index)),
    close: doc.close,
  );
}

class _PdfxRenderPage implements PdfRenderPage {
  _PdfxRenderPage(this._page);

  final pdfx.PdfPage _page;

  @override
  double get width => _page.width;

  @override
  double get height => _page.height;

  @override
  Future<Uint8List?> renderJpeg(double width, double height) async {
    final img = await _page.render(
      width: width,
      height: height,
      format: pdfx.PdfPageImageFormat.jpeg,
      quality: 90,
    );
    return img?.bytes;
  }

  @override
  Future<void> close() => _page.close();
}

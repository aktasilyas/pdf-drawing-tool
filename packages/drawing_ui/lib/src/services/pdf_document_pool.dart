import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;

/// One open PDF document that renders its pages to PNG bytes.
abstract interface class PdfPageSource {
  /// Renders page [pageNumber] (as stored in `PageBackground.pdfPageIndex`)
  /// into a [width] x [height] pixel PNG. Null when the page renders nothing.
  Future<Uint8List?> renderPage(
    int pageNumber, {
    required int width,
    required int height,
  });

  /// Releases the native document.
  Future<void> close();
}

/// Opens the PDF at an already resolved [filePath]; null when the file does
/// not exist.
typedef PdfDocumentOpener = Future<PdfPageSource?> Function(String filePath);

/// Keeps PDF documents open across page thumbnail renders, so a sidebar of
/// N cells opens each file once instead of once per cell.
///
/// At most [maxOpen] documents stay open (least recently used is closed
/// first). Renders of one document run one at a time, because the native
/// renderer allows a single open page per document. After [close], renders
/// still work but open and close their document each time.
class PdfDocumentPool {
  PdfDocumentPool({PdfDocumentOpener? opener, this.maxOpen = 2})
      : assert(maxOpen > 0, 'maxOpen must be positive'),
        _opener = opener ?? openPdfxDocument;

  /// Maximum number of documents kept open.
  final int maxOpen;

  final PdfDocumentOpener _opener;

  /// Open documents by file path, least recently used first.
  final Map<String, _PooledDocument> _documents = <String, _PooledDocument>{};

  bool _closed = false;

  /// Number of documents currently held open.
  int get openCount => _documents.length;

  /// Renders page [pageNumber] of the PDF at the resolved [filePath] into a
  /// [width] x [height] pixel PNG. Null when the file does not exist.
  /// Throws when opening or rendering fails.
  Future<Uint8List?> renderPage(
    String filePath,
    int pageNumber, {
    required int width,
    required int height,
  }) async {
    if (_closed) {
      final oneShot = _PooledDocument(_opener(filePath));
      try {
        return await oneShot.render(pageNumber, width, height);
      } finally {
        await oneShot.close();
      }
    }

    // Move (or add) the document to the most recently used end.
    final document =
        _documents.remove(filePath) ?? _PooledDocument(_opener(filePath));
    _documents[filePath] = document;
    _evictOverflow();

    try {
      final bytes = await document.render(pageNumber, width, height);
      if (await document.isMissing) _forget(filePath, document);
      return bytes;
    } catch (_) {
      // A document that failed to open or render is not reused.
      _forget(filePath, document);
      rethrow;
    }
  }

  /// Closes every open document. Renders already running finish first.
  Future<void> close() async {
    _closed = true;
    final documents = _documents.values.toList();
    _documents.clear();
    await Future.wait([for (final d in documents) d.close()]);
  }

  void _evictOverflow() {
    while (_documents.length > maxOpen) {
      final oldest = _documents.keys.first;
      unawaited(_documents.remove(oldest)!.close());
    }
  }

  void _forget(String filePath, _PooledDocument document) {
    if (identical(_documents[filePath], document)) {
      _documents.remove(filePath);
      unawaited(document.close());
    }
  }
}

/// A document in the pool: opened once, renders serialised.
class _PooledDocument {
  _PooledDocument(this._source);

  final Future<PdfPageSource?> _source;
  Future<void> _tail = Future<void>.value();
  bool _isClosed = false;

  /// Whether the file did not exist (or failed to open).
  Future<bool> get isMissing async {
    try {
      return await _source == null;
    } catch (_) {
      return true;
    }
  }

  Future<Uint8List?> render(int pageNumber, int width, int height) {
    final result = _tail.then<Uint8List?>((_) async {
      final source = await _source;
      if (source == null) return null;
      return source.renderPage(pageNumber, width: width, height: height);
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _tail;
    try {
      await (await _source)?.close();
    } catch (_) {
      // Opening failed or the native document is already gone.
    }
  }
}

/// Default [PdfDocumentOpener] backed by pdfx.
Future<PdfPageSource?> openPdfxDocument(String filePath) async {
  if (!await File(filePath).exists()) return null;
  return _PdfxPageSource(await pdfx.PdfDocument.openFile(filePath));
}

class _PdfxPageSource implements PdfPageSource {
  _PdfxPageSource(this._document);

  final pdfx.PdfDocument _document;

  @override
  Future<Uint8List?> renderPage(
    int pageNumber, {
    required int width,
    required int height,
  }) async {
    final page = await _document.getPage(pageNumber);
    try {
      final image = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: pdfx.PdfPageImageFormat.png,
      );
      return image?.bytes;
    } finally {
      try {
        await page.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() => _document.close();
}

/// Renders page [pageIndex] of the PDF at [filePath] at [renderScale] times
/// its size in PDF points, opening and closing the document. Used by export,
/// whose resolution follows the export scale. Null when the file is missing.
Future<Uint8List?> renderPdfPageAtScale(
  String filePath,
  int pageIndex,
  double renderScale,
) async {
  if (!await File(filePath).exists()) return null;

  pdfx.PdfDocument? document;
  pdfx.PdfPage? pdfPage;
  try {
    document = await pdfx.PdfDocument.openFile(filePath);
    pdfPage = await document.getPage(pageIndex);
    final pageImage = await pdfPage.render(
      width: pdfPage.width * renderScale,
      height: pdfPage.height * renderScale,
      format: pdfx.PdfPageImageFormat.png,
    );
    return pageImage?.bytes;
  } finally {
    try {
      await pdfPage?.close();
    } catch (_) {}
    try {
      await document?.close();
    } catch (_) {}
  }
}

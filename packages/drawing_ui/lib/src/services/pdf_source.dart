import 'dart:io';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;

/// A source PDF opened once and kept for all of its pages in an export.
abstract class PdfSource {
  /// Renders page [index] as a JPEG, or null when it cannot be rendered.
  Future<Uint8List?> renderJpeg(int index, double scale);

  Future<void> close();
}

/// Opens the source PDF at a path; null when the file is missing/unreadable.
typedef PdfSourceOpener = Future<PdfSource?> Function(String path);

/// One [PdfSource] per path, opened lazily and closed after the export.
class PdfSourcePool {
  PdfSourcePool(this._open);

  final PdfSourceOpener _open;
  final _sources = <String, PdfSource?>{};

  Future<PdfSource?> get(String path) async {
    if (_sources.containsKey(path)) return _sources[path];
    return _sources[path] = await _open(path);
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

/// Default opener backed by pdfx.
Future<PdfSource?> openPdfxSource(String path) async {
  if (!await File(path).exists()) return null;
  return _PdfxSource(await pdfx.PdfDocument.openFile(path));
}

class _PdfxSource implements PdfSource {
  _PdfxSource(this._doc);

  final pdfx.PdfDocument _doc;

  @override
  Future<Uint8List?> renderJpeg(int index, double scale) async {
    pdfx.PdfPage? pg;
    try {
      pg = await _doc.getPage(index);
      final img = await pg.render(
        width: pg.width * scale,
        height: pg.height * scale,
        format: pdfx.PdfPageImageFormat.jpeg,
        quality: 90,
      );
      return img?.bytes;
    } finally {
      try {
        await pg?.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() => _doc.close();
}

import 'dart:typed_data';

import 'package:drawing_ui/src/services/pdf_document_pool.dart';

/// One recorded page render.
typedef FakePdfRender = ({String path, int page, int width, int height});

/// In-memory [PdfDocumentOpener] that counts opens, renders and closes.
class FakePdfDocuments {
  final Map<String, int> _opens = {};

  /// Every render, in order.
  final List<FakePdfRender> renders = [];

  /// Paths of documents closed, in order.
  final List<String> closedPaths = [];

  /// Paths that do not exist on "disk".
  final Set<String> missing = {};

  /// When set, renders wait for it.
  Future<void>? renderGate;

  /// When true, renders throw.
  bool failRender = false;

  /// Bytes every render returns (not a real image).
  Uint8List bytes = Uint8List.fromList([1, 2, 3]);

  int _running = 0;

  /// Most renders seen running at the same time.
  int maxConcurrentRenders = 0;

  /// How often [path] was opened.
  int openCount(String path) => _opens[path] ?? 0;

  /// The [PdfDocumentOpener].
  Future<PdfPageSource?> open(String path) async {
    _opens[path] = openCount(path) + 1;
    if (missing.contains(path)) return null;
    return _FakeSource(this, path);
  }
}

class _FakeSource implements PdfPageSource {
  _FakeSource(this._fake, this._path);

  final FakePdfDocuments _fake;
  final String _path;

  @override
  Future<Uint8List?> renderPage(
    int pageNumber, {
    required int width,
    required int height,
  }) async {
    _fake._running++;
    if (_fake._running > _fake.maxConcurrentRenders) {
      _fake.maxConcurrentRenders = _fake._running;
    }
    try {
      await (_fake.renderGate ?? Future<void>.delayed(Duration.zero));
      if (_fake.failRender) throw StateError('render failed');
      _fake.renders
          .add((path: _path, page: pageNumber, width: width, height: height));
      return _fake.bytes;
    } finally {
      _fake._running--;
    }
  }

  @override
  Future<void> close() async => _fake.closedPaths.add(_path);
}

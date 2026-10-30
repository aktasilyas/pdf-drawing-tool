import 'dart:async';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show
        ThumbnailGenerator,
        libraryPreviewMaxDpr,
        libraryPreviewTileWidth,
        pdfPathResolverProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/core.dart' show logger;
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Widest library tile (logical px) the stored preview must stay sharp at;
/// the same tile the PDF tile preview is rendered for.
const double libraryThumbnailTileWidth = libraryPreviewTileWidth;

/// Highest device pixel ratio the stored preview must stay sharp at.
const double libraryThumbnailMaxDpr = libraryPreviewMaxDpr;

/// Pixel size of the stored library preview for a page of [pageW] x [pageH].
///
/// The width is fixed; the height follows the page aspect ratio and is capped
/// so a very tall page cannot allocate a huge bitmap. A page without a usable
/// size gets a 3:4 preview.
({int width, int height}) libraryThumbnailPixels(double pageW, double pageH) {
  final width = (libraryThumbnailTileWidth * libraryThumbnailMaxDpr).ceil();
  if (!(pageW > 0) || !(pageH > 0)) return (width: width, height: 960);
  final height = (width * pageH / pageW).ceil().clamp(1, 2048).toInt();
  return (width: width, height: height);
}

/// Renders [page] to PNG bytes at [width] x [height] pixels; null on failure.
typedef ThumbnailRenderer = Future<Uint8List?> Function(
  Page page,
  int width,
  int height,
);

/// Keeps the library preview of a notebook in step with its first page.
///
/// After a successful save the editor calls [request]; the first page is
/// rendered and stored only when it is not the page instance recorded by
/// [baseline] or by the last write, so edits to other pages cost nothing.
/// The render waits for [idleDelay] without new requests, or for [flush]
/// when the editor closes, so drawing on the first page does not re-render
/// it after every autosave. Pending requests are coalesced (newest wins).
/// Legacy single-layer documents build new page views on every access and
/// so always count as changed; the idle delay bounds that cost.
/// Nothing here throws.
class LibraryThumbnailWriter {
  LibraryThumbnailWriter({
    required this.enabled,
    required this.repository,
    required this.render,
    this.onWritten,
    this.idleDelay = const Duration(seconds: 20),
  });

  final bool enabled;
  final DocumentRepository Function() repository;
  final ThumbnailRenderer render;
  final void Function()? onWritten;

  /// Quiet time after the last request before the render starts.
  /// [Duration.zero] starts it at once.
  final Duration idleDelay;

  /// Documents whose first page is remembered; older ones are forgotten so
  /// the pages (and their strokes) of every opened notebook are not kept.
  static const int maxRecorded = 8;

  /// First page last seen (opened or written) per document id.
  /// Insertion-ordered (map literal), so the first key is the oldest.
  final Map<String, Page> _recorded = {};
  final Map<String, DrawingDocument> _pending = {};
  Future<void>? _worker;
  Timer? _timer;

  /// Completes when no render or write is in flight.
  Future<void> get idle => _worker ?? Future<void>.value();

  /// Records the first page of [document] as already stored.
  void baseline(DrawingDocument document) {
    try {
      final pages = document.pages;
      if (pages.isEmpty) return;
      _record(document.id, pages.first);
    } catch (e) {
      logger.w('Thumbnail baseline failed', error: e);
    }
  }

  /// Stores a new preview when the first page of [document] changed.
  void request(DrawingDocument document) {
    try {
      if (!_wants(document)) return;
      _pending[document.id] = document;
      _timer?.cancel();
      if (idleDelay == Duration.zero) {
        _start();
      } else {
        _timer = Timer(idleDelay, _start);
      }
    } catch (e) {
      logger.w('Thumbnail request failed', error: e);
    }
  }

  /// Starts pending renders now (the editor is closing) and completes when
  /// they are stored.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    _start();
    return idle;
  }

  void _start() {
    if (_pending.isEmpty) return;
    _worker ??= _drain();
  }

  void _record(String id, Page page) {
    _recorded.remove(id);
    _recorded[id] = page;
    while (_recorded.length > maxRecorded) {
      _recorded.remove(_recorded.keys.first);
    }
  }

  bool _wants(DrawingDocument document) {
    if (!enabled) return false;
    final pages = document.pages;
    if (pages.isEmpty) return false;
    final first = pages.first;
    if (first.isCover) return false;
    return !identical(first, _recorded[document.id]);
  }

  Future<void> _drain() async {
    try {
      while (_pending.isNotEmpty) {
        final id = _pending.keys.first;
        final document = _pending.remove(id)!;
        await _write(document);
      }
    } finally {
      _worker = null;
    }
  }

  Future<void> _write(DrawingDocument document) async {
    try {
      if (!_wants(document)) return;
      final page = document.pages.first;
      final size = libraryThumbnailPixels(page.size.width, page.size.height);
      final bytes = await render(page, size.width, size.height);
      if (bytes == null) return;
      final result = await repository().saveThumbnail(document.id, bytes);
      final saved = result.fold((_) => false, (_) => true);
      if (!saved) return;
      _record(document.id, page);
      onWritten?.call();
    } catch (e, st) {
      logger.w('Library thumbnail write failed', error: e, stackTrace: st);
    }
  }
}

/// The editor's library-preview writer. Disabled when the app documents root
/// is unknown (tests), so the repository is never touched there.
final libraryThumbnailWriterProvider = Provider<LibraryThumbnailWriter>((ref) {
  final paths = ref.watch(pdfPathResolverProvider);
  return LibraryThumbnailWriter(
    enabled: paths.documentsRoot?.isNotEmpty == true,
    repository: () => ref.read(documentRepositoryProvider),
    render: (page, width, height) => ThumbnailGenerator.generate(
      page,
      width: width.toDouble(),
      height: height.toDouble(),
      pdfPaths: paths,
    ),
    onWritten: () {
      ref.invalidate(documentsProvider);
      ref.invalidate(favoriteDocumentsProvider);
      ref.invalidate(recentDocumentsProvider);
    },
  );
});

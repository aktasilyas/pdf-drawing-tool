part of 'document.dart';

/// Derived read-only views of a [DrawingDocument] (pages, layers, counts).
///
/// A `part` of `document.dart` so it can read the private storage fields.
mixin _DocumentViews {
  // Storage and identity, implemented by the fields of [DrawingDocument].
  String get id;
  String get title;
  List<Page>? get _pages;
  List<Layer>? get _layers;
  int? get _currentPageIndex;
  int? get _activeLayerIndex;
  DocumentSettings? get _settings;
  double? get _width;
  double? get _height;
  DocumentType get documentType;
  List<AudioRecording> get audioRecordings;
  DateTime get createdAt;
  DateTime get updatedAt;

  DrawingDocument get _self => this as DrawingDocument;

  /// Implemented by [DrawingDocument]; declared here for the other mixins.
  DrawingDocument copyWith({
    String? id,
    String? title,
    List<Layer>? layers,
    int? activeLayerIndex,
    List<Page>? pages,
    int? currentPageIndex,
    DocumentSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? width,
    double? height,
    DocumentType? documentType,
    List<AudioRecording>? audioRecordings,
  });

  /// The pages in this document (V2).
  ///
  /// For V1 documents, returns a single page containing all layers.
  List<Page> get pages {
    if (_pages != null) return _pages!;

    // V1 compatibility: convert layers to a single page
    final size = PageSize(
      width: _width ?? 1920.0,
      height: _height ?? 1080.0,
      preset: PagePreset.custom,
    );
    return [
      Page(
        id: 'page_0',
        index: 0,
        size: size,
        background: PageBackground.blank,
        layers: _layers ?? [],
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    ];
  }

  /// Current page index.
  int get currentPageIndex => _currentPageIndex ?? 0;

  /// Document settings.
  DocumentSettings get settings => _settings ?? DocumentSettings.defaults();

  /// Canvas mode (based on document type).
  CanvasMode get canvasMode => CanvasMode.fromDocumentType(documentType);

  /// Is this an infinite canvas document?
  bool get isInfiniteCanvas => documentType.isInfiniteCanvas;

  /// The layers in the current page.
  ///
  /// **Deprecated for V2:** Use `pages[currentPageIndex].layers` instead.
  List<Layer> get layers {
    if (_layers != null) return _layers!; // V1
    return pages.isNotEmpty ? pages[currentPageIndex].layers : []; // V2
  }

  /// The index of the currently active layer.
  ///
  /// **Deprecated for V2:** Access through page.
  int get activeLayerIndex => _activeLayerIndex ?? 0;

  /// The width of the current page.
  ///
  /// **Deprecated for V2:** Use `pages[currentPageIndex].size.width` instead.
  double get width {
    if (_width != null) return _width!; // V1
    return pages.isNotEmpty ? pages[currentPageIndex].size.width : 1920.0; // V2
  }

  /// The height of the current page.
  ///
  /// **Deprecated for V2:** Use `pages[currentPageIndex].size.height` instead.
  double get height {
    if (_height != null) return _height!; // V1
    return pages.isNotEmpty
        ? pages[currentPageIndex].size.height
        : 1080.0; // V2
  }

  /// The currently active page.
  Page? get currentPage {
    final pageList = pages;
    if (currentPageIndex >= 0 && currentPageIndex < pageList.length) {
      return pageList[currentPageIndex];
    }
    return null;
  }

  /// The currently active layer.
  Layer? get activeLayer {
    final layerList = layers;
    if (activeLayerIndex >= 0 && activeLayerIndex < layerList.length) {
      return layerList[activeLayerIndex];
    }
    return null;
  }

  /// The number of pages in this document.
  int get pageCount => pages.length;

  /// The number of layers in the current page.
  int get layerCount => layers.length;

  /// The total number of strokes across all pages and layers.
  int get strokeCount {
    int count = 0;
    for (final page in pages) {
      count += page.strokeCount;
    }
    return count;
  }

  /// Whether this document has no strokes.
  bool get isEmpty => strokeCount == 0;

  /// Whether this document has at least one stroke.
  bool get isNotEmpty => !isEmpty;

  /// Whether this is a V2 multi-page document.
  bool get isMultiPage => _pages != null;
}

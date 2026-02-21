import 'package:equatable/equatable.dart';

import 'package:drawing_core/src/models/audio_recording.dart';
import 'package:drawing_core/src/models/canvas_mode.dart';
import 'package:drawing_core/src/models/document_settings.dart';
import 'package:drawing_core/src/models/document_type.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/page.dart';
import 'package:drawing_core/src/models/page_background.dart';
import 'package:drawing_core/src/models/page_size.dart';
import 'package:drawing_core/src/models/stroke.dart';

/// Represents a complete drawing document.
///
/// A [DrawingDocument] contains multiple [Page]s (V2) or [Layer]s (V1 legacy).
/// It manages the active page and layers, and tracks document metadata.
///
/// This class is immutable - all modification methods return a new [DrawingDocument].
///
/// **V2 Multi-Page Support:**
/// - Use [DrawingDocument.multiPage] constructor for multi-page documents
/// - V1 single-page documents are automatically supported for backward compatibility
class DrawingDocument extends Equatable {
  /// Unique identifier for the document.
  final String id;

  /// Display title of the document.
  final String title;

  /// Internal: Pages storage (V2).
  final List<Page>? _pages;

  /// Internal: Layers storage (V1 legacy).
  final List<Layer>? _layers;

  /// Current page index (V2 only).
  final int? _currentPageIndex;

  /// Active layer index (V1 legacy).
  final int? _activeLayerIndex;

  /// Document settings (V2).
  final DocumentSettings? _settings;

  /// Page width (V1 legacy).
  final double? _width;

  /// Page height (V1 legacy).
  final double? _height;

  /// Document type (notebook, whiteboard, etc.)
  final DocumentType documentType;

  /// Audio recordings attached to this document.
  final List<AudioRecording> audioRecordings;

  /// When this document was created.
  final DateTime createdAt;

  /// When this document was last modified.
  final DateTime updatedAt;

  // ========== PUBLIC GETTERS ==========

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

  // ========== CONSTRUCTORS ==========

  /// Creates a new [DrawingDocument] (V1 legacy format).
  ///
  /// **Deprecated:** Use [DrawingDocument.multiPage] for multi-page documents.
  @Deprecated('Use DrawingDocument.multiPage() for new documents')
  DrawingDocument({
    required this.id,
    required this.title,
    required List<Layer> layers,
    int activeLayerIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    double width = 1920.0,
    double height = 1080.0,
    this.documentType = DocumentType.notebook,
    List<AudioRecording>? audioRecordings,
  })  : _layers = List.unmodifiable(layers),
        _activeLayerIndex = activeLayerIndex,
        _width = width,
        _height = height,
        _pages = null,
        _currentPageIndex = null,
        _settings = null,
        audioRecordings = audioRecordings != null
            ? List.unmodifiable(audioRecordings)
            : const [];

  /// Creates a multi-page [DrawingDocument] (V2).
  DrawingDocument.multiPage({
    required this.id,
    required this.title,
    required List<Page> pages,
    int currentPageIndex = 0,
    int activeLayerIndex = 0,
    DocumentSettings? settings,
    required this.createdAt,
    required this.updatedAt,
    this.documentType = DocumentType.notebook,
    List<AudioRecording>? audioRecordings,
  })  : _pages = List.unmodifiable(pages),
        _currentPageIndex = currentPageIndex,
        _settings = settings ?? DocumentSettings.defaults(),
        _layers = null,
        _activeLayerIndex = activeLayerIndex,
        _width = null,
        _height = null,
        audioRecordings = audioRecordings != null
            ? List.unmodifiable(audioRecordings)
            : const [];

  /// Creates an empty document with a single empty layer (V1).
  ///
  /// **Deprecated:** Use [emptyMultiPage] for V2 multi-page support.
  @Deprecated('Use emptyMultiPage() for V2 documents')
  factory DrawingDocument.empty(
    String title, {
    double? width,
    double? height,
    DocumentType documentType = DocumentType.notebook,
  }) {
    final now = DateTime.now();
    return DrawingDocument(
      id: _generateId(),
      title: title,
      layers: [Layer.empty('Katman 1')],
      activeLayerIndex: 0,
      createdAt: now,
      updatedAt: now,
      width: width ?? 1920.0,
      height: height ?? 1080.0,
      documentType: documentType,
    );
  }

  /// Creates an empty multi-page document (V2).
  factory DrawingDocument.emptyMultiPage(
    String title, {
    PageSize? pageSize,
    PageBackground? background,
    DocumentSettings? settings,
    DocumentType documentType = DocumentType.notebook,
  }) {
    final now = DateTime.now();
    final defaultSettings = settings ?? DocumentSettings.defaults();

    return DrawingDocument.multiPage(
      id: _generateId(),
      title: title,
      pages: [
        Page.create(
          index: 0,
          size: pageSize ?? defaultSettings.defaultPageSize,
          background: background ?? defaultSettings.defaultBackground,
        ),
      ],
      currentPageIndex: 0,
      settings: defaultSettings,
      createdAt: now,
      updatedAt: now,
      documentType: documentType,
    );
  }

  /// Creates a document with the given layers (V1).
  factory DrawingDocument.withLayers(
    String title,
    List<Layer> layers, {
    double? width,
    double? height,
    DocumentType documentType = DocumentType.notebook,
  }) {
    final now = DateTime.now();
    return DrawingDocument(
      id: _generateId(),
      title: title,
      layers: layers.isEmpty ? [Layer.empty('Katman 1')] : layers,
      activeLayerIndex: 0,
      createdAt: now,
      updatedAt: now,
      width: width ?? 1920.0,
      height: height ?? 1080.0,
      documentType: documentType,
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return 'doc_${DateTime.now().microsecondsSinceEpoch}';
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

  /// Returns a new [DrawingDocument] with the given layer added.
  ///
  /// The new layer is added at the top and becomes the active layer.
  DrawingDocument addLayer(Layer layer) {
    if (isMultiPage) {
      // V2: Add to current page
      final current = currentPage;
      if (current == null) return this;

      final newLayers = [...current.layers, layer];
      final updatedPage = current.copyWith(layers: newLayers);

      final newPages = List<Page>.from(pages);
      newPages[currentPageIndex] = updatedPage;

      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: newPages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: newLayers.length - 1,
        settings: settings,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      return DrawingDocument(
        id: id,
        title: title,
        layers: [...layers, layer],
        activeLayerIndex: activeLayerIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the layer at [index] removed.
  ///
  /// If removing would leave no layers, returns unchanged.
  DrawingDocument removeLayer(int index) {
    if (index < 0 || index >= layers.length || layers.length <= 1) {
      return copyWith(updatedAt: DateTime.now());
    }

    if (isMultiPage) {
      // V2: Remove from current page
      final current = currentPage;
      if (current == null) return copyWith(updatedAt: DateTime.now());

      final newLayers = List<Layer>.from(current.layers)..removeAt(index);
      final updatedPage = current.copyWith(layers: newLayers);

      // Adjust activeLayerIndex if needed
      int newActiveIndex = activeLayerIndex;
      if (activeLayerIndex >= newLayers.length) {
        newActiveIndex = newLayers.length - 1;
      } else if (activeLayerIndex > index) {
        newActiveIndex = activeLayerIndex - 1;
      }

      final newPages = List<Page>.from(pages);
      newPages[currentPageIndex] = updatedPage;

      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: newPages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: newActiveIndex,
        settings: settings,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      final newLayers = List<Layer>.from(layers)..removeAt(index);

      // Adjust activeLayerIndex if needed
      int newActiveIndex = activeLayerIndex;
      if (activeLayerIndex >= newLayers.length) {
        newActiveIndex = newLayers.length - 1;
      } else if (activeLayerIndex > index) {
        newActiveIndex = activeLayerIndex - 1;
      }

      return DrawingDocument(
        id: id,
        title: title,
        layers: newLayers,
        activeLayerIndex: newActiveIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the layer at [index] updated.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument updateLayer(int index, Layer layer) {
    if (index < 0 || index >= layers.length) {
      return copyWith(updatedAt: DateTime.now());
    }

    if (isMultiPage) {
      // V2: Update in current page
      final current = currentPage;
      if (current == null) return copyWith(updatedAt: DateTime.now());

      final newLayers = List<Layer>.from(current.layers);
      newLayers[index] = layer;

      final updatedPage = current.copyWith(layers: newLayers);
      return _updatePageV2(currentPageIndex, updatedPage);
    } else {
      // V1: Legacy
      final newLayers = List<Layer>.from(layers);
      newLayers[index] = layer;

      return DrawingDocument(
        id: id,
        title: title,
        layers: newLayers,
        activeLayerIndex: activeLayerIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the active layer changed.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument setActiveLayer(int index) {
    if (index < 0 || index >= layers.length) {
      return this;
    }

    if (isMultiPage) {
      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: pages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: index,
        settings: settings,
        createdAt: createdAt,
        updatedAt: updatedAt,
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      return DrawingDocument(
        id: id,
        title: title,
        layers: layers,
        activeLayerIndex: index,
        createdAt: createdAt,
        updatedAt: updatedAt,
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the stroke added to the active layer.
  ///
  /// If there's no valid active layer, returns unchanged.
  DrawingDocument addStrokeToActiveLayer(Stroke stroke) {
    final active = activeLayer;
    if (active == null) {
      return this;
    }

    final updatedLayer = active.addStroke(stroke);
    return updateLayer(activeLayerIndex, updatedLayer);
  }

  /// Returns a new [DrawingDocument] with the stroke removed from the active layer.
  ///
  /// If there's no valid active layer, returns unchanged.
  DrawingDocument removeStrokeFromActiveLayer(String strokeId) {
    final active = activeLayer;
    if (active == null) {
      return this;
    }

    final updatedLayer = active.removeStroke(strokeId);
    return updateLayer(activeLayerIndex, updatedLayer);
  }

  /// Returns a new [DrawingDocument] with the title updated.
  DrawingDocument updateTitle(String newTitle) {
    return copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
  }

  // ========== V2 PAGE OPERATIONS ==========

  /// Add a new page (V2 only).
  DrawingDocument addPage(Page page) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'addPage() is only supported for V2 multi-page documents');
    }

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: [...pages, page],
      currentPageIndex: currentPageIndex,
      activeLayerIndex: activeLayerIndex,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Remove a page (V2 only).
  DrawingDocument removePage(int pageIndex) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'removePage() is only supported for V2 multi-page documents');
    }

    if (pageIndex < 0 || pageIndex >= pages.length || pages.length <= 1) {
      return this;
    }

    final newPages = List<Page>.from(pages)..removeAt(pageIndex);

    // Adjust currentPageIndex if needed
    int newCurrentIndex = currentPageIndex;
    if (currentPageIndex >= newPages.length) {
      newCurrentIndex = newPages.length - 1;
    } else if (currentPageIndex > pageIndex) {
      newCurrentIndex = currentPageIndex - 1;
    }

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: newPages,
      currentPageIndex: newCurrentIndex,
      activeLayerIndex: activeLayerIndex,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Set the current page (V2 only).
  ///
  /// Resets activeLayerIndex to 0 when switching pages.
  DrawingDocument setCurrentPage(int pageIndex) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'setCurrentPage() is only supported for V2 multi-page documents');
    }

    if (pageIndex < 0 || pageIndex >= pages.length) {
      return this;
    }

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: pages,
      currentPageIndex: pageIndex,
      activeLayerIndex: 0,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Helper: Update a page in V2 document.
  DrawingDocument _updatePageV2(int pageIndex, Page updatedPage) {
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return this;
    }

    final newPages = List<Page>.from(pages);
    newPages[pageIndex] = updatedPage;

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: newPages,
      currentPageIndex: currentPageIndex,
      activeLayerIndex: activeLayerIndex,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  // ========== AUDIO RECORDING OPERATIONS ==========

  /// Add an audio recording to this document.
  DrawingDocument addAudioRecording(AudioRecording recording) {
    return copyWith(
      audioRecordings: [...audioRecordings, recording],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove an audio recording by ID.
  DrawingDocument removeAudioRecording(String recordingId) {
    return copyWith(
      audioRecordings:
          audioRecordings.where((r) => r.id != recordingId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update an audio recording by ID.
  DrawingDocument updateAudioRecording(
      String recordingId, AudioRecording updated) {
    return copyWith(
      audioRecordings: audioRecordings
          .map((r) => r.id == recordingId ? updated : r)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy of this [DrawingDocument] with the given fields replaced.
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
  }) {
    if (isMultiPage) {
      // V2: Copy as multi-page
      return DrawingDocument.multiPage(
        id: id ?? this.id,
        title: title ?? this.title,
        pages: pages ?? this.pages,
        currentPageIndex: currentPageIndex ?? this.currentPageIndex,
        activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
        settings: settings ?? this.settings,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        documentType: documentType ?? this.documentType,
        audioRecordings: audioRecordings ?? this.audioRecordings,
      );
    } else {
      // V1: Copy as legacy
      return DrawingDocument(
        id: id ?? this.id,
        title: title ?? this.title,
        layers: layers ?? this.layers,
        activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        width: width ?? this.width,
        height: height ?? this.height,
        documentType: documentType ?? this.documentType,
        audioRecordings: audioRecordings ?? this.audioRecordings,
      );
    }
  }

  /// Converts this [DrawingDocument] to a JSON map.
  Map<String, dynamic> toJson() {
    if (isMultiPage) {
      // V2: Multi-page format
      return {
        'version': 2,
        'id': id,
        'title': title,
        'pages': pages.map((p) => p.toJson()).toList(),
        'currentPageIndex': currentPageIndex,
        'activeLayerIndex': activeLayerIndex,
        'settings': settings.toJson(),
        'documentType': documentType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (audioRecordings.isNotEmpty)
          'audioRecordings':
              audioRecordings.map((r) => r.toJson()).toList(),
      };
    } else {
      // V1: Legacy format (no version for backward compat)
      return {
        'id': id,
        'title': title,
        'layers': layers.map((l) => l.toJson()).toList(),
        'activeLayerIndex': activeLayerIndex,
        'documentType': documentType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'width': width,
        'height': height,
      };
    }
  }

  /// Creates a [DrawingDocument] from a JSON map.
  ///
  /// Supports both V1 (legacy) and V2 (multi-page) formats.
  factory DrawingDocument.fromJson(Map<String, dynamic> json) {
    // Version detection with safe parsing
    final version = _parseVersion(json['version']) ?? 1;

    // Parse documentType (with fallback to notebook for backward compatibility)
    final documentType = json.containsKey('documentType')
        ? DocumentType.values.firstWhere(
            (e) => e.name == json['documentType'],
            orElse: () => DocumentType.notebook,
          )
        : DocumentType.notebook;

    // V2: Has version >= 2 AND pages field
    if (version >= 2 && json.containsKey('pages')) {
      return DrawingDocument.multiPage(
        id: json['id'] as String,
        title: json['title'] as String,
        pages: (json['pages'] as List)
            .map((p) => Page.fromJson(p as Map<String, dynamic>))
            .toList(),
        currentPageIndex: _parseInt(json['currentPageIndex']) ?? 0,
        activeLayerIndex: _parseInt(json['activeLayerIndex']) ?? 0,
        settings: json.containsKey('settings')
            ? DocumentSettings.fromJson(
                json['settings'] as Map<String, dynamic>)
            : DocumentSettings.defaults(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        documentType: documentType,
        audioRecordings: (json['audioRecordings'] as List?)
            ?.map(
                (r) => AudioRecording.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    }

    // V1: Legacy format with layers
    return DrawingDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      activeLayerIndex: _parseInt(json['activeLayerIndex']) ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      width: _parseDouble(json['width']) ?? 1920.0,
      height: _parseDouble(json['height']) ?? 1080.0,
      documentType: documentType,
    );
  }

  /// Safe version parsing
  static int? _parseVersion(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  /// Safe int parsing
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  /// Safe double parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        _pages,
        _layers,
        _currentPageIndex,
        _activeLayerIndex,
        _settings,
        _width,
        _height,
        documentType,
        audioRecordings,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    if (isMultiPage) {
      return 'DrawingDocument(id: $id, title: $title, pageCount: $pageCount, '
          'currentPageIndex: $currentPageIndex, strokeCount: $strokeCount)';
    } else {
      return 'DrawingDocument(id: $id, title: $title, layerCount: $layerCount, '
          'strokeCount: $strokeCount, activeLayerIndex: $activeLayerIndex, '
          'size: ${width}x$height)';
    }
  }
}

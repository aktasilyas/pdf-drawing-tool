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

part 'document_json.dart';
part 'document_layer_ops.dart';
part 'document_v2_ops.dart';
part 'document_views.dart';

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
class DrawingDocument extends Equatable
    with _DocumentViews, _DocumentV2Ops, _DocumentLayerOps, _DocumentJson {
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

  /// Creates a copy of this [DrawingDocument] with the given fields replaced.
  ///
  /// For multi-page (V2) documents, [layers], [width] and [height] live on the
  /// [Page]s and cannot be set here; passing them throws an [ArgumentError].
  /// Update the page instead, e.g.
  /// `doc.copyWith(pages: [...pages]..[i] = page.copyWith(layers: layers))`.
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
      if (layers != null || width != null || height != null) {
        throw ArgumentError(
          'layers, width and height are ignored on multi-page documents; '
          'update the Page (page.copyWith(layers: ...)) and pass pages: '
          'instead.',
        );
      }
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

  /// Creates a [DrawingDocument] from a JSON map.
  ///
  /// Supports both V1 (legacy) and V2 (multi-page) formats.
  factory DrawingDocument.fromJson(Map<String, dynamic> json) =>
      _documentFromJson(json);

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

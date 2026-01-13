import 'package:equatable/equatable.dart';

import 'layer.dart';
import 'stroke.dart';

/// Represents a complete drawing document.
///
/// A [DrawingDocument] contains multiple [Layer]s and manages the active layer.
/// It also tracks document metadata like title, dimensions, and timestamps.
///
/// This class is immutable - all modification methods return a new [DrawingDocument].
class DrawingDocument extends Equatable {
  /// Unique identifier for the document.
  final String id;

  /// Display title of the document.
  final String title;

  /// The layers in this document.
  ///
  /// This list is unmodifiable.
  final List<Layer> layers;

  /// The index of the currently active layer.
  final int activeLayerIndex;

  /// When this document was created.
  final DateTime createdAt;

  /// When this document was last modified.
  final DateTime updatedAt;

  /// The width of the canvas in logical pixels.
  final double width;

  /// The height of the canvas in logical pixels.
  final double height;

  /// Creates a new [DrawingDocument].
  ///
  /// The [layers] list is wrapped in [List.unmodifiable] to ensure immutability.
  DrawingDocument({
    required this.id,
    required this.title,
    required List<Layer> layers,
    this.activeLayerIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.width = 1920.0,
    this.height = 1080.0,
  }) : layers = List.unmodifiable(layers);

  /// Creates an empty document with a single empty layer.
  factory DrawingDocument.empty(
    String title, {
    double? width,
    double? height,
  }) {
    final now = DateTime.now();
    return DrawingDocument(
      id: _generateId(),
      title: title,
      layers: [Layer.empty('Layer 1')],
      activeLayerIndex: 0,
      createdAt: now,
      updatedAt: now,
      width: width ?? 1920.0,
      height: height ?? 1080.0,
    );
  }

  /// Creates a document with the given layers.
  factory DrawingDocument.withLayers(
    String title,
    List<Layer> layers, {
    double? width,
    double? height,
  }) {
    final now = DateTime.now();
    return DrawingDocument(
      id: _generateId(),
      title: title,
      layers: layers.isEmpty ? [Layer.empty('Layer 1')] : layers,
      activeLayerIndex: 0,
      createdAt: now,
      updatedAt: now,
      width: width ?? 1920.0,
      height: height ?? 1080.0,
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return 'doc_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// The currently active layer, or null if the index is invalid.
  Layer? get activeLayer {
    if (activeLayerIndex >= 0 && activeLayerIndex < layers.length) {
      return layers[activeLayerIndex];
    }
    return null;
  }

  /// The number of layers in this document.
  int get layerCount => layers.length;

  /// The total number of strokes across all layers.
  int get strokeCount {
    int count = 0;
    for (final layer in layers) {
      count += layer.strokeCount;
    }
    return count;
  }

  /// Whether this document has no strokes in any layer.
  bool get isEmpty => strokeCount == 0;

  /// Whether this document has at least one stroke.
  bool get isNotEmpty => !isEmpty;

  /// Returns a new [DrawingDocument] with the given layer added.
  DrawingDocument addLayer(Layer layer) {
    return DrawingDocument(
      id: id,
      title: title,
      layers: [...layers, layer],
      activeLayerIndex: activeLayerIndex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      width: width,
      height: height,
    );
  }

  /// Returns a new [DrawingDocument] with the layer at [index] removed.
  ///
  /// If removing would leave no layers, returns unchanged.
  /// Adjusts [activeLayerIndex] if necessary.
  DrawingDocument removeLayer(int index) {
    if (index < 0 || index >= layers.length || layers.length <= 1) {
      return copyWith(updatedAt: DateTime.now());
    }

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
    );
  }

  /// Returns a new [DrawingDocument] with the layer at [index] updated.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument updateLayer(int index, Layer layer) {
    if (index < 0 || index >= layers.length) {
      return copyWith(updatedAt: DateTime.now());
    }

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
    );
  }

  /// Returns a new [DrawingDocument] with the active layer changed.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument setActiveLayer(int index) {
    if (index < 0 || index >= layers.length) {
      return this;
    }

    return DrawingDocument(
      id: id,
      title: title,
      layers: layers,
      activeLayerIndex: index,
      createdAt: createdAt,
      updatedAt: updatedAt, // Don't update for just changing active layer
      width: width,
      height: height,
    );
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
    return DrawingDocument(
      id: id,
      title: newTitle,
      layers: layers,
      activeLayerIndex: activeLayerIndex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      width: width,
      height: height,
    );
  }

  /// Creates a copy of this [DrawingDocument] with the given fields replaced.
  DrawingDocument copyWith({
    String? id,
    String? title,
    List<Layer>? layers,
    int? activeLayerIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? width,
    double? height,
  }) {
    return DrawingDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      layers: layers ?? this.layers,
      activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Converts this [DrawingDocument] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'layers': layers.map((l) => l.toJson()).toList(),
      'activeLayerIndex': activeLayerIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'width': width,
      'height': height,
    };
  }

  /// Creates a [DrawingDocument] from a JSON map.
  factory DrawingDocument.fromJson(Map<String, dynamic> json) {
    return DrawingDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      activeLayerIndex: json['activeLayerIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 1920.0,
      height: (json['height'] as num?)?.toDouble() ?? 1080.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        layers,
        activeLayerIndex,
        createdAt,
        updatedAt,
        width,
        height,
      ];

  @override
  String toString() {
    return 'DrawingDocument(id: $id, title: $title, layerCount: $layerCount, '
        'strokeCount: $strokeCount, activeLayerIndex: $activeLayerIndex, '
        'size: ${width}x$height)';
  }
}

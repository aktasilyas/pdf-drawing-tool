import 'dart:ui' show Rect, Size, Color;
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'layer.dart';
import 'stroke.dart';

/// Represents a complete drawing document.
///
/// A document contains multiple [Layer]s, each with their own strokes.
/// It also holds metadata like title, creation date, and canvas size.
///
/// ## Example
///
/// ```dart
/// final document = DrawingDocument(
///   title: 'My Drawing',
///   size: Size(1920, 1080),
///   layers: [
///     Layer(name: 'Background', strokes: []),
///     Layer(name: 'Sketch', strokes: [stroke1, stroke2]),
///   ],
/// );
/// ```
class DrawingDocument extends Equatable {
  /// Creates a new drawing document.
  ///
  /// If [id] is not provided, a UUID will be generated.
  /// If [layers] is not provided, a single empty layer is created.
  DrawingDocument({
    String? id,
    this.title = 'Untitled',
    this.size = const Size(1920, 1080),
    List<Layer>? layers,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.activeLayerIndex = 0,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        layers = layers ?? [Layer(name: 'Layer 1')],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Creates an empty document with a single layer.
  factory DrawingDocument.empty({
    Size size = const Size(1920, 1080),
    Color backgroundColor = const Color(0xFFFFFFFF),
  }) {
    return DrawingDocument(
      title: 'Untitled',
      size: size,
      backgroundColor: backgroundColor,
      layers: [Layer(name: 'Layer 1')],
    );
  }

  /// Unique identifier for this document.
  final String id;

  /// The title of this document.
  final String title;

  /// The canvas size of this document.
  final Size size;

  /// The layers in this document.
  final List<Layer> layers;

  /// The background color of the canvas.
  final Color backgroundColor;

  /// The index of the currently active layer.
  final int activeLayerIndex;

  /// When this document was created.
  final DateTime createdAt;

  /// When this document was last modified.
  final DateTime modifiedAt;

  /// Returns the currently active layer.
  Layer get activeLayer => layers[activeLayerIndex];

  /// Returns the total number of strokes across all layers.
  int get totalStrokeCount =>
      layers.fold(0, (sum, layer) => sum + layer.strokeCount);

  /// Returns the bounding box containing all content.
  Rect get contentBounds {
    if (layers.isEmpty) return Rect.zero;

    Rect? bounds;
    for (final layer in layers) {
      if (layer.isNotEmpty) {
        if (bounds == null) {
          bounds = layer.boundingBox;
        } else {
          bounds = bounds.expandToInclude(layer.boundingBox);
        }
      }
    }
    return bounds ?? Rect.zero;
  }

  /// Creates a copy with the given fields replaced.
  DrawingDocument copyWith({
    String? id,
    String? title,
    Size? size,
    List<Layer>? layers,
    Color? backgroundColor,
    int? activeLayerIndex,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DrawingDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      size: size ?? this.size,
      layers: layers ?? List.of(this.layers),
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  /// Creates a copy with a stroke added to the active layer.
  DrawingDocument addStrokeToActiveLayer(Stroke stroke) {
    final newLayers = List.of(layers);
    newLayers[activeLayerIndex] = activeLayer.addStroke(stroke);
    return copyWith(layers: newLayers);
  }

  /// Creates a copy with a stroke added to the specified layer.
  DrawingDocument addStrokeToLayer(int layerIndex, Stroke stroke) {
    if (layerIndex < 0 || layerIndex >= layers.length) {
      throw RangeError.index(layerIndex, layers, 'layerIndex');
    }
    final newLayers = List.of(layers);
    newLayers[layerIndex] = layers[layerIndex].addStroke(stroke);
    return copyWith(layers: newLayers);
  }

  /// Creates a copy with a new layer added.
  DrawingDocument addLayer({String? name, int? atIndex}) {
    final newLayer = Layer(name: name ?? 'Layer ${layers.length + 1}');
    final newLayers = List.of(layers);
    final index = atIndex ?? layers.length;
    newLayers.insert(index, newLayer);
    return copyWith(
      layers: newLayers,
      activeLayerIndex: index,
    );
  }

  /// Creates a copy with the layer at [index] removed.
  DrawingDocument removeLayer(int index) {
    if (layers.length <= 1) {
      throw StateError('Cannot remove the last layer');
    }
    final newLayers = List.of(layers)..removeAt(index);
    var newActiveIndex = activeLayerIndex;
    if (activeLayerIndex >= newLayers.length) {
      newActiveIndex = newLayers.length - 1;
    }
    return copyWith(
      layers: newLayers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Creates a copy with the layer at [index] updated.
  DrawingDocument updateLayer(int index, Layer layer) {
    final newLayers = List.of(layers);
    newLayers[index] = layer;
    return copyWith(layers: newLayers);
  }

  /// Creates a copy with layers reordered.
  DrawingDocument reorderLayers(int oldIndex, int newIndex) {
    final newLayers = List.of(layers);
    final layer = newLayers.removeAt(oldIndex);
    newLayers.insert(newIndex, layer);

    // Adjust active layer index
    var newActiveIndex = activeLayerIndex;
    if (activeLayerIndex == oldIndex) {
      newActiveIndex = newIndex;
    } else if (oldIndex < activeLayerIndex && newIndex >= activeLayerIndex) {
      newActiveIndex--;
    } else if (oldIndex > activeLayerIndex && newIndex <= activeLayerIndex) {
      newActiveIndex++;
    }

    return copyWith(
      layers: newLayers,
      activeLayerIndex: newActiveIndex,
    );
  }

  /// Converts this document to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'size': {'width': size.width, 'height': size.height},
      'layers': layers.map((l) => l.toJson()).toList(),
      'backgroundColor': backgroundColor.value,
      'activeLayerIndex': activeLayerIndex,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Creates a document from a JSON map.
  factory DrawingDocument.fromJson(Map<String, dynamic> json) {
    final sizeJson = json['size'] as Map<String, dynamic>;
    return DrawingDocument(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      size: Size(
        (sizeJson['width'] as num).toDouble(),
        (sizeJson['height'] as num).toDouble(),
      ),
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFFFFFFF),
      activeLayerIndex: json['activeLayerIndex'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        size,
        layers,
        backgroundColor,
        activeLayerIndex,
        createdAt,
        modifiedAt,
      ];

  @override
  String toString() =>
      'DrawingDocument(id: $id, title: $title, layers: ${layers.length}, strokes: $totalStrokeCount)';
}

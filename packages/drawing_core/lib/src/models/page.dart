import 'dart:typed_data';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/page_background.dart';
import 'package:drawing_core/src/models/page_size.dart';
import 'package:drawing_core/src/models/stroke.dart';

/// Tek bir sayfa modeli
class Page {
  final String id;
  final int index;
  final PageSize size;
  final PageBackground background;
  final List<Layer> layers;
  final Uint8List? thumbnail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCover; // Flag for cover pages (drawings not saved)
  final bool isBookmarked;

  const Page({
    required this.id,
    required this.index,
    required this.size,
    this.background = const PageBackground(type: BackgroundType.blank),
    this.layers = const [],
    this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
    this.isCover = false,
    this.isBookmarked = false,
  });

  /// Factory for creating new page
  factory Page.create({
    required int index,
    PageSize? size,
    PageBackground? background,
    bool isCover = false,
  }) {
    final now = DateTime.now();
    return Page(
      id: 'page_${now.millisecondsSinceEpoch}_$index',
      index: index,
      size: size ?? PageSize.a4Portrait,
      background: background ?? PageBackground.blank,
      layers: [Layer.empty('Katman 1')], // Default empty layer
      createdAt: now,
      updatedAt: now,
      isCover: isCover,
    );
  }

  /// Factory for creating a cover page (drawings not saved)
  factory Page.createCover({
    required int index,
    PageSize? size,
    PageBackground? background,
  }) {
    return Page.create(
      index: index,
      size: size,
      background: background,
      isCover: true,
    );
  }

  /// Total stroke count across all layers
  int get strokeCount => layers.fold<int>(0, (sum, layer) => sum + layer.strokes.length);

  /// Total shape count across all layers
  int get shapeCount => layers.fold<int>(0, (sum, layer) => sum + layer.shapes.length);

  /// Total text count across all layers
  int get textCount => layers.fold<int>(0, (sum, layer) => sum + layer.texts.length);

  /// Is empty (no content)
  bool get isEmpty => strokeCount == 0 && shapeCount == 0 && textCount == 0;

  /// Active layer (last one)
  Layer get activeLayer => layers.isNotEmpty ? layers.last : Layer.empty('Katman');

  /// Copy with
  Page copyWith({
    String? id,
    int? index,
    PageSize? size,
    PageBackground? background,
    List<Layer>? layers,
    Uint8List? thumbnail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCover,
    bool? isBookmarked,
  }) {
    return Page(
      id: id ?? this.id,
      index: index ?? this.index,
      size: size ?? this.size,
      background: background ?? this.background,
      layers: layers ?? this.layers,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isCover: isCover ?? this.isCover,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  /// Returns a clean version of this page with all strokes removed
  /// (Used for cover pages before saving)
  Page clearDrawings() {
    final cleanLayers = layers.map((layer) {
      return layer.copyWith(
        strokes: [],
        shapes: [],
        texts: [],
      );
    }).toList();
    
    return copyWith(
      layers: cleanLayers,
      updatedAt: DateTime.now(),
    );
  }

  /// Add stroke to active layer
  Page addStroke(Stroke stroke) {
    final updatedLayers = List<Layer>.from(layers);
    if (updatedLayers.isEmpty) {
      updatedLayers.add(Layer.empty('Katman 1'));
    }
    final lastIndex = updatedLayers.length - 1;
    updatedLayers[lastIndex] = updatedLayers[lastIndex].addStroke(stroke);

    return copyWith(layers: updatedLayers);
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'index': index,
    'size': size.toJson(),
    'background': background.toJson(),
    'layers': layers.map((l) => l.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isCover': isCover,
    'isBookmarked': isBookmarked,
    // thumbnail is stored separately
  };

  factory Page.fromJson(Map<String, dynamic> json) {
    // Helper to parse int safely
    int parseInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }
    
    return Page(
      id: json['id'] as String,
      index: parseInt(json['index'], 0),
      size: PageSize.fromJson(json['size'] as Map<String, dynamic>),
      background: PageBackground.fromJson(json['background'] as Map<String, dynamic>),
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isCover: json['isCover'] as bool? ?? false,  // Backward compatible
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Page) return false;
    if (other.id != id ||
        other.index != index ||
        other.size != size ||
        other.background != background ||
        other.isCover != isCover ||
        other.isBookmarked != isBookmarked) {
      return false;
    }
    if (other.layers.length != layers.length) return false;
    for (int i = 0; i < layers.length; i++) {
      if (other.layers[i] != layers[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, index, layers.length, isBookmarked);
}

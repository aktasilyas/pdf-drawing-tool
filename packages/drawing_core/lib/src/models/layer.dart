import 'dart:ui' show BlendMode, Rect;
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'stroke.dart';

/// Represents a layer in a drawing document.
///
/// Layers allow organizing strokes and applying different blend modes
/// or visibility settings to groups of content.
///
/// ## Example
///
/// ```dart
/// final layer = Layer(
///   name: 'Sketch',
///   strokes: [stroke1, stroke2],
///   opacity: 0.8,
/// );
/// ```
class Layer extends Equatable {
  /// Creates a new layer.
  ///
  /// If [id] is not provided, a UUID will be generated.
  Layer({
    String? id,
    this.name = 'Layer',
    List<Stroke>? strokes,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
  })  : id = id ?? const Uuid().v4(),
        strokes = strokes ?? [];

  /// Unique identifier for this layer.
  final String id;

  /// Display name of this layer.
  final String name;

  /// The strokes contained in this layer.
  final List<Stroke> strokes;

  /// Whether this layer is visible.
  final bool isVisible;

  /// Whether this layer is locked (cannot be edited).
  final bool isLocked;

  /// The opacity of this layer, from 0.0 to 1.0.
  final double opacity;

  /// The blend mode used when compositing this layer.
  final BlendMode blendMode;

  /// Returns true if this layer has no strokes.
  bool get isEmpty => strokes.isEmpty;

  /// Returns true if this layer has at least one stroke.
  bool get isNotEmpty => strokes.isNotEmpty;

  /// Returns the number of strokes in this layer.
  int get strokeCount => strokes.length;

  /// Returns the bounding box that contains all strokes in this layer.
  Rect get boundingBox {
    if (strokes.isEmpty) return Rect.zero;

    Rect bounds = strokes.first.boundingBox;
    for (int i = 1; i < strokes.length; i++) {
      bounds = bounds.expandToInclude(strokes[i].boundingBox);
    }
    return bounds;
  }

  /// Creates a copy with the given fields replaced.
  Layer copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    BlendMode? blendMode,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? List.of(this.strokes),
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  /// Creates a copy with an additional stroke.
  Layer addStroke(Stroke stroke) {
    return copyWith(strokes: [...strokes, stroke]);
  }

  /// Creates a copy with the last stroke removed.
  Layer removeLastStroke() {
    if (strokes.isEmpty) return this;
    return copyWith(strokes: strokes.sublist(0, strokes.length - 1));
  }

  /// Creates a copy with the stroke at [index] removed.
  Layer removeStrokeAt(int index) {
    final newStrokes = List.of(strokes)..removeAt(index);
    return copyWith(strokes: newStrokes);
  }

  /// Creates a copy with the stroke with [id] removed.
  Layer removeStrokeById(String id) {
    final newStrokes = strokes.where((s) => s.id != id).toList();
    return copyWith(strokes: newStrokes);
  }

  /// Converts this layer to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
      'blendMode': blendMode.index,
    };
  }

  /// Creates a layer from a JSON map.
  factory Layer.fromJson(Map<String, dynamic> json) {
    return Layer(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Layer',
      strokes: (json['strokes'] as List?)
              ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: BlendMode.values[json['blendMode'] as int? ?? 0],
    );
  }

  @override
  List<Object?> get props =>
      [id, name, strokes, isVisible, isLocked, opacity, blendMode];

  @override
  String toString() =>
      'Layer(id: $id, name: $name, strokes: ${strokes.length}, visible: $isVisible)';
}

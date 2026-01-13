import 'package:equatable/equatable.dart';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/stroke.dart';

/// Represents a layer in a drawing document.
///
/// A [Layer] contains a collection of [Stroke]s and has properties like
/// visibility, lock state, and opacity.
///
/// This class is immutable - all modification methods return a new [Layer].
class Layer extends Equatable {
  /// Unique identifier for the layer.
  final String id;

  /// Display name of the layer.
  final String name;

  /// The strokes contained in this layer.
  ///
  /// This list is unmodifiable.
  final List<Stroke> strokes;

  /// Whether this layer is visible.
  final bool isVisible;

  /// Whether this layer is locked (cannot be modified).
  final bool isLocked;

  /// The opacity of this layer (0.0 to 1.0).
  final double opacity;

  /// Creates a new [Layer].
  ///
  /// The [strokes] list is wrapped in [List.unmodifiable] to ensure immutability.
  /// [opacity] is clamped to the range [0.0, 1.0].
  Layer({
    required this.id,
    required this.name,
    required List<Stroke> strokes,
    this.isVisible = true,
    this.isLocked = false,
    double opacity = 1.0,
  })  : strokes = List.unmodifiable(strokes),
        opacity = opacity.clamp(0.0, 1.0);

  /// Creates an empty layer with a generated ID.
  factory Layer.empty(String name) {
    return Layer(
      id: _generateId(),
      name: name,
      strokes: const [],
    );
  }

  /// Generates a unique ID based on the current timestamp.
  static String _generateId() {
    return 'layer_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Whether this layer has no strokes.
  bool get isEmpty => strokes.isEmpty;

  /// Whether this layer has at least one stroke.
  bool get isNotEmpty => strokes.isNotEmpty;

  /// The number of strokes in this layer.
  int get strokeCount => strokes.length;

  /// Returns a new [Layer] with the given stroke added.
  ///
  /// The original layer is not modified.
  Layer addStroke(Stroke stroke) {
    return Layer(
      id: id,
      name: name,
      strokes: [...strokes, stroke],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the stroke matching [strokeId] removed.
  ///
  /// If no stroke with the given ID exists, returns a copy of this layer.
  /// The original layer is not modified.
  Layer removeStroke(String strokeId) {
    final newStrokes = strokes.where((s) => s.id != strokeId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: newStrokes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with the stroke updated.
  ///
  /// The stroke is matched by ID. If no matching stroke is found,
  /// returns a copy of this layer unchanged.
  /// The original layer is not modified.
  Layer updateStroke(Stroke stroke) {
    final index = strokes.indexWhere((s) => s.id == stroke.id);
    if (index == -1) {
      return copyWith();
    }

    final newStrokes = List<Stroke>.from(strokes);
    newStrokes[index] = stroke;

    return Layer(
      id: id,
      name: name,
      strokes: newStrokes,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns a new [Layer] with all strokes removed.
  ///
  /// The original layer is not modified.
  Layer clear() {
    return Layer(
      id: id,
      name: name,
      strokes: const [],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
    );
  }

  /// Returns the stroke with the given [id], or null if not found.
  Stroke? getStrokeById(String strokeId) {
    for (final stroke in strokes) {
      if (stroke.id == strokeId) {
        return stroke;
      }
    }
    return null;
  }

  /// Finds all strokes that intersect with the given [rect].
  ///
  /// This is a stub implementation for Phase 2.
  /// Full implementation will be done in Phase 3.
  ///
  /// Returns an empty list (stub).
  List<Stroke> findStrokesInRect(BoundingBox rect) {
    // TODO: Implement in Phase 3
    // Will check stroke bounds intersection with rect
    return const [];
  }

  /// Creates a copy of this [Layer] with the given fields replaced.
  Layer copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
    );
  }

  /// Converts this [Layer] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
    };
  }

  /// Creates a [Layer] from a JSON map.
  factory Layer.fromJson(Map<String, dynamic> json) {
    return Layer(
      id: json['id'] as String,
      name: json['name'] as String,
      strokes: (json['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [id, name, strokes, isVisible, isLocked, opacity];

  @override
  String toString() {
    return 'Layer(id: $id, name: $name, strokeCount: $strokeCount, '
        'isVisible: $isVisible, isLocked: $isLocked, opacity: $opacity)';
  }
}

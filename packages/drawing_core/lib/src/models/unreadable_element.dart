import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A stored layer element that this app version could not decode.
///
/// Typical causes are data written by a newer app version (an unknown shape
/// type) or a damaged entry. The raw JSON is kept unchanged so that saving the
/// notebook does not lose it; it is never rendered, hit-tested or exported.
@immutable
class UnreadableElement extends Equatable {
  /// Creates an unreadable element found in the [listKey] list of a layer.
  const UnreadableElement({required this.listKey, required this.raw});

  /// The layer JSON list the element came from (`strokes`, `shapes`, ...).
  final String listKey;

  /// The element exactly as it was decoded from JSON. Never mutated.
  final Object? raw;

  /// The element id when the raw JSON has a string `id`, else null.
  String? get id {
    final value = raw;
    if (value is Map && value['id'] is String) return value['id'] as String;
    return null;
  }

  @override
  List<Object?> get props => [listKey, raw];

  @override
  String toString() => 'UnreadableElement(listKey: $listKey, id: $id)';
}

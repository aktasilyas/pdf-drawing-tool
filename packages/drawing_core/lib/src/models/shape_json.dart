part of 'shape.dart';

// JSON (de)serialization for [Shape]. The stored format is part of saved
// notebooks: keep keys and value encodings stable.

Map<String, dynamic> _shapeToJson(Shape shape) => {
      'id': shape.id,
      'type': shape.type.name,
      'startPoint': shape.startPoint.toJson(),
      'endPoint': shape.endPoint.toJson(),
      'style': shape.style.toJson(),
      'isFilled': shape.isFilled,
      'fillColor': shape.fillColor,
    };

Shape _shapeFromJson(Map<String, dynamic> json) {
  return Shape(
    id: json['id'] as String,
    type: ShapeType.values.byName(json['type'] as String),
    startPoint:
        DrawingPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
    endPoint: DrawingPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
    style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
    isFilled: (json['isFilled'] as bool?) ?? false,
    fillColor: _parseNullableInt(json['fillColor']),
  );
}

/// Lenient int parsing: accepts int, double, numeric string; else null.
int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

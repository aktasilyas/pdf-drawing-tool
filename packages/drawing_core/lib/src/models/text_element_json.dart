part of 'text_element.dart';

// JSON (de)serialization for [TextElement]. The stored format is part of
// saved notebooks: keep keys and value encodings stable.

Map<String, dynamic> _textElementToJson(TextElement e) => {
      'id': e.id,
      'text': e.text,
      'x': e.x,
      'y': e.y,
      'fontSize': e.fontSize,
      'color': e.color,
      'fontFamily': e.fontFamily,
      'isBold': e.isBold,
      'isItalic': e.isItalic,
      'isUnderline': e.isUnderline,
      'alignment': e.alignment.name,
      'width': e.width,
      'height': e.height,
      'rotation': e.rotation,
    };

TextElement _textElementFromJson(Map<String, dynamic> json) {
  return TextElement(
    id: json['id'],
    text: json['text'],
    x: _parseDouble(json['x'], 0.0),
    y: _parseDouble(json['y'], 0.0),
    fontSize: _parseDouble(json['fontSize'], 16.0),
    color: _parseInt(json['color'], 0xFF000000),
    fontFamily: json['fontFamily'] ?? 'Roboto',
    isBold: json['isBold'] ?? false,
    isItalic: json['isItalic'] ?? false,
    isUnderline: json['isUnderline'] ?? false,
    // Unknown values (e.g. from a newer app version) fall back to left.
    alignment: TextAlignment.values.asNameMap()[json['alignment']] ??
        TextAlignment.left,
    width: json['width'] != null ? _parseDouble(json['width'], 0.0) : null,
    height: json['height'] != null ? _parseDouble(json['height'], 0.0) : null,
    rotation: _parseDouble(json['rotation'], 0.0),
  );
}

double _parseDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  if (value is num) return value.toDouble();
  return defaultValue;
}

int _parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  if (value is num) return value.toInt();
  return defaultValue;
}

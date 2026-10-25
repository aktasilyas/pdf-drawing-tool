/// Lenient JSON number parsing shared by stroke models (internal).
double parseJsonDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Lenient JSON int parsing shared by stroke models (internal).
int parseJsonInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

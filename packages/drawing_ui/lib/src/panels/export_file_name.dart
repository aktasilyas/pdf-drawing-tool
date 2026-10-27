/// File names for exported documents.
library;

/// Builds an export filename with title + date/time stamp.
String buildExportFilename(String title) {
  final base = sanitizeFilename(title);
  final now = DateTime.now();
  final stamp = '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  return '${base}_$stamp';
}

/// Sanitizes a string for use as a filename.
String sanitizeFilename(String title) {
  var name = title.isEmpty ? 'doküman' : title;
  name = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
  if (name.length > 200) name = name.substring(0, 200);
  return name;
}

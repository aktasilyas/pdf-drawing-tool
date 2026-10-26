/// A PDF handed to the app by another app (Open with / Share).
///
/// [path] points to a private cache copy that the consumer must delete once
/// the PDF has been imported.
class IncomingPdf {
  const IncomingPdf({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is IncomingPdf &&
      other.path == path &&
      other.name == name &&
      other.size == size;

  @override
  int get hashCode => Object.hash(path, name, size);

  @override
  String toString() => 'IncomingPdf($name, $size bytes, $path)';
}

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;

/// Whether [path] points into the app's `elyanotes_images/` directory,
/// relative or absolute. Only such image files may be deleted: image elements
/// written by older versions can reference the user's own files (gallery,
/// Downloads) by absolute path.
bool isManagedImagePath(String path) {
  final segments = path.replaceAll('\\', '/').split('/');
  if (segments.contains('..') || segments.length < 2) return false;
  return segments.last.isNotEmpty &&
      segments[segments.length - 2] == PdfPathResolver.imagesDir;
}

/// Stored paths of the app-managed files that the page JSON [page] points to:
/// the copied PDF, the image of an image page and the files of image
/// elements. Image paths outside `elyanotes_images/` and anything malformed
/// are skipped; never throws.
Set<String> managedFilePathsOfPage(Map<String, dynamic> page) {
  final paths = <String>{};

  final background = page['background'];
  if (background is Map) {
    // Copied PDFs are always app files (unchanged pre-#384 behaviour).
    final pdf = background['pdfFilePath'];
    if (pdf is String && pdf.isNotEmpty) paths.add(pdf);
    final image = background['imageFilePath'];
    if (image is String && isManagedImagePath(image)) paths.add(image);
  }

  final layers = page['layers'];
  if (layers is List) {
    for (final layer in layers) {
      final images = layer is Map ? layer['images'] : null;
      if (images is! List) continue;
      for (final image in images) {
        final path = image is Map ? image['filePath'] : null;
        if (path is String && isManagedImagePath(path)) paths.add(path);
      }
    }
  }
  return paths;
}

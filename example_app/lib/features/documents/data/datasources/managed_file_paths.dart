/// Stored paths of the app-managed files that the page JSON [page] points to:
/// the copied PDF, the image of an image page and the files of image
/// elements. Anything malformed is skipped; never throws.
Set<String> managedFilePathsOfPage(Map<String, dynamic> page) {
  final paths = <String>{};

  final background = page['background'];
  if (background is Map) {
    for (final key in const ['pdfFilePath', 'imageFilePath']) {
      final path = background[key];
      if (path is String && path.isNotEmpty) paths.add(path);
    }
  }

  final layers = page['layers'];
  if (layers is List) {
    for (final layer in layers) {
      final images = layer is Map ? layer['images'] : null;
      if (images is! List) continue;
      for (final image in images) {
        final path = image is Map ? image['filePath'] : null;
        if (path is String && path.isNotEmpty) paths.add(path);
      }
    }
  }
  return paths;
}

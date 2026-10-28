/// Converts between absolute file paths of managed app files (imported PDFs and
/// inserted images) and the container-relative form that is persisted
/// (`pdfs/<name>.pdf`, `elyanotes_images/<name>.png`).
///
/// The app documents directory changes after a restore or device transfer, so
/// only the part below it is stored. Paths written by older versions are
/// absolute; they are resolved through their `<managedDir>/<name>` suffix.
///
/// Pure Dart (no `dart:io`); both `/` and `\` separators are understood.
class PdfPathResolver {
  /// Creates a resolver for the app documents directory [documentsRoot].
  /// A `null` root makes the resolver a passthrough.
  const PdfPathResolver(this.documentsRoot);

  /// Resolver that leaves every path unchanged.
  static const passthrough = PdfPathResolver(null);

  /// Name of the directory below the documents root that holds imported PDFs.
  static const pdfDir = 'pdfs';

  /// Name of the directory below the documents root that holds inserted images.
  static const imagesDir = 'elyanotes_images';

  static const Set<String> _managedDirs = {pdfDir, imagesDir};

  /// Absolute app documents directory, or `null` for a passthrough.
  final String? documentsRoot;

  static final RegExp _driveRoot = RegExp(r'^[A-Za-z]:[\\/]');

  static bool _isAbsolute(String path) =>
      path.startsWith('/') ||
      path.startsWith('\\') ||
      _driveRoot.hasMatch(path);

  static String _normalize(String path) => path.replaceAll('\\', '/');

  String? get _root {
    final root = documentsRoot;
    if (root == null || root.isEmpty) return null;
    var normalized = _normalize(root);
    while (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// The form to persist for [absolutePath]: `pdfs/<name>` when the file lives
  /// directly under `<root>/<managedDir>/`, otherwise [absolutePath] unchanged.
  String toStored(String absolutePath) {
    final root = _root;
    if (root == null) return absolutePath;
    final normalized = _normalize(absolutePath);
    for (final dir in _managedDirs) {
      final prefix = '$root/$dir/';
      if (!normalized.startsWith(prefix)) continue;
      final name = normalized.substring(prefix.length);
      if (name.isEmpty || name.contains('/')) return absolutePath;
      return '$dir/$name';
    }
    return absolutePath;
  }

  /// The absolute path to open for [stored].
  ///
  /// Relative paths are joined to the root. Absolute paths whose parent
  /// directory is a managed directory are re-rooted. Anything else is returned unchanged.
  String resolve(String stored) {
    final root = _root;
    if (root == null) return stored;
    final normalized = _normalize(stored);
    if (!_isAbsolute(stored)) {
      return normalized.split('/').contains('..')
          ? stored
          : '$root/$normalized';
    }
    final segments = normalized.split('/');
    if (segments.length >= 2 &&
        _managedDirs.contains(segments[segments.length - 2]) &&
        segments.last.isNotEmpty) {
      return '$root/${segments[segments.length - 2]}/${segments.last}';
    }
    return stored;
  }
}

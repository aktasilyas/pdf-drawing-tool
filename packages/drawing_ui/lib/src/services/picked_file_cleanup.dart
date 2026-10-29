import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Removes the temporary copy a file picker made of the file at a path.
typedef PickedFileCleanup = Future<void> Function(String path);

/// Deletes [path] when it lies inside the app cache directory; never throws.
///
/// On Android, file_picker resolves `content://` picks by copying them into
/// the app cache, so every import would otherwise leave a full copy behind
/// until the OS evicts it (#469). A path outside the cache (the user's own
/// file, as on desktop) is never touched. [cacheDirectory] defaults to
/// [getTemporaryDirectory], which is the cache directory on Android.
Future<void> deletePickedFileCopy(
  String path, {
  Future<String> Function()? cacheDirectory,
}) async {
  try {
    final cache = await (cacheDirectory ?? _temporaryDirectoryPath)();
    if (!isPathInsideDirectory(path, cache)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Cleanup must never fail an import; the OS evicts the cache later.
  }
}

/// Runs [body] for the picked file at [path], then [cleanup]s the picker's
/// temporary copy whether [body] succeeds, fails or throws.
///
/// [body] must be done reading [path] when its future completes: imports
/// copy the file into app storage before they return.
Future<T> withPickedFile<T>(
  String path,
  Future<T> Function() body, {
  PickedFileCleanup cleanup = deletePickedFileCopy,
}) async {
  try {
    return await body();
  } finally {
    await cleanup(path);
  }
}

/// Whether [path] is strictly inside [directory] after resolving `.` and
/// `..` segments; the directory itself and siblings sharing its name as a
/// prefix (`cache2` for `cache`) are not inside.
bool isPathInsideDirectory(String path, String directory) {
  final file = _normalized(path);
  final root = _normalized(directory);
  final prefix = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return file.length > prefix.length && file.startsWith(prefix);
}

String _normalized(String path) =>
    File(path).absolute.uri.normalizePath().toFilePath();

Future<String> _temporaryDirectoryPath() async =>
    (await getTemporaryDirectory()).path;

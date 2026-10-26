import 'dart:io';

/// Deletes [file] if it exists; never throws.
Future<void> deletePdfQuietly(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

/// Stores a PDF in app storage and imports it, leaving no orphan behind.
///
/// [write] fills [file] (a copy or a byte write) and [import] reads it.
/// The file is deleted when [write] or [import] throws (including a partial
/// write) or when [isFailure] reports the import result as failed.
Future<T> storePdfAndImport<T>({
  required File file,
  required Future<void> Function(File file) write,
  required Future<T> Function(File file) import,
  required bool Function(T result) isFailure,
}) async {
  try {
    await write(file);
    final result = await import(file);
    if (isFailure(result)) await deletePdfQuietly(file);
    return result;
  } catch (_) {
    await deletePdfQuietly(file);
    rethrow;
  }
}

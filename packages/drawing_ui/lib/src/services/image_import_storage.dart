import 'dart:io';

import 'package:drawing_core/drawing_core.dart';

/// Copies the picked image at [sourcePath] into the app-owned images folder
/// under [documentsRoot] and returns the path to persist on the element.
///
/// The returned path is container-relative (`elyanotes_images/<name>`) when
/// [paths] knows the documents root, so it survives a restore or device
/// transfer; with the passthrough resolver it is the absolute path.
Future<String> storeImportedImage(
  String sourcePath, {
  required String documentsRoot,
  PdfPathResolver paths = PdfPathResolver.passthrough,
}) async {
  final dir = Directory('$documentsRoot/${PdfPathResolver.imagesDir}');
  await dir.create(recursive: true);

  final name = sourcePath.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  final ext =
      dot < 0 || dot == name.length - 1 ? 'jpg' : name.substring(dot + 1);
  final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
  try {
    await File(sourcePath).copy(dest);
  } catch (_) {
    final partial = File(dest);
    if (await partial.exists()) await partial.delete();
    rethrow;
  }
  return paths.toStored(dest);
}

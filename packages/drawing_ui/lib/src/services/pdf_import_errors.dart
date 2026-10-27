import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'pdf_loader.dart';

/// Shown when a PDF needs a password to open.
const pdfPasswordProtectedMessage =
    'Bu PDF parola korumalı. Parolayı kaldırıp tekrar deneyin.';

/// Bytes read from each end of the file by [pdfFileLooksEncrypted].
const _sniffBytes = 64 * 1024;

/// Whether the PDF at [path] declares an `/Encrypt` dictionary.
///
/// Used only after opening failed: Android's renderer reports a locked file
/// with a generic error. The trailer (or xref stream dictionary) carrying
/// `/Encrypt` is uncompressed and sits at the end of the file, or near the
/// start for linearized files, so both ends are scanned. Any I/O error
/// counts as "not encrypted".
Future<bool> pdfFileLooksEncrypted(String path) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final length = await raf.length();
    final head = await raf.read(math.min(_sniffBytes, length));
    final tailStart = math.max(0, length - _sniffBytes);
    await raf.setPosition(tailStart);
    final tail = await raf.read(length - tailStart);
    bool has(List<int> bytes) => latin1.decode(bytes).contains('/Encrypt');
    return has(head) || has(tail);
  } on FileSystemException {
    return false;
  } finally {
    await raf?.close();
  }
}

/// Maps an import failure to a message that is safe to show to the user.
String friendlyPdfImportError(Object error) {
  if (error is ArgumentError || error is StateError) {
    return error.toString();
  }
  final text = error is PDFLoaderException
      ? '${error.message} ${error.cause}'.toLowerCase()
      : error.toString().toLowerCase();
  if (text.contains('password') ||
      text.contains('encrypt') ||
      text.contains('parola')) {
    return pdfPasswordProtectedMessage;
  }
  if (error is FileSystemException) {
    return 'PDF dosyasına erişilemedi.';
  }
  return 'PDF açılamadı. Dosya bozuk olabilir.';
}

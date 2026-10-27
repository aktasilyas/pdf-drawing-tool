import 'dart:io';

import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendlyExportError', () {
    test('maps ENOSPC to the storage-full message', () {
      final error = FileSystemException(
        'Cannot write',
        '/x.pdf',
        const OSError('No space left on device', 28),
      );
      expect(friendlyExportError(error), exportStorageFullMessage);
    });

    test('maps other file system errors to the cannot-write message', () {
      final error = FileSystemException(
        'Cannot write',
        '/x.pdf',
        const OSError('Permission denied', 13),
      );
      expect(friendlyExportError(error), exportCannotWriteMessage);
    });

    test('maps anything else to the generic message without raw text', () {
      final message = friendlyExportError(Exception('secret internals'));
      expect(message, exportFailedMessage);
      expect(message, isNot(contains('secret')));
    });
  });
}

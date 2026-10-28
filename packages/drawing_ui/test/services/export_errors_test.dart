import 'dart:io';

import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exportFailureFor', () {
    test('maps ENOSPC to storageFull', () {
      final error = FileSystemException(
        'Cannot write',
        '/x.pdf',
        const OSError('No space left on device', 28),
      );
      expect(exportFailureFor(error), ExportFailure.storageFull);
    });

    test('maps other file system errors to cannotWrite', () {
      final error = FileSystemException(
        'Cannot write',
        '/x.pdf',
        const OSError('Permission denied', 13),
      );
      expect(exportFailureFor(error), ExportFailure.cannotWrite);
    });

    test('maps anything else to failed', () {
      expect(exportFailureFor(Exception('secret internals')),
          ExportFailure.failed);
    });
  });
}

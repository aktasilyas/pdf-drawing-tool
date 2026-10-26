import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Back navigation is documented in docs/plans/202-a11y-pass.md: every route
// is top level, so system back pops to the library (and exits the app from
// the library itself). The editor is the only screen that intercepts back,
// to flush unsaved ink. This test keeps that single interception honest: a
// new PopScope anywhere else is a deliberate decision, not an accident.
void main() {
  test('PopScope lives only in the editor leave guard', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!entity.readAsStringSync().contains('PopScope')) continue;
      hits.add(entity.path.replaceAll(r'\', '/'));
    }

    expect(hits, [
      'lib/features/editor/presentation/widgets/editor_leave_guard.dart',
    ]);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:drawing_ui/src/utils/drawing_log.dart';

void main() {
  tearDown(() => DrawingLog.sink = null);

  test('messages reach a custom sink with level and error', () {
    final seen = <(DrawingLogLevel, String, Object?)>[];
    DrawingLog.sink =
        (level, message, error, stack) => seen.add((level, message, error));

    DrawingLog.w('careful');
    DrawingLog.e('boom', StateError('x'));

    expect(seen[0], (DrawingLogLevel.warning, 'careful', null));
    expect(seen[1].$1, DrawingLogLevel.error);
    expect(seen[1].$3, isA<StateError>());
  });

  test('default sink does not throw', () {
    DrawingLog.d('d');
    DrawingLog.i('i');
    DrawingLog.w('w');
    DrawingLog.e('e', 'err', StackTrace.current);
  });
}

import 'dart:async';

import 'helpers/tolerant_golden_comparator.dart';

/// Picked up by `flutter test` for every test under this directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    runWithTolerantGoldens(testMain);

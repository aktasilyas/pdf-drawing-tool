import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Share of pixels (0..1) a golden may differ by and still pass: 0.05 %.
///
/// CI's software renderer occasionally produces a few dozen anti-aliasing
/// pixels of noise (observed: 67 px, about 0.01 %). A real
/// change such as a 1 dp hairline across a 1180 dp tablet golden (~0.12 %)
/// still fails. Keep in sync with the copy in `packages/drawing_ui/test/` and
/// the `design-loop` skill.
const double kGoldenDiffTolerance = 0.0005;

/// [LocalFileComparator] that accepts diffs up to [tolerance] (a fraction of
/// all pixels). Size mismatches always fail.
class TolerantGoldenFileComparator extends LocalFileComparator {
  /// Creates a comparator resolving goldens relative to [testFile].
  TolerantGoldenFileComparator(
    super.testFile, {
    this.tolerance = kGoldenDiffTolerance,
  }) : assert(tolerance >= 0 && tolerance < 1);

  /// Maximum share of differing pixels (0..1) that still passes.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Replaces the default per-file [LocalFileComparator] with a
/// [TolerantGoldenFileComparator] for the same test file, then runs [testMain].
///
/// Called from `flutter_test_config.dart`.
Future<void> runWithTolerantGoldens(FutureOr<void> Function() testMain) async {
  final current = goldenFileComparator;
  if (current is LocalFileComparator &&
      current is! TolerantGoldenFileComparator) {
    // basedir is the test file's directory; any file name inside it works.
    goldenFileComparator =
        TolerantGoldenFileComparator(current.basedir.resolve('test.dart'));
  }
  await testMain();
}

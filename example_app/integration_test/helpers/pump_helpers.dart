import 'package:flutter_test/flutter_test.dart';

/// Pump helpers for the real app.
///
/// `pumpAndSettle` is avoided on purpose: the splash screen, progress
/// indicators and the editor run animations that never settle.
extension AppPump on WidgetTester {
  /// Pumps frames in 100 ms steps for [duration].
  Future<void> pumpFor(Duration duration) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    while (elapsed < duration) {
      await pump(step);
      elapsed += step;
    }
  }

  /// Pumps until [finder] matches at least one widget, or fails after
  /// [timeout]. Includes the 3.5 s splash delay in the default budget.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    while (finder.evaluate().isEmpty) {
      if (elapsed >= timeout) {
        throw TestFailure(
          'Timed out after ${timeout.inSeconds}s waiting for $finder',
        );
      }
      await pump(step);
      elapsed += step;
    }
    // One more frame so the widget is laid out and hit-testable.
    await pump(step);
  }

  /// Pumps until [finder] matches nothing, or fails after [timeout].
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    while (finder.evaluate().isNotEmpty) {
      if (elapsed >= timeout) {
        throw TestFailure(
          'Timed out after ${timeout.inSeconds}s waiting for $finder to go',
        );
      }
      await pump(step);
      elapsed += step;
    }
  }

  /// Waits for [finder], taps it, then lets transitions run.
  Future<void> tapAndWait(Finder finder) async {
    await pumpUntilFound(finder);
    await tap(finder.first);
    await pumpFor(const Duration(milliseconds: 600));
  }
}

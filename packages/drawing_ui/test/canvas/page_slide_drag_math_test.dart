import 'package:drawing_ui/src/canvas/page_slide_drag_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool commit(double offset,
          {double v = 0, bool fwd = true, bool back = true}) =>
      PageSlideDragMath.shouldCommit(
        offset: offset,
        extent: 400,
        velocity: v,
        canSwipeForward: fwd,
        canSwipeBack: back,
      );

  group('shouldCommit', () {
    test('drag below threshold reverts', () {
      expect(commit(-50), isFalse);
      expect(commit(50), isFalse);
    });
    test('drag above threshold navigates', () {
      expect(commit(-150), isTrue);
      expect(commit(150), isTrue);
    });
    test('fast fling commits even for a short drag', () {
      expect(commit(-20, v: -800), isTrue);
      expect(commit(20, v: 800), isTrue);
    });
    test('blocked direction never commits', () {
      expect(commit(-300, fwd: false), isFalse);
      expect(commit(300, back: false), isFalse);
    });
  });

  group('directionFor', () {
    test('stays undetermined under the lock threshold', () {
      expect(PageSlideDragMath.directionFor(-10), 0);
      expect(PageSlideDragMath.directionFor(9), 0);
    });
    test('negative offset is forward, positive is back', () {
      expect(PageSlideDragMath.directionFor(-11), 1);
      expect(PageSlideDragMath.directionFor(11), -1);
    });
  });

  group('applyDelta', () {
    double apply(double cur, double d,
            {int lock = 0, bool fwd = true, bool back = true}) =>
        PageSlideDragMath.applyDelta(
          current: cur,
          delta: d,
          lockedDirection: lock,
          canSwipeForward: fwd,
          canSwipeBack: back,
        );

    test('free drag follows the finger', () {
      expect(apply(0, -30), -30);
      expect(apply(-30, 10), -20);
    });
    test('locked forward direction cannot cross zero', () {
      expect(apply(-10, 50, lock: 1), 0);
    });
    test('locked back direction cannot cross zero', () {
      expect(apply(10, -50, lock: -1), 0);
    });
    test('disallowed direction only moves with resistance', () {
      expect(apply(0, -100, fwd: false), closeTo(-15, 1e-9));
      expect(apply(0, 100, back: false), closeTo(15, 1e-9));
    });
  });

  test('targetOffset', () {
    expect(
        PageSlideDragMath.targetOffset(
            commit: false, forward: true, extent: 400),
        0);
    expect(
        PageSlideDragMath.targetOffset(
            commit: true, forward: true, extent: 400),
        -400);
    expect(
        PageSlideDragMath.targetOffset(
            commit: true, forward: false, extent: 400),
        400);
  });

  test('releaseMillis is clamped', () {
    expect(
        PageSlideDragMath.releaseMillis(
            distance: 100, extent: 0, absVelocity: 0),
        250);
    expect(
        PageSlideDragMath.releaseMillis(
            distance: 10, extent: 400, absVelocity: 5000),
        100);
    expect(
        PageSlideDragMath.releaseMillis(
            distance: 400, extent: 400, absVelocity: 0),
        300);
    expect(
        PageSlideDragMath.releaseMillis(
            distance: 1, extent: 400, absVelocity: 0),
        150);
  });
}

/// Pure maths for the interactive page-swipe drag (no Flutter dependency).
///
/// Direction is `1` for forward (drag towards negative offset) and `-1` for
/// back.
class PageSlideDragMath {
  const PageSlideDragMath._();

  /// Drag distance after which the swipe direction is locked.
  static const double directionLockThreshold = 10;

  /// Fraction of the extent that commits a swipe.
  static const double commitFraction = 0.25;

  /// Fling speed (px/s) that commits a swipe regardless of distance.
  static const double commitVelocity = 500;

  /// Fraction of a delta applied while dragging in a disallowed direction.
  static const double resistance = 0.15;

  /// New drag offset after [delta]. Once [lockedDirection] is non-zero the
  /// offset cannot cross zero; disallowed directions only move by [resistance].
  static double applyDelta({
    required double current,
    required double delta,
    required int lockedDirection,
    required bool canSwipeForward,
    required bool canSwipeBack,
  }) {
    var next = current + delta;
    if (lockedDirection == 1) {
      next = next > 0 ? 0 : next;
    } else if (lockedDirection == -1) {
      next = next < 0 ? 0 : next;
    }
    if (next < 0 && !canSwipeForward || next > 0 && !canSwipeBack) {
      return current + delta * resistance;
    }
    return next;
  }

  /// Direction implied by [offset], or 0 while still under the threshold.
  static int directionFor(double offset) {
    if (offset.abs() <= directionLockThreshold) return 0;
    return offset < 0 ? 1 : -1;
  }

  /// Whether releasing at [offset] with [velocity] navigates to another page.
  static bool shouldCommit({
    required double offset,
    required double extent,
    required double velocity,
    required bool canSwipeForward,
    required bool canSwipeBack,
  }) {
    final progress = offset.abs() / extent;
    if (offset < 0) {
      return canSwipeForward &&
          (progress > commitFraction || velocity < -commitVelocity);
    }
    return canSwipeBack &&
        (progress > commitFraction || velocity > commitVelocity);
  }

  /// Offset the release animation settles on.
  static double targetOffset({
    required bool commit,
    required bool forward,
    required double extent,
  }) =>
      !commit ? 0 : (forward ? -extent : extent);

  /// Duration (ms) of the release animation.
  static int releaseMillis({
    required double distance,
    required double extent,
    required double absVelocity,
  }) {
    if (extent <= 0) return 250;
    if (absVelocity > 300) {
      return (distance / absVelocity * 1000).clamp(100, 350).toInt();
    }
    return (distance / extent * 300).clamp(150, 350).toInt();
  }
}

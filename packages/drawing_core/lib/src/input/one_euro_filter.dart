import 'dart:math' as math;

/// One Euro filter (Casiez et al., CHI 2012) for a single scalar signal.
///
/// Adaptive low-pass filter: heavy smoothing at low speed (kills jitter),
/// light smoothing at high speed (keeps latency low).
class OneEuroFilter {
  /// Minimum cutoff frequency in Hz. Lower = smoother at rest.
  final double minCutoff;

  /// Speed coefficient. Higher = less lag during fast movement.
  final double beta;

  /// Cutoff frequency for the derivative estimate in Hz.
  final double dCutoff;

  double? _x;
  double _dx = 0;

  /// Creates a filter with the given tuning.
  OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.0, this.dCutoff = 1.0});

  static double _alpha(double cutoff, double dt) {
    final tau = 1.0 / (2 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  /// Filters [value] sampled [dt] seconds after the previous sample.
  double filter(double value, double dt) {
    final prev = _x;
    if (prev == null || dt <= 0) {
      _x = value;
      return value;
    }
    final rawDx = (value - prev) / dt;
    _dx += _alpha(dCutoff, dt) * (rawDx - _dx);
    final cutoff = minCutoff + beta * _dx.abs();
    final result = prev + _alpha(cutoff, dt) * (value - prev);
    _x = result;
    return result;
  }

  /// Forgets all state.
  void reset() {
    _x = null;
    _dx = 0;
  }
}

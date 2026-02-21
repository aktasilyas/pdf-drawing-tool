import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the ruler overlay is visible on the canvas.
final rulerVisibleProvider = StateProvider<bool>((ref) => false);

/// Centre of the ruler strip in screen coordinates.
final rulerPositionProvider = StateProvider<Offset>(
  (ref) => const Offset(300, 350),
);

/// Rotation angle of the ruler in radians.
final rulerAngleProvider = StateProvider<double>((ref) => 0.0);

/// Whether the ruler is currently being rotated (two-finger gesture active).
final rulerRotatingProvider = StateProvider<bool>((ref) => false);

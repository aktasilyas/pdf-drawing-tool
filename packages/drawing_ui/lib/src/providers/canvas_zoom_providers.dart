import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';

// Derived zoom/viewport providers built on canvasTransformProvider.

/// Current zoom level (1.0 = 100%).
final zoomLevelProvider = Provider<double>((ref) {
  return ref.watch(canvasTransformProvider).zoom;
});

/// Zoom percentage string for UI display (e.g., "150%").
/// Now relative to baselineZoom: baseline = 100%.
final zoomPercentageProvider = Provider<String>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  final percentage = transform.displayPercentage.round();
  return '$percentage%';
});

/// Whether zoom gesture is currently active.
final isZoomingProvider = StateProvider<bool>((ref) => false);

/// Current canvas viewport size (set by DrawingCanvas/DrawingScreen).
/// Used by zoom controls to compute target offsets.
final canvasViewportSizeProvider = StateProvider<Size>((ref) => Size.zero);

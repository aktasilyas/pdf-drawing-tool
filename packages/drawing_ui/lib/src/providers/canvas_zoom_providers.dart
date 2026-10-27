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

/// Whether canvas is at baseline zoom (what user sees as "100%").
final isDefaultZoomProvider = Provider<bool>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  return (transform.zoom - transform.baselineZoom).abs() < 0.01;
});

/// Whether canvas can zoom in further.
final canZoomInProvider = Provider<bool>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return zoom < CanvasTransform.maxZoom;
});

/// Whether canvas can zoom out further.
final canZoomOutProvider = Provider<bool>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return zoom > CanvasTransform.minZoom;
});

/// Whether zoom gesture is currently active.
final isZoomingProvider = StateProvider<bool>((ref) => false);

/// Current canvas viewport size (set by DrawingCanvas/DrawingScreen).
/// Used by zoom controls to compute target offsets.
final canvasViewportSizeProvider = StateProvider<Size>((ref) => Size.zero);

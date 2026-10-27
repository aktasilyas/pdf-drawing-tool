/// Pure page-fit and pan-clamp maths used by `CanvasTransformNotifier`.
///
/// Internal to `drawing_ui`: not exported from the package barrel.
library;

import 'dart:ui';

/// Baseline zoom that fits the page within the viewport.
///
/// Uses min(fitWidth, fitHeight) with a small padding factor so the
/// page doesn't touch the viewport edges on narrow (portrait) screens.
double fitPageZoom(Size viewportSize, Size pageSize) {
  const padding = 0.96; // ~4% breathing room on the tight axis
  final fitWidth = viewportSize.width / pageSize.width;
  final fitHeight = viewportSize.height / pageSize.height;
  return (fitWidth < fitHeight) ? fitWidth * padding : fitHeight;
}

/// Offset that centers a page of [pageSize] at [zoom] in [viewportSize].
Offset centeredPageOffset(Size viewportSize, Size pageSize, double zoom) {
  final pageScreenWidth = pageSize.width * zoom;
  final pageScreenHeight = pageSize.height * zoom;
  return Offset(
    (viewportSize.width - pageScreenWidth) / 2,
    (viewportSize.height - pageScreenHeight) / 2,
  );
}

/// Clamps [offset] so a page of [pageSize] at [zoom] stays in [viewportSize].
///
/// Per axis: a page smaller than the viewport is centered; a larger page is
/// clamped so its edges never move inside the viewport edges.
Offset clampPageOffset(
  Offset offset, {
  required Size viewportSize,
  required Size pageSize,
  required double zoom,
}) {
  final pageScreenWidth = pageSize.width * zoom;
  final pageScreenHeight = pageSize.height * zoom;

  final dx = pageScreenWidth <= viewportSize.width
      ? (viewportSize.width - pageScreenWidth) / 2
      : offset.dx.clamp(viewportSize.width - pageScreenWidth, 0.0);
  final dy = pageScreenHeight <= viewportSize.height
      ? (viewportSize.height - pageScreenHeight) / 2
      : offset.dy.clamp(viewportSize.height - pageScreenHeight, 0.0);

  return Offset(dx, dy);
}

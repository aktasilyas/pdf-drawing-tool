import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Layout of the page behind the dragged snapshot.
Widget buildPageSlideDragOverlay({
  required BoxConstraints constraints,
  required Axis axis,
  required double extent,
  required double dragOffset,
  required ui.Image? snapshot,
  required Widget child,
  required bool pagePreSwitched,
  Widget? addPagePreview,
  Color? nextPagePreviewColor,
  Color? prevPagePreviewColor,
}) {
  final c = constraints;
  final horizontal = axis == Axis.horizontal;
  Offset along(double d) => horizontal ? Offset(d, 0) : Offset(0, d);
  Widget sized(Widget w) =>
      SizedBox(width: c.maxWidth, height: c.maxHeight, child: w);

  final off = dragOffset.clamp(-extent, extent);
  final fwd = off < 0;
  final adj = along(off + (fwd ? extent : -extent));

  final Widget adjWidget;
  // Keep child always in the tree to prevent DrawingCanvas disposal
  // during active gestures. Use Offstage when child is not visible.
  var childUsedInAdj = false;
  if (pagePreSwitched) {
    childUsedInAdj = true;
    adjWidget = Transform.translate(offset: adj, child: sized(child));
  } else if (fwd && addPagePreview != null) {
    adjWidget = Transform.translate(offset: adj, child: sized(addPagePreview));
  } else {
    final color = fwd ? nextPagePreviewColor : prevPagePreviewColor;
    if (color != null) {
      adjWidget = Transform.translate(
          offset: adj, child: sized(ColoredBox(color: color)));
    } else {
      childUsedInAdj = true;
      adjWidget = sized(child);
    }
  }
  return Stack(children: [
    adjWidget,
    Transform.translate(
        offset: along(off),
        child: sized(RawImage(image: snapshot, fit: BoxFit.none))),
    if (!childUsedInAdj) Offstage(child: child),
  ]);
}

/// Old snapshot sliding out while the live [child] slides in.
Widget buildPageSlideAutoAnimation({
  required Animation<double> animation,
  required Axis axis,
  required bool forward,
  required ui.Image? snapshot,
  required Widget child,
}) {
  final dir = forward ? -1.0 : 1.0;
  final horizontal = axis == Axis.horizontal;
  return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(animation.value);
        return ClipRect(child: LayoutBuilder(builder: (_, c) {
          final ext = horizontal ? c.maxWidth : c.maxHeight;
          Offset along(double d) => horizontal ? Offset(d, 0) : Offset(0, d);
          return Stack(children: [
            Transform.translate(
                offset: along(dir * t * ext),
                child: RawImage(image: snapshot, fit: BoxFit.none)),
            Transform.translate(
                offset: along(-dir * (1 - t) * ext), child: child),
          ]);
        }));
      });
}

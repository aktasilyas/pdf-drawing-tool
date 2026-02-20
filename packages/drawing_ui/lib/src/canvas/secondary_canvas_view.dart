import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/secondary_canvas_layers.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Interactive mirror of the primary canvas for dual-page mode.
///
/// Shares the same [canvasTransformProvider] (zoom/offset) as the primary
/// canvas. Renders the secondary page with identical visual output using
/// the same painter stack. Supports zoom/pan gestures that update the
/// shared transform.
///
/// Single-finger taps navigate to this page, making it the primary canvas
/// with full drawing support.
class SecondaryCanvasView extends ConsumerStatefulWidget {
  const SecondaryCanvasView({
    super.key,
    required this.page,
    this.canvasMode,
    this.colorScheme,
    this.onTap,
  });

  final core.Page? page;
  final core.CanvasMode? canvasMode;
  final CanvasColorScheme? colorScheme;

  /// Called when the user single-taps the secondary canvas.
  /// Typically navigates to this page index.
  final ValueChanged<int>? onTap;

  @override
  ConsumerState<SecondaryCanvasView> createState() =>
      _SecondaryCanvasViewState();
}

class _SecondaryCanvasViewState extends ConsumerState<SecondaryCanvasView> {
  final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();
  final ImageCacheManager _imageCacheManager = ImageCacheManager();
  Offset? _lastFocalPoint;
  double? _lastScale;

  // Tap detection for page navigation
  Offset? _tapStartPosition;
  DateTime? _tapStartTime;
  bool _isPotentialTap = false;

  /// Max distance for a gesture to qualify as a tap.
  static const double _tapSlop = 10.0;

  /// Max duration for a gesture to qualify as a tap.
  static const int _tapMaxDurationMs = 300;

  @override
  void dispose() {
    _imageCacheManager.dispose();
    super.dispose();
  }

  // ─── Zoom/Pan Gesture Handlers ─────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) {
      // Single finger: track as potential tap for page navigation
      _tapStartPosition = details.localFocalPoint;
      _tapStartTime = DateTime.now();
      _isPotentialTap = true;
      return;
    }
    _isPotentialTap = false;
    ref.read(isZoomingProvider.notifier).state = true;
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Cancel tap if second finger added
    if (details.pointerCount >= 2) {
      _isPotentialTap = false;
    }

    // Single finger: check if still a potential tap
    if (_isPotentialTap && details.pointerCount < 2) {
      if (_tapStartPosition != null &&
          (details.localFocalPoint - _tapStartPosition!).distance > _tapSlop) {
        _isPotentialTap = false;
      }
      return;
    }

    if (details.pointerCount < 2) return;

    final transformNotifier = ref.read(canvasTransformProvider.notifier);
    final mode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    // Use PRIMARY page for clamping (shared transform is based on primary)
    final primaryPage = ref.read(currentPageProvider);
    final primaryPageSize =
        Size(primaryPage.size.width, primaryPage.size.height);

    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportSize = renderBox?.size ?? const Size(800, 600);

    // Apply zoom (use localFocalPoint for correct coordinate mapping)
    if (_lastScale != null && details.scale != 1.0) {
      final scaleDelta = details.scale / _lastScale!;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        if (mode.isInfinite) {
          transformNotifier.applyZoomDelta(
            scaleDelta,
            details.localFocalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
          );
        } else {
          transformNotifier.applyZoomDeltaClamped(
            scaleDelta,
            details.localFocalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
            viewportSize: viewportSize,
            pageSize: primaryPageSize,
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    // Apply pan
    if (_lastFocalPoint != null) {
      final panDelta = details.localFocalPoint - _lastFocalPoint!;
      if (panDelta.distance > 0.5) {
        if (mode.isInfinite || mode.unlimitedPan) {
          transformNotifier.applyPanDelta(panDelta);
        } else {
          transformNotifier.applyPanDeltaClamped(
            panDelta,
            viewportSize: viewportSize,
            pageSize: primaryPageSize,
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    _lastFocalPoint = details.localFocalPoint;
    _lastScale = details.scale;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Check for single-finger tap -> navigate to this page
    if (_isPotentialTap && _tapStartTime != null && widget.page != null) {
      final duration = DateTime.now().difference(_tapStartTime!);
      if (duration.inMilliseconds < _tapMaxDurationMs) {
        final nextIdx = ref.read(currentPageIndexProvider) + 1;
        widget.onTap?.call(nextIdx);
      }
    }
    _isPotentialTap = false;
    _tapStartPosition = null;
    _tapStartTime = null;

    ref.read(isZoomingProvider.notifier).state = false;

    final mode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!mode.isInfinite && !mode.unlimitedPan) {
      final primaryPage = ref.read(currentPageProvider);
      final renderBox = context.findRenderObject() as RenderBox?;
      final viewportSize = renderBox?.size ?? const Size(800, 600);

      ref.read(canvasTransformProvider.notifier).snapBackForPage(
            viewportSize: viewportSize,
            pageSize:
                Size(primaryPage.size.width, primaryPage.size.height),
          );
    }

    _lastFocalPoint = null;
    _lastScale = null;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mode = widget.canvasMode ?? const core.CanvasMode(isInfinite: true);

    if (widget.page == null) {
      final bg = mode.isInfinite
          ? Colors.transparent
          : Color(mode.surroundingAreaColor);
      return _LastPagePlaceholder(surroundingColor: bg);
    }

    final page = widget.page!;
    final transform = ref.watch(canvasTransformProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final vw = constraints.maxWidth;
        final vh = constraints.maxHeight;
        if (vw <= 0 || vh <= 0) return const SizedBox.shrink();

        // Use same effective transform as primary canvas
        CanvasTransform effectiveTransform = transform;
        if (!mode.isInfinite) {
          final isDefault =
              transform.zoom == 1.0 && transform.offset == Offset.zero;
          if (isDefault) {
            const defaultZoom = 1.0;
            final pageSize = Size(page.size.width, page.size.height);
            effectiveTransform = CanvasTransform(
              zoom: defaultZoom,
              offset: Offset(
                (vw - pageSize.width * defaultZoom) / 2,
                (vh - pageSize.height * defaultZoom) / 2,
              ),
            );
          }
        }

        return Stack(
          children: [
            if (!mode.isInfinite)
              Positioned.fill(
                child: ColoredBox(
                  color: Color(mode.surroundingAreaColor),
                ),
              ),
            GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              behavior: HitTestBehavior.opaque,
              child: ClipRect(
                child: SizedBox(
                  width: vw,
                  height: vh,
                  child: Transform(
                    transform: effectiveTransform.matrix,
                    alignment: Alignment.topLeft,
                    child: buildSecondaryCanvasLayers(
                      page: page,
                      canvasMode: mode,
                      colorScheme: widget.colorScheme,
                      renderer: _renderer,
                      imageCacheManager: _imageCacheManager,
                      ref: ref,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Placeholder shown when there is no next page in dual-page mode.
class _LastPagePlaceholder extends StatelessWidget {
  const _LastPagePlaceholder({required this.surroundingColor});
  final Color surroundingColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: surroundingColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(StarNoteIcons.page,
                size: 40, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text('Son sayfa',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

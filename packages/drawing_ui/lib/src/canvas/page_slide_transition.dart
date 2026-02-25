import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

/// Slide transition between pages with auto-animation and interactive drag.
class PageSlideTransition extends StatefulWidget {
  const PageSlideTransition({
    super.key,
    required this.child,
    this.scrollDirection = Axis.horizontal,
    this.nextPagePreviewColor,
    this.prevPagePreviewColor,
    this.canSwipeForward = true,
    this.canSwipeBack = true,
    this.onSwipeNavigate,
    this.onDragDirectionDetermined,
    this.onDragReverted,
    this.addPagePreview,
  });
  final Widget child;
  final Axis scrollDirection;
  final Color? nextPagePreviewColor;
  final Color? prevPagePreviewColor;
  /// Widget shown when swiping forward on the last page (add new page).
  final Widget? addPagePreview;
  final bool canSwipeForward;
  final bool canSwipeBack;

  final ValueChanged<int>? onSwipeNavigate;
  final bool Function(int direction)? onDragDirectionDetermined;
  final VoidCallback? onDragReverted;

  @override
  State<PageSlideTransition> createState() => PageSlideTransitionState();
}

class PageSlideTransitionState extends State<PageSlideTransition>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;
  ui.Image? _snapshot;
  bool _isForward = true;

  // Interactive drag state
  bool _isDragging = false, _isAnimatingDrag = false;
  bool _directionDetermined = false, _pagePreSwitched = false;
  int _determinedDirection = 0;
  ui.Image? _dragSnapshot;
  double _dragOffset = 0.0, _startOffset = 0.0, _targetOffset = 0.0, _extent = 0.0;
  VoidCallback? _dragAnimListener;

  bool get _isHorizontal => widget.scrollDirection == Axis.horizontal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300))
      ..addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    if (_dragAnimListener != null) _controller.removeListener(_dragAnimListener!);
    _controller.dispose();
    _snapshot?.dispose();
    _dragSnapshot?.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_isAnimatingDrag) {
      _finalizeDrag();
    } else if (_snapshot != null) {
      setState(() { _snapshot?.dispose(); _snapshot = null; });
    }
  }

  Future<void> captureSnapshot({required bool forward}) async {
    if (_isDragging) return;
    if (_snapshot != null) {
      _controller.value = 1.0; _snapshot?.dispose(); _snapshot = null;
    }
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;
    try {
      final image = await boundary.toImage(pixelRatio: 1.0);
      if (!mounted) { image.dispose(); return; }
      setState(() { _snapshot = image; _isForward = forward; });
    } catch (_) {}
  }

  void startAnimation() {
    if (_snapshot == null) return;
    _controller.duration = const Duration(milliseconds: 300);
    _controller.forward(from: 0.0);
  }

  Future<void> beginDrag() async {
    if (_isDragging) return;
    if (_snapshot != null) {
      _controller.value = 1.0; _snapshot?.dispose(); _snapshot = null;
    }
    setState(() {
      _isDragging = true; _isAnimatingDrag = false; _dragOffset = 0;
      _directionDetermined = false; _pagePreSwitched = false;
      _determinedDirection = 0;
    });
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;
    try {
      final image = await boundary.toImage(pixelRatio: 1.0);
      if (!mounted || !_isDragging) { image.dispose(); return; }
      setState(() => _dragSnapshot = image);
    } catch (_) {}
  }

  void updateDrag(double delta) {
    if (!_isDragging || _isAnimatingDrag) return;
    setState(() {
      var n = _dragOffset + delta;
      // Direction lock: once determined, can't reverse past zero
      if (_directionDetermined) {
        n = _determinedDirection == 1 ? n.clamp(double.negativeInfinity, 0.0)
            : n.clamp(0.0, double.infinity);
      }
      // Resistance for disallowed directions
      if (n < 0 && !widget.canSwipeForward || n > 0 && !widget.canSwipeBack) {
        _dragOffset += delta * 0.15;
      } else {
        _dragOffset = n;
      }
      // Detect direction once threshold exceeded
      if (!_directionDetermined && _dragOffset.abs() > 10) {
        _determinedDirection = _dragOffset < 0 ? 1 : -1;
        _directionDetermined = true;
        _pagePreSwitched =
            widget.onDragDirectionDetermined?.call(_determinedDirection) ?? false;
      }
    });
  }

  void endDrag(double velocity) {
    if (!_isDragging || _isAnimatingDrag) return;
    if (_extent <= 0) { _cancelDrag(); return; }
    final progress = _dragOffset.abs() / _extent;
    final isForward = _dragOffset < 0;
    _isForward = isForward;
    final ok = isForward && widget.canSwipeForward
        ? (progress > 0.25 || velocity < -500)
        : !isForward && widget.canSwipeBack
            ? (progress > 0.25 || velocity > 500)
            : false;
    _animateToTarget(ok ? (isForward ? -_extent : _extent) : 0, velocity.abs());
  }

  void _animateToTarget(double target, double absVel) {
    _startOffset = _dragOffset;
    _targetOffset = target;
    _isAnimatingDrag = true;
    final dist = (target - _dragOffset).abs();
    final ms = _extent <= 0 ? 250
        : absVel > 300 ? (dist / absVel * 1000).clamp(100, 350).toInt()
        : (dist / _extent * 300).clamp(150, 350).toInt();
    _controller.duration = Duration(milliseconds: ms);
    _dragAnimListener = () {
      if (!_isAnimatingDrag) return;
      final t = Curves.easeOut.transform(_controller.value);
      setState(() => _dragOffset = _startOffset + (_targetOffset - _startOffset) * t);
    };
    _controller.addListener(_dragAnimListener!);
    _controller.forward(from: 0.0);
  }

  void _finalizeDrag() {
    _removeDragListener();
    _isAnimatingDrag = false;
    final completed = _targetOffset != 0;
    if (completed) {
      // If page wasn't pre-switched, signal navigation now
      if (!_pagePreSwitched) {
        widget.onSwipeNavigate?.call(_isForward ? 1 : -1);
      }
      // Wait for new page to render, then remove overlay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_resetDragState);
      });
    } else {
      // Cancelled — revert if page was pre-switched
      if (_pagePreSwitched) {
        widget.onDragReverted?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_resetDragState);
        });
      } else {
        setState(_resetDragState);
      }
    }
  }

  void _cancelDrag() {
    _removeDragListener();
    if (_pagePreSwitched) widget.onDragReverted?.call();
    setState(_resetDragState);
  }

  void _removeDragListener() {
    if (_dragAnimListener != null) {
      _controller.removeListener(_dragAnimListener!); _dragAnimListener = null;
    }
  }

  void _resetDragState() {
    _isDragging = false; _isAnimatingDrag = false;
    _directionDetermined = false; _pagePreSwitched = false;
    _determinedDirection = 0;
    _dragSnapshot?.dispose(); _dragSnapshot = null; _dragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(key: _boundaryKey, child: widget.child);
    if (_isDragging && _dragSnapshot != null) return _buildDragOverlay(child);
    if (_isDragging) return _buildDragFallback(child);
    if (_snapshot != null) return _buildAutoAnimation(child);
    return child;
  }

  Widget _buildDragFallback(Widget child) => ClipRect(
    child: LayoutBuilder(builder: (_, c) {
      _extent = _isHorizontal ? c.maxWidth : c.maxHeight;
      return Transform.translate(
        offset: _isHorizontal ? Offset(_dragOffset, 0) : Offset(0, _dragOffset),
        child: child,
      );
    }),
  );

  Widget _buildDragOverlay(Widget child) {
    return ClipRect(child: LayoutBuilder(builder: (_, c) {
      _extent = _isHorizontal ? c.maxWidth : c.maxHeight;
      final off = _dragOffset.clamp(-_extent, _extent);
      final fwd = off < 0;
      final cur = _isHorizontal ? Offset(off, 0) : Offset(0, off);
      final d = off + (fwd ? _extent : -_extent);
      final adj = _isHorizontal ? Offset(d, 0) : Offset(0, d);

      final Widget adjWidget;
      // Keep child always in the tree to prevent DrawingCanvas disposal
      // during active gestures. Use Offstage when child is not visible.
      bool childUsedInAdj = false;
      if (_pagePreSwitched) {
        childUsedInAdj = true;
        adjWidget = Transform.translate(offset: adj,
          child: SizedBox(width: c.maxWidth, height: c.maxHeight, child: child));
      } else if (fwd && widget.addPagePreview != null) {
        adjWidget = Transform.translate(offset: adj, child: SizedBox(
            width: c.maxWidth, height: c.maxHeight, child: widget.addPagePreview));
      } else {
        final color = fwd ? widget.nextPagePreviewColor : widget.prevPagePreviewColor;
        if (color != null) {
          adjWidget = Transform.translate(offset: adj, child: SizedBox(
              width: c.maxWidth, height: c.maxHeight, child: ColoredBox(color: color)));
        } else {
          childUsedInAdj = true;
          adjWidget = SizedBox(width: c.maxWidth, height: c.maxHeight, child: child);
        }
      }
      return Stack(children: [
        adjWidget,
        Transform.translate(offset: cur, child: SizedBox(
          width: c.maxWidth, height: c.maxHeight,
          child: RawImage(image: _dragSnapshot, fit: BoxFit.none))),
        if (!childUsedInAdj) Offstage(child: child),
      ]);
    }));
  }

  Widget _buildAutoAnimation(Widget child) {
    final dir = _isForward ? -1.0 : 1.0;
    return AnimatedBuilder(animation: _controller, builder: (_, __) {
      final t = Curves.easeInOut.transform(_controller.value);
      return ClipRect(child: LayoutBuilder(builder: (_, c) {
        final ext = _isHorizontal ? c.maxWidth : c.maxHeight;
        final old = _isHorizontal ? Offset(dir * t * ext, 0) : Offset(0, dir * t * ext);
        final nw = _isHorizontal
            ? Offset(-dir * (1 - t) * ext, 0) : Offset(0, -dir * (1 - t) * ext);
        return Stack(children: [
          Transform.translate(offset: old,
              child: RawImage(image: _snapshot, fit: BoxFit.none)),
          Transform.translate(offset: nw, child: child),
        ]);
      }));
    });
  }
}

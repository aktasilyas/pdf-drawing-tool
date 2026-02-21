import 'package:flutter/material.dart';

/// Popover placement direction.
enum _Placement { below, above, right }

/// Controller for showing/hiding popover panels.
///
/// Lighter alternative to [AnchoredPanelController].
/// Shows compact panels with arrow pointing to anchor.
/// Automatically flips above the anchor when there is not enough space below,
/// and opens to the right when neither vertical direction has enough room.
class PopoverController {
  OverlayEntry? _overlayEntry;

  /// Whether the popover is currently showing.
  bool get isShowing => _overlayEntry != null;

  /// Show popover anchored to the widget identified by [anchorKey].
  void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required Widget child,
    VoidCallback? onDismiss,
    double maxWidth = 280,
  }) {
    hide();
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => _PopoverOverlay(
        anchorPosition: box.localToGlobal(Offset.zero),
        anchorSize: box.size,
        screenSize: MediaQuery.of(context).size,
        maxWidth: maxWidth,
        onDismiss: () { hide(); onDismiss?.call(); },
        child: child,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  /// Hide the popover.
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Dispose the controller.
  void dispose() => hide();
}

class _PopoverOverlay extends StatefulWidget {
  const _PopoverOverlay({
    required this.anchorPosition,
    required this.anchorSize,
    required this.screenSize,
    required this.maxWidth,
    required this.onDismiss,
    required this.child,
  });
  final Offset anchorPosition;
  final Size anchorSize;
  final Size screenSize;
  final double maxWidth;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_PopoverOverlay> createState() => _PopoverOverlayState();
}

class _PopoverOverlayState extends State<_PopoverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150),
    );
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(curve);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  _Placement _decidePlacement() {
    const edge = 12.0, gap = 4.0, minSpace = 300.0;
    final anchorBottom = widget.anchorPosition.dy + widget.anchorSize.height;
    final anchorTop = widget.anchorPosition.dy;
    final spaceBelow = widget.screenSize.height - anchorBottom - gap - edge;
    final spaceAbove = anchorTop - gap - edge;

    if (spaceBelow >= minSpace) return _Placement.below;
    if (spaceAbove >= minSpace) return _Placement.above;
    return _Placement.right;
  }

  @override
  Widget build(BuildContext context) {
    final placement = _decidePlacement();
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onDismiss,
          child: const SizedBox.expand(),
        ),
      ),
      if (placement == _Placement.right)
        _buildHorizontal(context)
      else
        _buildVertical(context, placement),
    ]);
  }

  /// Vertical popover (below or above anchor).
  Widget _buildVertical(BuildContext context, _Placement placement) {
    final cs = Theme.of(context).colorScheme;
    const edge = 12.0, gap = 4.0, ah = 10.0, aw = 20.0;
    final openAbove = placement == _Placement.above;

    final anchorBottom = widget.anchorPosition.dy + widget.anchorSize.height;
    final anchorTop = widget.anchorPosition.dy;
    final cx = widget.anchorPosition.dx + widget.anchorSize.width / 2;
    final left = (cx - widget.maxWidth / 2).clamp(
      edge, widget.screenSize.width - widget.maxWidth - edge,
    );
    final arrowLeft = (cx - left - aw / 2).clamp(16.0, widget.maxWidth - 16.0 - aw);
    final bg = cs.surfaceContainerHigh;
    final border = cs.outlineVariant;

    final arrow = Padding(
      padding: EdgeInsets.only(left: arrowLeft),
      child: CustomPaint(
        size: const Size(aw, ah),
        painter: _ArrowPainter(color: bg, borderColor: border, direction: openAbove ? _ArrowDir.down : _ArrowDir.up),
      ),
    );
    final panel = _panelBox(bg, border);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: openAbove ? [panel, arrow] : [arrow, panel],
    );

    final animated = _animatedWrap(
      content,
      openAbove ? Alignment.bottomCenter : Alignment.topCenter,
    );

    return openAbove
        ? Positioned(bottom: widget.screenSize.height - anchorTop + gap, left: left, child: animated)
        : Positioned(top: anchorBottom + gap, left: left, child: animated);
  }

  /// Horizontal popover (right of anchor).
  Widget _buildHorizontal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const edge = 12.0, gap = 4.0, ah = 10.0, aw = 20.0;
    final bg = cs.surfaceContainerHigh;
    final border = cs.outlineVariant;

    final anchorRight = widget.anchorPosition.dx + widget.anchorSize.width;
    final anchorCy = widget.anchorPosition.dy + widget.anchorSize.height / 2;
    final left = anchorRight + gap;

    // Vertical position: center on anchor, clamped to screen
    final maxHeight = widget.screenSize.height - edge * 2;
    final top = (anchorCy - maxHeight / 2).clamp(edge, widget.screenSize.height - maxHeight - edge);
    final arrowTop = (anchorCy - top - ah / 2).clamp(16.0, maxHeight - 16.0 - ah);

    final arrow = Padding(
      padding: EdgeInsets.only(top: arrowTop),
      child: CustomPaint(
        size: const Size(aw, ah),
        painter: _ArrowPainter(color: bg, borderColor: border, direction: _ArrowDir.left),
      ),
    );
    final panel = _panelBox(bg, border);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [arrow, panel],
    );

    return Positioned(
      left: left,
      top: top,
      child: _animatedWrap(content, Alignment.centerLeft),
    );
  }

  Widget _panelBox(Color bg, Color border) => Container(
    constraints: BoxConstraints(maxWidth: widget.maxWidth),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 0.5),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(type: MaterialType.transparency, child: widget.child),
    ),
  );

  Widget _animatedWrap(Widget child, Alignment alignment) => FadeTransition(
    opacity: _fade,
    child: ScaleTransition(
      scale: _scale,
      alignment: alignment,
      child: GestureDetector(onTap: () {}, child: child),
    ),
  );
}

/// Arrow direction for the popover.
enum _ArrowDir { up, down, left }

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.color,
    required this.borderColor,
    required this.direction,
  });
  final Color color;
  final Color borderColor;
  final _ArrowDir direction;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Path();
    final stroke = Path();

    switch (direction) {
      case _ArrowDir.up:
        fill..moveTo(size.width / 2, 0)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
        stroke..moveTo(0, size.height)..lineTo(size.width / 2, 0)..lineTo(size.width, size.height);
      case _ArrowDir.down:
        fill..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
        stroke..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0);
      case _ArrowDir.left:
        // Arrow pointing left: tip at left center, base on right
        fill..moveTo(0, size.height / 2)..lineTo(size.width, 0)..lineTo(size.width, size.height)..close();
        stroke..moveTo(size.width, 0)..lineTo(0, size.height / 2)..lineTo(size.width, size.height);
    }

    canvas.drawPath(fill, Paint()..color = color);
    canvas.drawPath(stroke, Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.color != color || old.borderColor != borderColor || old.direction != direction;
}

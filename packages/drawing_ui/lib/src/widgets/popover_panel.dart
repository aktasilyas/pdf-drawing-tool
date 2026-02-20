import 'package:flutter/material.dart';

/// Controller for showing/hiding popover panels.
///
/// Lighter alternative to [AnchoredPanelController].
/// Shows compact panels with arrow pointing to anchor.
/// Automatically flips above the anchor when there is not enough space below.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const edge = 12.0, gap = 4.0, ah = 10.0, aw = 20.0;

    final anchorBottom = widget.anchorPosition.dy + widget.anchorSize.height;
    final anchorTop = widget.anchorPosition.dy;
    final spaceBelow = widget.screenSize.height - anchorBottom - gap - edge;
    final spaceAbove = anchorTop - gap - edge;
    final openAbove = spaceBelow < 300 && spaceAbove > spaceBelow;

    final cx = widget.anchorPosition.dx + widget.anchorSize.width / 2;
    final left = (cx - widget.maxWidth / 2).clamp(
      edge, widget.screenSize.width - widget.maxWidth - edge,
    );
    final arrowLeft = (cx - left - aw / 2).clamp(
      16.0, widget.maxWidth - 16.0 - aw,
    );
    final bg = cs.surfaceContainerHigh;
    final border = cs.outlineVariant;

    final arrow = Padding(
      padding: EdgeInsets.only(left: arrowLeft),
      child: CustomPaint(
        size: const Size(aw, ah),
        painter: _ArrowPainter(
          color: bg, borderColor: border, pointUp: !openAbove,
        ),
      ),
    );

    final panel = Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: widget.child,
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: openAbove ? [panel, arrow] : [arrow, panel],
    );

    final animatedContent = FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: openAbove ? Alignment.bottomCenter : Alignment.topCenter,
        child: GestureDetector(onTap: () {}, child: content),
      ),
    );

    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onDismiss,
          child: const SizedBox.expand(),
        ),
      ),
      if (openAbove)
        Positioned(
          bottom: widget.screenSize.height - anchorTop + gap,
          left: left,
          child: animatedContent,
        )
      else
        Positioned(
          top: anchorBottom + gap,
          left: left,
          child: animatedContent,
        ),
    ]);
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.color,
    required this.borderColor,
    this.pointUp = true,
  });
  final Color color;
  final Color borderColor;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Path();
    if (pointUp) {
      fill
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      fill
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(fill, Paint()..color = color);

    final stroke = Path();
    if (pointUp) {
      stroke
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      stroke
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(stroke, Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.color != color || old.borderColor != borderColor || old.pointUp != pointUp;
}

import 'package:flutter/material.dart';

/// Alignment hint for anchored panels
enum AnchorAlignment {
  /// Panel aligned to left edge of anchor
  left,
  /// Panel centered below anchor
  center,
  /// Panel aligned to right edge of anchor
  right,
}

/// Controller for managing anchored panel overlay using GlobalKey positioning
class AnchoredPanelController {
  OverlayEntry? _overlayEntry;
  bool get isShowing => _overlayEntry != null;

  /// Show the panel as an overlay positioned relative to anchor
  void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required Widget child,
    required VoidCallback onBarrierTap,
    AnchorAlignment alignment = AnchorAlignment.center,
    double verticalOffset = 8,
  }) {
    // Remove existing if any
    hide();

    // Get anchor position
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('[AnchoredPanel] ERROR: Could not find anchor RenderBox');
      return;
    }

    final anchorPosition = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _PositionedPanelOverlay(
        anchorPosition: anchorPosition,
        anchorSize: anchorSize,
        screenSize: screenSize,
        alignment: alignment,
        verticalOffset: verticalOffset,
        onBarrierTap: onBarrierTap,
        child: child,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Hide the panel
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Dispose the controller
  void dispose() {
    hide();
  }
}

/// Internal overlay widget with absolute positioning
class _PositionedPanelOverlay extends StatelessWidget {
  const _PositionedPanelOverlay({
    required this.anchorPosition,
    required this.anchorSize,
    required this.screenSize,
    required this.alignment,
    required this.verticalOffset,
    required this.onBarrierTap,
    required this.child,
  });

  final Offset anchorPosition;
  final Size anchorSize;
  final Size screenSize;
  final AnchorAlignment alignment;
  final double verticalOffset;
  final VoidCallback onBarrierTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Calculate panel position based on anchor
    final panelTop = anchorPosition.dy + anchorSize.height + verticalOffset;
    
    // Calculate horizontal position based on alignment
    double? panelLeft;
    double? panelRight;
    
    // Panel max width
    const panelMaxWidth = 300.0;
    const horizontalPadding = 16.0;
    
    switch (alignment) {
      case AnchorAlignment.left:
        // Align panel's left edge with anchor's left edge
        panelLeft = anchorPosition.dx;
        // Ensure panel doesn't go off right edge
        if (panelLeft + panelMaxWidth > screenSize.width - horizontalPadding) {
          panelLeft = screenSize.width - panelMaxWidth - horizontalPadding;
        }
        // Ensure panel doesn't go off left edge
        if (panelLeft < horizontalPadding) {
          panelLeft = horizontalPadding;
        }
        break;
        
      case AnchorAlignment.right:
        // Align panel's right edge with anchor's right edge
        panelRight = screenSize.width - (anchorPosition.dx + anchorSize.width);
        // Ensure panel doesn't go off left edge
        if (screenSize.width - panelRight - panelMaxWidth < horizontalPadding) {
          panelRight = screenSize.width - panelMaxWidth - horizontalPadding;
        }
        // Ensure panel doesn't go off right edge
        if (panelRight < horizontalPadding) {
          panelRight = horizontalPadding;
        }
        break;
        
      case AnchorAlignment.center:
        // Center panel below anchor
        final anchorCenterX = anchorPosition.dx + anchorSize.width / 2;
        panelLeft = anchorCenterX - panelMaxWidth / 2;
        // Ensure panel doesn't go off edges
        if (panelLeft < horizontalPadding) {
          panelLeft = horizontalPadding;
        }
        if (panelLeft + panelMaxWidth > screenSize.width - horizontalPadding) {
          panelLeft = screenSize.width - panelMaxWidth - horizontalPadding;
        }
        break;
    }

    // Calculate arrow position (points to anchor center)
    final anchorCenterX = anchorPosition.dx + anchorSize.width / 2;
    final double arrowLeftPosition;
    
    if (panelLeft != null) {
      // Panel positioned from left - arrow relative to panelLeft
      arrowLeftPosition = anchorCenterX - panelLeft - 12; // 12 = half of arrow width
    } else if (panelRight != null) {
      // Panel positioned from right - calculate panel's actual left position first
      final actualPanelLeft = screenSize.width - panelRight - panelMaxWidth;
      arrowLeftPosition = anchorCenterX - actualPanelLeft - 12;
    } else {
      // Fallback to center
      arrowLeftPosition = panelMaxWidth / 2 - 12;
    }

    return Stack(
      children: [
        // Barrier to detect taps outside panel (transparent)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onBarrierTap,
            child: const SizedBox.expand(),
          ),
        ),
        
        // Panel positioned below anchor
        Positioned(
          top: panelTop,
          left: panelLeft,
          right: panelRight,
          child: GestureDetector(
            // Absorb taps on panel (don't close)
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: panelMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arrow pointing up to anchor
                    Padding(
                      padding: EdgeInsets.only(
                        left: arrowLeftPosition.clamp(40, panelMaxWidth - 64),
                      ),
                      child: CustomPaint(
                        size: const Size(24, 12),
                        painter: _ArrowPainter(),
                      ),
                    ),
                    // Panel content
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple arrow painter pointing up
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Keep old AnchoredPanel for backwards compatibility but mark as deprecated
@Deprecated('Use AnchoredPanelController instead')
class AnchoredPanel extends StatelessWidget {
  const AnchoredPanel({
    super.key,
    required this.link,
    required this.child,
    this.offset = Offset.zero,
    this.showArrow = true,
    this.alignment = AnchorAlignment.center,
  });

  final LayerLink link;
  final Widget child;
  final Offset offset;
  final bool showArrow;
  final AnchorAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

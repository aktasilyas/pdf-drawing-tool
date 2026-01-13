import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// An anchored overlay panel for tool settings.
///
/// This widget manages the positioning and animation of floating panels
/// that appear below toolbar buttons.
class PanelOverlay extends StatelessWidget {
  const PanelOverlay({
    super.key,
    required this.child,
    required this.anchorKey,
    this.onDismiss,
    this.maxWidth,
    this.alignment = Alignment.topLeft,
  });

  /// The content of the panel.
  final Widget child;

  /// GlobalKey of the anchor widget (toolbar button).
  final GlobalKey anchorKey;

  /// Callback when the panel should be dismissed.
  final VoidCallback? onDismiss;

  /// Maximum width of the panel (defaults to theme's panelMaxWidth).
  final double? maxWidth;

  /// Alignment of the panel relative to the anchor.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        children: [
          // Transparent barrier
          Positioned.fill(
            child: Container(color: Colors.transparent),
          ),
          // Panel
          Positioned(
            left: _calculateLeftPosition(context),
            top: _calculateTopPosition(context),
            child: GestureDetector(
              onTap: () {}, // Prevent tap from dismissing
              child: Material(
                elevation: theme.panelElevation,
                borderRadius: BorderRadius.circular(theme.panelBorderRadius),
                color: theme.panelBackground,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth ?? theme.panelMaxWidth,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(theme.panelBorderRadius),
                    border: Border.all(
                      color: theme.panelBorderColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(theme.panelBorderRadius),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateLeftPosition(BuildContext context) {
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = DrawingTheme.of(context);
    final panelWidth = maxWidth ?? theme.panelMaxWidth;

    // Try to center the panel under the anchor
    double left = position.dx + (renderBox.size.width / 2) - (panelWidth / 2);

    // Clamp to screen bounds
    left = left.clamp(8.0, screenWidth - panelWidth - 8);

    return left;
  }

  double _calculateTopPosition(BuildContext context) {
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;

    final position = renderBox.localToGlobal(Offset.zero);

    // Position below the anchor with some padding
    return position.dy + renderBox.size.height + 8;
  }
}

/// An animated panel overlay with fade and slide transitions.
class AnimatedPanelOverlay extends StatefulWidget {
  const AnimatedPanelOverlay({
    super.key,
    required this.child,
    required this.anchorKey,
    required this.isVisible,
    this.onDismiss,
    this.maxWidth,
  });

  /// The content of the panel.
  final Widget child;

  /// GlobalKey of the anchor widget.
  final GlobalKey anchorKey;

  /// Whether the panel is visible.
  final bool isVisible;

  /// Callback when the panel should be dismissed.
  final VoidCallback? onDismiss;

  /// Maximum width of the panel.
  final double? maxWidth;

  @override
  State<AnimatedPanelOverlay> createState() => _AnimatedPanelOverlayState();
}

class _AnimatedPanelOverlayState extends State<AnimatedPanelOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedPanelOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: PanelOverlay(
              anchorKey: widget.anchorKey,
              onDismiss: widget.onDismiss,
              maxWidth: widget.maxWidth,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Tap-to-dismiss scrim behind a phone drawer.
class DrawerScrim extends StatelessWidget {
  const DrawerScrim({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: 0.5,
          child: Container(color: Theme.of(context).colorScheme.scrim),
        ),
      ),
    );
  }
}

/// Phone drawer that slides in from the left edge.
class SlidingLeftDrawer extends StatelessWidget {
  const SlidingLeftDrawer({
    super.key,
    required this.isOpen,
    required this.width,
    required this.child,
  });

  final bool isOpen;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: ChromeDurations.normal,
      curve: Curves.easeInOut,
      left: isOpen ? 0 : -width,
      top: 0,
      bottom: 0,
      width: width,
      child: child,
    );
  }
}

/// Tablet side panel that animates its width open/closed without relaying out
/// its content.
class CollapsibleSidePanel extends StatelessWidget {
  const CollapsibleSidePanel({
    super.key,
    required this.width,
    required this.contentWidth,
    required this.child,
  });

  final double width;
  final double contentWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ChromeDurations.normal,
      curve: Curves.easeInOut,
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: contentWidth,
        minWidth: contentWidth,
        child: child,
      ),
    );
  }
}

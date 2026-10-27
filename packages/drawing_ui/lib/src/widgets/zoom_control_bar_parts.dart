import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Icon button used in the zoom overlay bar.
class ZoomBarIconButton extends StatelessWidget {
  /// Creates a 48dp icon button announced as [label].
  const ZoomBarIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;

  /// Screen-reader label.
  final String label;

  /// Whether the toggle is on (drawn brighter, announced as toggled).
  final bool isActive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: PhosphorIcon(
              icon,
              size: ElyanotesIcons.actionSize,
              color:
                  isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

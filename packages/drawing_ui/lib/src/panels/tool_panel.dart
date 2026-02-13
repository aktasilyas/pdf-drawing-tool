import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Base container for tool settings panels.
///
/// Provides consistent styling, header, and close behavior for all tool panels.
class ToolPanel extends StatelessWidget {
  const ToolPanel({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.headerActions,
    this.width,
  });

  /// Title displayed in the panel header.
  final String title;

  /// Content of the panel.
  final Widget child;

  /// Callback when close button is pressed.
  final VoidCallback? onClose;

  /// Optional actions to display in the header.
  final List<Widget>? headerActions;

  /// Width of the panel (defaults to theme's panelMaxWidth).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Yatay/dikey ekrana göre maxHeight ayarla
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final maxPanelHeight = isLandscape
        ? screenSize.height * 0.85  // Yatay: ekranın %85'i
        : screenSize.height * 0.7;  // Dikey: ekranın %70'i

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width ?? theme.panelMaxWidth,
        constraints: BoxConstraints(
          maxHeight: maxPanelHeight,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(theme.panelBorderRadius),
          boxShadow: [
            // Main shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 20.0 / 255.0),
              blurRadius: theme.panelElevation,
              offset: const Offset(0, 4),
            ),
            // Subtle ambient shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 8.0 / 255.0),
              blurRadius: theme.panelElevation * 2,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _PanelHeader(
              title: title,
              onClose: onClose,
              actions: headerActions,
            ),

            // Divider
            Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),

            // Content - use LayoutBuilder to conditionally scroll
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header for tool panels.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.onClose,
    this.actions,
  });

  final String title;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (actions != null) ...actions!,
          if (onClose != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    StarNoteIcons.close,
                    size: StarNoteIcons.panelSize,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section within a tool panel.
class PanelSection extends StatelessWidget {
  const PanelSection({
    super.key,
    required this.title,
    required this.child,
    this.isLocked = false,
    this.onLockedTap,
  });

  /// Title of the section.
  final String title;

  /// Content of the section.
  final Widget child;

  /// Whether this section is locked (premium feature).
  final bool isLocked;

  /// Callback when locked section is tapped.
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(StarNoteIcons.lock, size: 10, color: colorScheme.tertiary),
                    const SizedBox(width: 2),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (isLocked)
          _LockedSectionOverlay(onTap: onLockedTap, child: child)
        else
          child,
      ],
    );
  }
}

/// Overlay for locked (premium) sections.
class _LockedSectionOverlay extends StatelessWidget {
  const _LockedSectionOverlay({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Blurred content
          Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
          // Lock overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(StarNoteIcons.lock, color: colorScheme.tertiary, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A toggle option row for panels.
class PanelToggleRow extends StatelessWidget {
  const PanelToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: enabled ? colorScheme.onSurface : colorScheme.outline,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A button row for panel actions.
class PanelActionButton extends StatelessWidget {
  const PanelActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final bgColor = isPrimary
        ? colorScheme.primary
        : isDestructive
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerLowest;
    final fgColor = isPrimary
        ? colorScheme.onPrimary
        : isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

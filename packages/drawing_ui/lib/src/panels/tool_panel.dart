import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/panels/panel_controls.dart';

export 'package:drawing_ui/src/panels/panel_controls.dart';
export 'package:drawing_ui/src/panels/panel_section.dart';

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
    final brightness = Theme.of(context).brightness;

    // Yatay/dikey ekrana göre maxHeight ayarla
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final maxPanelHeight = isLandscape
        ? screenSize.height * 0.85 // Yatay: ekranın %85'i
        : screenSize.height * 0.7; // Dikey: ekranın %70'i

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
          boxShadow: DrawingShadows.panel(brightness),
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
                    padding: const EdgeInsets.all(ChromeSpacing.md),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: ChromeSpacing.lg,
        right: onClose == null ? ChromeSpacing.sm : 0,
        top: ChromeSpacing.xs,
        bottom: ChromeSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ChromeSizes.minTouchTarget,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (actions != null) ...actions!,
            if (onClose != null) PanelCloseButton(onTap: onClose!),
          ],
        ),
      ),
    );
  }
}

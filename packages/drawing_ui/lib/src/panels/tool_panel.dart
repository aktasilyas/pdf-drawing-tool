import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';

void _writeDebugLog({
  required String hypothesisId,
  required String message,
  Map<String, Object?> data = const {},
}) {
  try {
    final file = File(
      r'c:\Users\aktas\source\repos\starnote_drawing_workspace\.cursor\debug.log',
    );
    final payload = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
      'location': 'panels/tool_panel.dart',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    file.writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}

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

    // Yatay/dikey ekrana göre maxHeight ayarla
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final maxPanelHeight = isLandscape
        ? screenSize.height * 0.85  // Yatay: ekranın %85'i
        : screenSize.height * 0.7;  // Dikey: ekranın %70'i

    // #region agent log - H2: ToolPanel max height
    _writeDebugLog(
      hypothesisId: 'H2',
      message: 'tool_panel_max_height',
      data: {
        'title': title,
        'screenHeight': screenSize.height,
        'screenWidth': screenSize.width,
        'isLandscape': isLandscape,
        'maxPanelHeight': maxPanelHeight,
      },
    );
    // #endregion

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width ?? theme.panelMaxWidth,
        constraints: BoxConstraints(
          maxHeight: maxPanelHeight,
        ),
        decoration: BoxDecoration(
          color: theme.panelBackground,
          borderRadius: BorderRadius.circular(theme.panelBorderRadius),
          boxShadow: [
            // Main shadow
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: theme.panelElevation,
              offset: const Offset(0, 4),
            ),
            // Subtle ambient shadow
            BoxShadow(
              color: Colors.black.withAlpha(8),
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
              color: Colors.grey.shade200,
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: child,
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
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
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
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF666666),
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
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 10, color: Colors.orange),
                    SizedBox(width: 2),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
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
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.orange, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
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
              color: enabled ? const Color(0xFF333333) : Colors.grey,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: const Color(0xFF4F46E5),
              activeTrackColor: const Color(0xFF4F46E5).withAlpha(100),
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
    final bgColor = isPrimary
        ? const Color(0xFF4F46E5)
        : isDestructive
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFF3F4F6);
    final fgColor = isPrimary
        ? Colors.white
        : isDestructive
            ? const Color(0xFFDC2626)
            : const Color(0xFF374151);

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

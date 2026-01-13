import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/drawing_providers.dart';
import '../theme/drawing_theme.dart';

/// Top navigation bar (Row 1) - Navigation and document actions.
///
/// Contains:
/// - Left: Back, Camera, Crop, Mic buttons
/// - Center: Document tabs
/// - Right: Book, Home, Layers, Export, Grid, Settings, More buttons
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({
    super.key,
    this.onBackPressed,
  });

  /// Callback when back button is pressed.
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DrawingTheme.of(context);
    final gridVisible = ref.watch(gridVisibilityProvider);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.toolbarBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.panelBorderColor.withAlpha(50),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left actions
          _NavButton(
            icon: Icons.arrow_back,
            tooltip: 'Geri',
            onPressed: onBackPressed ?? () => _showPlaceholder(context, 'Geri'),
          ),
          _NavButton(
            icon: Icons.camera_alt_outlined,
            tooltip: 'Kamera',
            onPressed: () => _showPlaceholder(context, 'Kamera'),
          ),
          _NavButton(
            icon: Icons.crop,
            tooltip: 'Kırp',
            onPressed: () => _showPlaceholder(context, 'Kırp'),
          ),
          _NavButton(
            icon: Icons.mic_none,
            tooltip: 'Ses kaydı',
            onPressed: () => _showPlaceholder(context, 'Ses kaydı'),
          ),

          // Center - Document tabs
          Expanded(
            child: _DocumentTabs(),
          ),

          // Right actions
          _NavButton(
            icon: Icons.menu_book_outlined,
            tooltip: 'Okuyucu modu',
            onPressed: () => _showPlaceholder(context, 'Okuyucu modu'),
          ),
          _NavButton(
            icon: Icons.home_outlined,
            tooltip: 'Ana sayfa',
            onPressed: () => _showPlaceholder(context, 'Ana sayfa'),
          ),
          _NavButton(
            icon: Icons.layers_outlined,
            tooltip: 'Katmanlar',
            onPressed: () => _showPlaceholder(context, 'Katmanlar'),
          ),
          _NavButton(
            icon: Icons.ios_share,
            tooltip: 'Dışa aktar',
            onPressed: () => _showPlaceholder(context, 'Dışa aktar'),
          ),
          _NavButton(
            icon: gridVisible ? Icons.grid_on : Icons.grid_off,
            tooltip: gridVisible ? 'Izgarayı gizle' : 'Izgarayı göster',
            isActive: gridVisible,
            onPressed: () {
              ref.read(gridVisibilityProvider.notifier).state = !gridVisible;
            },
          ),
          _NavButton(
            icon: Icons.settings_outlined,
            tooltip: 'Ayarlar',
            onPressed: () => _showPlaceholder(context, 'Ayarlar'),
          ),
          _NavButton(
            icon: Icons.more_horiz,
            tooltip: 'Daha fazla',
            onPressed: () => _showPlaceholder(context, 'Daha fazla'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Yakında eklenecek'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Navigation button for the top bar.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.toolbarIconSelectedColor.withAlpha(25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.toolbarIconSelectedColor
                  : theme.toolbarIconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Document tabs in the center of the navigation bar.
class _DocumentTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Center(
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.panelBorderColor.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 16,
              color: theme.toolbarIconColor,
            ),
            const SizedBox(width: 6),
            Text(
              'İsimsiz not',
              style: TextStyle(
                fontSize: 13,
                color: theme.toolbarIconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: theme.toolbarIconColor,
            ),
          ],
        ),
      ),
    );
  }
}

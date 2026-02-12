import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/pdf_import_dialog.dart';
import 'package:drawing_ui/src/widgets/pdf_export_dialog.dart';

/// Top navigation bar (Row 1) - Navigation and document actions.
///
/// Contains:
/// - Left: Home button and document title
/// - Center: Document tabs (when multiple documents)
/// - Right: Layers, Export, Grid, Settings, More buttons
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onTitlePressed,
    this.onBackPressed,
    this.compact = false,
  });

  /// Document title to display.
  final String? documentTitle;

  /// Callback when home button is pressed.
  final VoidCallback? onHomePressed;

  /// Callback when document title is pressed (opens menu).
  final VoidCallback? onTitlePressed;

  /// Callback when back button is pressed.
  final VoidCallback? onBackPressed;

  /// Whether to use compact mode (phone) - shows minimal buttons.
  final bool compact;

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
            color: theme.panelBorderColor.withValues(alpha: 50.0 / 255.0),
            width: 0.5,
          ),
        ),
      ),
      child: compact
          ? _buildCompactLayout(theme)
          : _buildFullLayout(context, ref, theme, gridVisible),
    );
  }

  /// Build compact layout (phone) - minimal buttons only.
  Widget _buildCompactLayout(DrawingTheme theme) => Row(children: [
        _NavButton(icon: Icons.home_rounded, tooltip: 'Ana Sayfa', onPressed: onHomePressed ?? () {}),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTitlePressed ?? () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.panelBorderColor.withValues(alpha: 30.0 / 255.0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(documentTitle ?? 'İsimsiz Not',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.toolbarIconColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: theme.toolbarIconColor),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NavButton(icon: Icons.ios_share, tooltip: 'Paylaş', onPressed: () {}),
        _NavButton(icon: Icons.more_vert, tooltip: 'Daha fazla', onPressed: () {}),
        const SizedBox(width: 4),
      ]);

  /// Build full layout (tablet/desktop) - all buttons visible.
  Widget _buildFullLayout(BuildContext context, WidgetRef ref, DrawingTheme theme, bool gridVisible) =>
      LayoutBuilder(builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;
        return Row(children: [
          _NavButton(icon: Icons.home_rounded, tooltip: 'Ana Sayfa', onPressed: onHomePressed ?? () => _showPlaceholder(context, 'Ana Sayfa')),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onTap: onTitlePressed ?? () => _showPlaceholder(context, 'Belge Menüsü'),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.panelBorderColor.withValues(alpha: 30.0 / 255.0), borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                      child: Text(documentTitle ?? 'İsimsiz Not',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.toolbarIconColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: theme.toolbarIconColor),
                ]),
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
          if (!isSmallScreen) _NavButton(icon: Icons.menu_book_outlined, tooltip: 'Okuyucu modu', onPressed: () => _showPlaceholder(context, 'Okuyucu modu')),
          _NavButton(icon: Icons.layers_outlined, tooltip: 'Katmanlar', onPressed: () => _showPlaceholder(context, 'Katmanlar')),
          _NavButton(
              icon: gridVisible ? Icons.grid_on : Icons.grid_off,
              tooltip: gridVisible ? 'Izgarayı gizle' : 'Izgarayı göster',
              isActive: gridVisible,
              onPressed: () => ref.read(gridVisibilityProvider.notifier).state = !gridVisible),
          if (!isSmallScreen) ...[
            _NavButton(icon: Icons.upload_file, tooltip: 'PDF İçe Aktar', onPressed: () => _showPDFImportDialog(context, ref)),
            _NavButton(icon: Icons.picture_as_pdf, tooltip: 'PDF Olarak Dışa Aktar', onPressed: () => _showPDFExportDialog(context, ref)),
          ],
          _NavButton(icon: Icons.more_horiz, tooltip: 'Daha fazla', onPressed: () => _showPlaceholder(context, 'Daha fazla')),
          const SizedBox(width: 4),
        ]);
      });

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Yakında eklenecek'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPDFImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => PDFImportDialog(
        onImportComplete: (result) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${result.pageCount} sayfa içe aktarıldı'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPDFExportDialog(BuildContext context, WidgetRef ref) {
    final pageCount = ref.read(pageCountProvider);

    showDialog(
      context: context,
      builder: (context) => PDFExportDialog(
        totalPages: pageCount,
        onExport: (config) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF dışa aktarılıyor...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.toolbarIconSelectedColor.withValues(alpha: 25.0 / 255.0)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
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
// ignore: unused_element
class _DocumentTabs extends StatelessWidget {
  const _DocumentTabs();

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);

    return Center(
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.panelBorderColor.withValues(alpha: 30.0 / 255.0),
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

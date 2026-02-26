import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/infinite_background_panel.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/pdf_import_dialog.dart';
import 'package:drawing_ui/src/widgets/pdf_export_dialog.dart';

/// Shows export/share bottom sheet menu.
///
/// Options: PDF export, image export (future), share (future).
void showExportMenu(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.exportIcon,
              color: colorScheme.onSurface,
            ),
            title: const Text('PDF İçe Aktar'),
            onTap: () {
              Navigator.pop(ctx);
              _showPDFImportDialog(context, ref);
            },
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.pdfFile,
              color: colorScheme.onSurface,
            ),
            title: const Text('PDF Olarak Dışa Aktar'),
            onTap: () {
              Navigator.pop(ctx);
              _showPDFExportDialog(context, ref);
            },
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.image,
              color: colorScheme.onSurface,
              size: StarNoteIcons.navSize,
            ),
            title: const Text('Resim Olarak Dışa Aktar'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.share,
              color: colorScheme.onSurface,
              size: StarNoteIcons.navSize,
            ),
            title: const Text('Paylaş'),
            enabled: false,
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Shows background options for infinite/whiteboard canvas mode.
void showInfiniteBackgroundMenu(BuildContext context) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;

  if (isTablet) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 56, right: 8),
          child: InfiniteBackgroundPanel(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: InfiniteBackgroundPanel(onClose: () => Navigator.pop(ctx)),
      ),
    );
  }
}

/// Shows page options popup.
///
/// On tablet (>=600px): floating dialog positioned top-right below toolbar.
/// On phone (<600px): modal bottom sheet.
///
/// Optional params add document info and hidden-button actions to the panel
/// (used by the phone compact layout to consolidate toolbar items).
void showMoreMenu(
  BuildContext context,
  WidgetRef ref, {
  String? documentTitle,
  VoidCallback? onRenameDocument,
  VoidCallback? onDeleteDocument,
  bool showAddPage = false,
  bool showExport = false,
  bool compact = false,
}) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;

  if (isTablet) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 56, right: 8),
          child: PageOptionsPanel(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: PageOptionsPanel(
            onClose: () => Navigator.pop(ctx),
            documentTitle: documentTitle,
            onRenameDocument: onRenameDocument,
            onDeleteDocument: onDeleteDocument,
            compact: compact,
            onAddPage: showAddPage
                ? () {
                    Navigator.pop(ctx);
                    showAddPageMenu(context);
                  }
                : null,
            onExport: showExport
                ? () {
                    Navigator.pop(ctx);
                    showExportMenu(context, ref);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

/// Shows the "Add Page" popup panel.
///
/// On tablet (>=600px): floating dialog positioned top-right below toolbar.
/// On phone (<600px): modal bottom sheet with draggable sheet.
void showAddPageMenu(BuildContext context) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;

  if (isTablet) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 56, right: 8),
          child: AddPagePanel(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: AddPagePanel(
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }
}

/// Shows audio recording bottom sheet menu (compact/phone layout).
void showAudioMenu(
  BuildContext context,
  WidgetRef ref,
  VoidCallback? onSidebarToggle,
  bool isSidebarOpen,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final isActive = ref.read(isRecordingProvider);

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          if (isActive)
            ListTile(
              leading: PhosphorIcon(
                StarNoteIcons.recordCircle,
                color: colorScheme.onSurface,
              ),
              title: const Text('Kayit devam ediyor...'),
              enabled: false,
            )
          else
            ListTile(
              leading: PhosphorIcon(
                StarNoteIcons.recordCircle,
                color: colorScheme.onSurface,
              ),
              title: const Text('Kaydet'),
              onTap: () async {
                final service = ref.read(audioRecordingServiceProvider);
                final hasPerms = await service.hasPermission();
                if (!hasPerms) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mikrofon izni gerekli. '
                            'Lütfen ayarlardan izin verin.'),
                      ),
                    );
                  }
                  return;
                }
                final started = await service.startRecording();
                if (started && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
            ),
          ListTile(
            leading: PhosphorIcon(
              StarNoteIcons.waveform,
              color: colorScheme.onSurface,
            ),
            title: const Text('Kayitlari goster'),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(sidebarFilterProvider.notifier).state =
                  SidebarFilter.recordings;
              if (!isSidebarOpen) onSidebarToggle?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Private helpers ──

void _showPDFImportDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
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

  showDialog<void>(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/infinite_background_panel.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Shows the export options as a bottom sheet (phone layout).
///
/// Same options and export path as the tablet [ExportPanel] popover:
/// PDF for paged documents, PNG for the infinite canvas.
void showExportMenu(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ExportPanel(
        embedded: true,
        onClose: () => Navigator.pop(ctx),
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
  // Read before any await: the tap handler below is async.
  final s = context.drawingStrings.toolbar;
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
                ElyanotesIcons.recordCircle,
                color: colorScheme.onSurface,
              ),
              title: Text(s.recordingInProgress),
              enabled: false,
            )
          else
            ListTile(
              leading: PhosphorIcon(
                ElyanotesIcons.recordCircle,
                color: colorScheme.onSurface,
              ),
              title: Text(s.record),
              onTap: () async {
                final service = ref.read(audioRecordingServiceProvider);
                final hasPerms = await service.hasPermission();
                if (!hasPerms) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.micPermissionRequired),
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
              ElyanotesIcons.waveform,
              color: colorScheme.onSurface,
            ),
            title: Text(s.showRecordings),
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

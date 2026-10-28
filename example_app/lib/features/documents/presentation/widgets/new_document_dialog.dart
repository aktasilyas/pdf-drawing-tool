import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_quota.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_importers.dart';
import 'package:example_app/features/premium/premium.dart';

/// Dropdown menü item'ları
enum NewDocumentOption {
  notebook, // 📓 Not Defteri - şablon seçimi göster
  whiteboard, // 🔲 Beyaz Tahta - direkt aç (infinite canvas + blank)
  quickNote, // ✏️ Hızlı Not - direkt aç
  importPdf, // 📄 PDF İçe Aktar - dosya seç, direkt aç
  importImage, // 🖼️ Resim İçe Aktar - dosya seç, direkt aç
}

/// Yeni doküman dropdown menüsünü gösterir.
/// Eğer toplam belge limiti aşıldıysa dropdown yerine upgrade sheet gösterir.
void showNewDocumentDropdown(BuildContext context, GlobalKey buttonKey) async {
  // Unified total document limit check; shows the upgrade sheet when reached.
  if (!await ensureDocumentQuota(context)) return;
  if (!context.mounted) return;

  final l10n = context.l10n;
  final RenderBox button =
      buttonKey.currentContext!.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

  showMenu<NewDocumentOption>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy + button.size.height + 4,
      position.dx + button.size.width,
      position.dy + button.size.height + 300,
    ),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    items: [
      _buildMenuItem(l10n, NewDocumentOption.notebook, Icons.book_outlined),
      _buildMenuItem(
        l10n,
        NewDocumentOption.whiteboard,
        Icons.space_dashboard_outlined,
      ),
      _buildMenuItem(l10n, NewDocumentOption.quickNote, Icons.note_outlined),
      const PopupMenuDivider(height: 1),
      _buildMenuItem(
        l10n,
        NewDocumentOption.importPdf,
        Icons.picture_as_pdf_outlined,
      ),
      _buildMenuItem(
        l10n,
        NewDocumentOption.importImage,
        Icons.image_outlined,
      ),
    ],
  ).then((value) {
    if (value == null) return;
    if (!context.mounted) return;
    _handleNewDocumentOption(context, value);
  });
}

PopupMenuItem<NewDocumentOption> _buildMenuItem(
  AppLocalizations l10n,
  NewDocumentOption option,
  IconData icon,
) {
  final label = option.label(l10n);
  return PopupMenuItem<NewDocumentOption>(
    value: option,
    padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    height: 52,
    child: Builder(
      builder: (context) {
        final iconColor = context.palette.accent;
        final iconBg = context.palette.surfaceElevated;
        final textPrimary = context.palette.textPrimary;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppIconSize.sm, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: textPrimary),
              ),
            ),
          ],
        );
      },
    ),
  );
}

void _handleNewDocumentOption(
    BuildContext context, NewDocumentOption option) async {
  // Unified total document limit already checked in showNewDocumentDropdown.
  // If dropdown is shown, user is within limit.
  if (!context.mounted) return;

  switch (option) {
    case NewDocumentOption.notebook:
      context.push(RouteNames.templateSelection);
    case NewDocumentOption.whiteboard:
      _createWhiteboard(context);
    case NewDocumentOption.quickNote:
      _createQuickNote(context);
    case NewDocumentOption.importPdf:
      importPdf(context);
    case NewDocumentOption.importImage:
      importImage(context);
  }
}

void _createQuickNote(BuildContext context) async {
  if (!context.mounted) return;
  final l10n = context.l10n;

  final container = ProviderScope.containerOf(context);
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);

  // Varsayılan ayarlarla hızlı not oluştur (beyaz kağıt + ince çizgili)
  final documentId = await controller.createDocument(
    title: l10n.libraryQuickNoteTitle(_nowStamp()),
    templateId: 'thin_lined', // İnce çizgili şablon
    folderId: folderId,
    paperColor: PaperColor.white.storageKey,
    isPortrait: true,
    documentType: drawing_core.DocumentType.quickNote,
  );

  // Refresh providers to update folder counts and document lists
  if (documentId != null) {
    container.invalidate(foldersProvider);
    container.invalidate(documentsProvider);
    container.invalidate(totalDocumentCountProvider);
    container.invalidate(notebookCountProvider);
  }

  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push(RouteNames.editorPath(documentId));
  }
}

void _createWhiteboard(BuildContext context) async {
  if (!context.mounted) return;
  final l10n = context.l10n;

  final container = ProviderScope.containerOf(context);
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);

  // Beyaz tahta oluştur (infinite canvas + blank background)
  final documentId = await controller.createDocument(
    title: l10n.libraryWhiteboardTitle(_nowStamp()),
    templateId: 'blank', // Boş arka plan
    folderId: folderId,
    paperColor: PaperColor.white.storageKey,
    isPortrait: true,
    documentType: drawing_core.DocumentType.whiteboard, // Infinite canvas
  );

  // Refresh providers to update folder counts and document lists
  if (documentId != null) {
    container.invalidate(foldersProvider);
    container.invalidate(documentsProvider);
    container.invalidate(totalDocumentCountProvider);
    container.invalidate(notebookCountProvider);
  }

  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push(RouteNames.editorPath(documentId));
  }
}

/// Date part of generated titles (`yyyy-MM-dd HH:mm`), stored with the title.
String _nowStamp() => DateTime.now().toString().substring(0, 16);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_importers.dart';

/// Dropdown menü item'ları
enum NewDocumentOption {
  notebook,    // 📓 Not Defteri - şablon seçimi göster
  whiteboard,  // 🔲 Beyaz Tahta - direkt aç (infinite canvas + blank)
  quickNote,   // ✏️ Hızlı Not - direkt aç
  importPdf,   // 📄 PDF İçe Aktar - dosya seç, direkt aç
  importImage, // 🖼️ Resim İçe Aktar - dosya seç, direkt aç
}

/// Yeni doküman dropdown menüsünü gösterir
void showNewDocumentDropdown(BuildContext context, GlobalKey buttonKey) {
  final RenderBox button = buttonKey.currentContext!.findRenderObject() as RenderBox;
  final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

  showMenu<NewDocumentOption>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy + button.size.height + 4,
      position.dx + button.size.width,
      position.dy + button.size.height + 300,
    ),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    items: [
      _buildMenuItem(NewDocumentOption.notebook, Icons.book_outlined, 'Not Defteri'),
      _buildMenuItem(NewDocumentOption.whiteboard, Icons.space_dashboard_outlined, 'Beyaz Tahta'),
      _buildMenuItem(NewDocumentOption.quickNote, Icons.note_outlined, 'Hızlı Not'),
      const PopupMenuDivider(height: 1),
      _buildMenuItem(NewDocumentOption.importPdf, Icons.picture_as_pdf_outlined, 'PDF İçe Aktar'),
      _buildMenuItem(NewDocumentOption.importImage, Icons.image_outlined, 'Resim İçe Aktar'),
    ],
  ).then((value) {
    if (value == null) return;
    if (!context.mounted) return;
    _handleNewDocumentOption(context, value);
  });
}

PopupMenuItem<NewDocumentOption> _buildMenuItem(
  NewDocumentOption option,
  IconData icon,
  String label,
) {
  return PopupMenuItem<NewDocumentOption>(
    value: option,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    height: 52,
    child: Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    ),
  );
}

void _handleNewDocumentOption(BuildContext context, NewDocumentOption option) async {
  switch (option) {
    case NewDocumentOption.notebook:
      // Template Selection Screen'e yönlendir (Not Defteri)
      if (context.mounted) {
        context.push(RouteNames.templateSelection);
      }
      break;

    case NewDocumentOption.whiteboard:
      // Beyaz tahta - direkt aç (infinite canvas + blank background)
      _createWhiteboard(context);
      break;

    case NewDocumentOption.quickNote:
      // Hızlı not oluştur
      _createQuickNote(context);
      break;
    case NewDocumentOption.importPdf:
      // PDF içe aktar
      importPdf(context);
      break;
    case NewDocumentOption.importImage:
      // Resim içe aktar
      importImage(context);
      break;
  }
}

void _createQuickNote(BuildContext context) async {
  if (!context.mounted) return;

  final container = ProviderScope.containerOf(context);
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);

  // Varsayılan ayarlarla hızlı not oluştur (beyaz kağıt + ince çizgili)
  final documentId = await controller.createDocument(
    title: 'Hızlı Not - ${DateTime.now().toString().substring(0, 16)}',
    templateId: 'thin_lined', // İnce çizgili şablon
    folderId: folderId,
    paperColor: 'Beyaz kağıt',
    isPortrait: true,
    documentType: drawing_core.DocumentType.quickNote,
  );

  // Refresh providers to update folder counts and document lists
  if (documentId != null) {
    container.invalidate(foldersProvider);
    container.invalidate(documentsProvider);
  }

  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push(RouteNames.editorPath(documentId));
  }
}

void _createWhiteboard(BuildContext context) async {
  if (!context.mounted) return;

  final container = ProviderScope.containerOf(context);
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);

  // Beyaz tahta oluştur (infinite canvas + blank background)
  final documentId = await controller.createDocument(
    title: 'Beyaz Tahta - ${DateTime.now().toString().substring(0, 16)}',
    templateId: 'blank', // Boş arka plan
    folderId: folderId,
    paperColor: 'Beyaz kağıt',
    isPortrait: true,
    documentType: drawing_core.DocumentType.whiteboard, // Infinite canvas
  );

  // Refresh providers to update folder counts and document lists
  if (documentId != null) {
    container.invalidate(foldersProvider);
    container.invalidate(documentsProvider);
  }

  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push(RouteNames.editorPath(documentId));
  }
}

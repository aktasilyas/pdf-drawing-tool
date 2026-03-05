import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_importers.dart';
import 'package:example_app/features/premium/premium.dart';

/// Dropdown menü item'ları
enum NewDocumentOption {
  notebook,    // 📓 Not Defteri - şablon seçimi göster
  whiteboard,  // 🔲 Beyaz Tahta - direkt aç (infinite canvas + blank)
  quickNote,   // ✏️ Hızlı Not - direkt aç
  importPdf,   // 📄 PDF İçe Aktar - dosya seç, direkt aç
  importImage, // 🖼️ Resim İçe Aktar - dosya seç, direkt aç
}

/// Yeni doküman dropdown menüsünü gösterir.
/// Eğer toplam belge limiti aşıldıysa dropdown yerine upgrade sheet gösterir.
void showNewDocumentDropdown(BuildContext context, GlobalKey buttonKey) async {
  // Unified total document limit check
  final container = ProviderScope.containerOf(context);
  final totalCount = await container.read(totalDocumentCountProvider.future);
  final access = container.read(featureAccessProvider(
    FeatureAccessParams(
      feature: GatedFeature.createDocument,
      currentUsage: totalCount,
    ),
  ));

  if (!context.mounted) return;

  // If limit reached, show general upgrade sheet instead of dropdown
  if (!access.isAllowed) {
    await UpgradePromptSheet.show(
      context,
      access: access,
      featureIcon: Icons.note_add_outlined,
      featureTitle: 'Belge Limitine Ulaştınız',
      onUpgrade: () {
        Navigator.pop(context);
        GoRouter.of(context).push(RouteNames.paywall);
      },
    );
    return;
  }

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
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
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
    padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    height: 52,
    child: Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor =
            isDark ? AppColors.primaryDarkMode : AppColors.primary;
        final iconBg = isDark
            ? AppColors.surfaceContainerHighDark
            : AppColors.surfaceContainerHighLight;
        final textPrimary =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

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
                style:
                    AppTypography.bodyMedium.copyWith(color: textPrimary),
              ),
            ),
          ],
        );
      },
    ),
  );
}

void _handleNewDocumentOption(BuildContext context, NewDocumentOption option) async {
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
    container.invalidate(totalDocumentCountProvider);
    container.invalidate(notebookCountProvider);
  }

  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push(RouteNames.editorPath(documentId));
  }
}

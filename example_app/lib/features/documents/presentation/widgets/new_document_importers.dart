import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:drawing_ui/drawing_ui.dart'
    show
        ImagePage,
        ImagePageImportError,
        ImagePageImportException,
        discardImportedImagePage,
        importImagePage,
        maxImagePageEdge,
        pdfPathResolverProvider;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/pdf_file_importer.dart';
import 'package:example_app/features/premium/premium.dart';

/// PDF içe aktarma işlemini yönetir
Future<void> importPdf(BuildContext context) async {
  // Unified document limit is already checked in showNewDocumentDropdown.

  final l10n = context.l10n;
  // PDF dosyası seç (withData: false - RAM'e yüklemeden sadece yol al)
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: false,
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  final filePath = file.path;
  if (filePath == null || filePath.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.libraryPdfReadFailed)),
    );
    return;
  }

  if (!context.mounted) return;
  await importPdfFile(
    context,
    path: filePath,
    name: file.name,
    size: file.size,
  );
}

/// Resim içe aktarma işlemini yönetir
Future<void> importImage(BuildContext context) async {
  final l10n = context.l10n;
  // 1. Resim seç (yalnızca yol; bayt okuma importImagePage'de)
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: false,
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  final filePath = file.path;
  if (filePath == null || filePath.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryImageReadFailed)),
      );
    }
    return;
  }

  if (!context.mounted) return;
  await importImageFile(context, path: filePath, name: file.name);
}

/// Imports the image at [path] as a new one-page notebook named after [name]
/// and opens it. Failures show localized copy only; the error is logged.
Future<void> importImageFile(
  BuildContext context, {
  required String path,
  required String name,
}) async {
  final l10n = context.l10n;
  // 2. Loading göster
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: AppSpacing.lg),
          Text(l10n.libraryImageLoading),
        ],
      ),
    ),
  );

  try {
    // 3. Doğrula, uygulama klasörüne kopyala, dosya referansı al
    final paths = ProviderScope.containerOf(context, listen: false)
        .read(pdfPathResolverProvider);
    final ImagePage imagePage;
    try {
      imagePage = await importImagePage(
        path,
        documentsRoot: paths.documentsRoot ??
            (await getApplicationDocumentsDirectory()).path,
        paths: paths,
        maxDimension: maxImagePageEdge,
      );
    } on ImagePageImportException catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.error == ImagePageImportError.tooLarge
                  ? l10n.libraryImageTooLarge
                  : l10n.libraryImageReadFailed,
            ),
          ),
        );
      }
      return;
    }

    // Sayfa oluştur
    final now = DateTime.now();
    final page = drawing_core.Page(
      id: 'page_${now.millisecondsSinceEpoch}_0',
      index: 0,
      size: imagePage.size,
      background: imagePage.background.copyWith(color: 0xFFFFFFFF),
      layers: [drawing_core.Layer.empty('Layer 1')],
      createdAt: now,
      updatedAt: now,
    );

    // 5. Doküman oluştur
    if (!context.mounted) {
      await discardImportedImagePage(imagePage, paths: paths);
      return;
    }
    final container = ProviderScope.containerOf(context);
    final controller = container.read(documentsControllerProvider.notifier);
    final folderId = container.read(currentFolderIdProvider);

    final title = name.replaceAll(
      RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)$', caseSensitive: false),
      '',
    );

    final documentId = await controller.createDocumentWithPages(
      title: title,
      folderId: folderId,
      documentType: drawing_core.DocumentType.image,
      pages: [page.toJson()],
      pageCount: 1,
    );
    if (documentId == null) {
      await discardImportedImagePage(imagePage, paths: paths);
    }

    // Refresh providers to update folder counts and document lists
    if (documentId != null) {
      container.invalidate(foldersProvider);
      container.invalidate(documentsProvider);
      container.invalidate(totalDocumentCountProvider);
      container.invalidate(pdfImportCountProvider);
      container.invalidate(notebookCountProvider);
    }

    // Loading kapat
    if (context.mounted) Navigator.pop(context);
    // Editor'e yönlendir
    if (documentId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.libraryOpening(title)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      context.push(RouteNames.editorPath(documentId));
    }
  } catch (e, st) {
    logger.e('Image import failed', error: e, stackTrace: st);
    // Loading dialog'u kapat (eğer açıksa)
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.libraryErrorImportDocument),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

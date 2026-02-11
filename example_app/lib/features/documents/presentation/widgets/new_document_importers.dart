import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'dart:ui' as ui;

/// PDF içe aktarma işlemini yönetir
Future<void> importPdf(BuildContext context) async {
  // 1. PDF dosyası seç (withData: false - RAM'e yüklemeden sadece yol al)
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
      const SnackBar(content: Text('PDF dosyası okunamadı')),
    );
    return;
  }

  // Dosya boyutu kontrolü (max 200MB)
  const maxFileSizeBytes = 200 * 1024 * 1024;
  if (file.size > maxFileSizeBytes) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF dosyası çok büyük! Maksimum boyut: 200MB'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // 2. Loading göster
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'PDF açılıyor...',
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
          ),
        ],
      ),
    ),
  );

  // Save references before async gap
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  // Track dialog state to prevent double-pop crash
  bool isDialogOpen = true;
  void closeLoadingDialog() {
    if (isDialogOpen && context.mounted) {
      isDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  PDFImportService? importService;
  try {
    // PDF Import Service kullan (dosya yolu ile - RAM tasarrufu)
    importService = PDFImportService();
    final importResult = await importService.importFromFile(
      filePath: filePath,
      config: PDFImportConfig.all(),
    );
    // Loading dialog kapat
    closeLoadingDialog();

    if (!importResult.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(importResult.errorMessage ?? 'PDF import başarısız'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Doküman oluştur
    if (!context.mounted) return;
    final container = ProviderScope.containerOf(context);
    final controller = container.read(documentsControllerProvider.notifier);
    final folderId = container.read(currentFolderIdProvider);

    final title = file.name.replaceAll('.pdf', '');
    final pagesJson = importResult.pages.map((page) => page.toJson()).toList();

    final documentId = await controller.createDocumentWithPages(
      title: title,
      folderId: folderId,
      documentType: drawing_core.DocumentType.pdf,
      pages: pagesJson,
      pageCount: importResult.pages.length,
    );

    // Refresh providers to update folder counts and document lists
    if (documentId != null) {
      container.invalidate(foldersProvider);
      container.invalidate(documentsProvider);
    }
    // Editor'e git
    if (documentId != null && context.mounted) {
      // State güncelle
      if (importResult.pages.isNotEmpty) {
        final firstPage = importResult.pages.first;
        if (firstPage.background.pdfFilePath != null) {
          container.read(currentPdfFilePathProvider.notifier).state =
              firstPage.background.pdfFilePath!;
          container.read(totalPdfPagesProvider.notifier).state =
              importResult.pages.length;
          container.read(visiblePdfPageProvider.notifier).state = 0;
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('$title açılıyor (${importResult.pages.length} sayfa)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      router.push(RouteNames.editorPath(documentId));
    }
  } catch (e) {
    // Loading dialog'u kapat (sadece henüz kapatılmadıysa)
    closeLoadingDialog();

    // Hata mesajı göster
    messenger.showSnackBar(
      SnackBar(
        content: Text('PDF yüklenirken hata: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    importService?.dispose();
  }
}

/// Resim içe aktarma işlemini yönetir
Future<void> importImage(BuildContext context) async {
  // 1. Resim seç
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  if (file.bytes == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim dosyası okunamadı')),
      );
    }
    return;
  }

  // 2. Loading göster
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: AppSpacing.lg),
          Text('Resim yükleniyor...'),
        ],
      ),
    ),
  );

  try {
    // 3. Resim boyutunu al
    final codec = await ui.instantiateImageCodec(file.bytes!);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Boyut kontrolü
    if (imageWidth > 4096 || imageHeight > 4096) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim çok büyük! Maksimum boyut: 4096x4096'),
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
      size: drawing_core.PageSize(width: imageWidth, height: imageHeight),
      background: drawing_core.PageBackground(
        type: drawing_core.BackgroundType.pdf,
        color: 0xFFFFFFFF,
        pdfData: file.bytes,
        pdfPageIndex: 1,
      ),
      layers: [drawing_core.Layer.empty('Layer 1')],
      createdAt: now,
      updatedAt: now,
    );

    // 5. Doküman oluştur
    if (!context.mounted) return;
    final container = ProviderScope.containerOf(context);
    final controller = container.read(documentsControllerProvider.notifier);
    final folderId = container.read(currentFolderIdProvider);

    final title = file.name.replaceAll(
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

    // Refresh providers to update folder counts and document lists
    if (documentId != null) {
      container.invalidate(foldersProvider);
      container.invalidate(documentsProvider);
    }

    // Loading kapat
    if (context.mounted) Navigator.pop(context);
    // Editor'e yönlendir
    if (documentId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title açılıyor'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      context.push(RouteNames.editorPath(documentId));
    }

  } catch (e) {
    // Loading dialog'u kapat (eğer açıksa)
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

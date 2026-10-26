import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:file_picker/file_picker.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/pdf_file_importer.dart';
import 'package:example_app/features/premium/premium.dart';
import 'dart:ui' as ui;

/// PDF içe aktarma işlemini yönetir
Future<void> importPdf(BuildContext context) async {
  // Unified document limit is already checked in showNewDocumentDropdown.

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
      const SnackBar(content: Text('PDF dosyası okunamadı')),
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
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

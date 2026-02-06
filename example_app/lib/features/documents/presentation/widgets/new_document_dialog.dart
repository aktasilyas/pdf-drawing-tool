import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'dart:ui' as ui;

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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    height: 52,
    child: Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
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
      _importPdf(context);
      break;
    case NewDocumentOption.importImage:
      // Resim içe aktar
      _importImage(context);
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

void _importPdf(BuildContext context) async {
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
          const SizedBox(width: 16),
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
    // 3. PDF Import Service kullan (dosya yolu ile - RAM tasarrufu)
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

    // 4. Doküman oluştur
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

    // 5. Editor'e git
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

void _importImage(BuildContext context) async {
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
          SizedBox(width: 16),
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
    
    // 4. Sayfa oluştur
    final page = drawing_core.Page(
      id: 'page_${DateTime.now().millisecondsSinceEpoch}_0',
      index: 0,
      size: drawing_core.PageSize(width: imageWidth, height: imageHeight),
      background: drawing_core.PageBackground(
        type: drawing_core.BackgroundType.pdf,
        color: 0xFFFFFFFF,
        pdfData: file.bytes,
        pdfPageIndex: 1,
      ),
      layers: [drawing_core.Layer.empty('Layer 1')],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    
    // 6. Loading kapat
    if (context.mounted) Navigator.pop(context);
    
    // 7. Editor'e yönlendir
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

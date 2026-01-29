import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart' as drawing_core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'dart:ui' as ui;

/// Dropdown menü item'ları
enum NewDocumentOption {
  notebook,    // 📓 Not Defteri - şablon seçimi göster
  whiteboard,  // 🔲 Beyaz Tahta - şablon seçimi göster  
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
    case NewDocumentOption.whiteboard:
      // Yeni TemplatePicker ile şablon seçimi
      await _showTemplatePickerAndCreate(context, option);
      break;
    case NewDocumentOption.quickNote:
      // Direkt aç - varsayılan ayarlar
      _createQuickNote(context);
      break;
    case NewDocumentOption.importPdf:
      // PDF dosya seçici
      _importPdf(context);
      break;
    case NewDocumentOption.importImage:
      // Resim dosya seçici
      _importImage(context);
      break;
  }
}

Future<void> _showTemplatePickerAndCreate(
  BuildContext context,
  NewDocumentOption option,
) async {
  if (!context.mounted) return;
  
  final container = ProviderScope.containerOf(context);
  
  // Premium durumunu kontrol et (TODO: gerçek premium provider eklenecek)
  final isPremiumUser = false; // TODO: ref.watch(premiumProvider)
  
  // TemplatePicker'ı göster
  final result = await TemplatePicker.show(
    context,
    isLocked: (template) => template.isPremium && !isPremiumUser,
    onPremiumTap: () {
      // TODO: Premium dialog göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu şablon premium üyelere özeldir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  );
  
  if (result == null || !context.mounted) return;
  
  // Yeni Template'den eski templateId'ye mapping
  String mappedTemplateId = _mapNewTemplateToOldId(result.template);
  
  // Template'den paperColor çıkar
  String paperColor = _mapTemplateToColor(result.template);
  
  // PaperSize'dan orientation çıkar
  bool isPortrait = !result.paperSize.isLandscape;
  
  // Doküman oluştur
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);
  
  final documentType = option == NewDocumentOption.notebook 
      ? drawing_core.DocumentType.notebook 
      : drawing_core.DocumentType.whiteboard;
  
  final title = documentType == drawing_core.DocumentType.notebook
      ? 'Adsız Not Defteri'
      : 'Adsız Beyaz Tahta';
  
  final documentId = await controller.createDocument(
    title: title,
    templateId: mappedTemplateId,
    folderId: folderId,
    paperColor: paperColor,
    isPortrait: isPortrait,
    documentType: documentType,
  );
  
  if (documentId != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title oluşturuldu'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    
    context.push('/editor/$documentId');
  }
}

/// Yeni Template'i eski templateId'ye map et (geçici çözüm)
String _mapNewTemplateToOldId(drawing_core.Template newTemplate) {
  // Pattern bazlı mapping
  switch (newTemplate.pattern) {
    case drawing_core.TemplatePattern.blank:
      return 'blank';
    case drawing_core.TemplatePattern.thinLines:
      return 'thin_lined';
    case drawing_core.TemplatePattern.thickLines:
      return 'thick_lined';
    case drawing_core.TemplatePattern.smallDots:
      return 'dotted';
    case drawing_core.TemplatePattern.smallGrid:
      return 'small_grid';
    case drawing_core.TemplatePattern.largeGrid:
      return 'large_grid';
    case drawing_core.TemplatePattern.cornell:
      return 'cornell';
    default:
      return 'blank'; // Fallback
  }
}

/// Template'in defaultBackgroundColor'ını paperColor string'ine map et
String _mapTemplateToColor(drawing_core.Template template) {
  final colorValue = template.defaultBackgroundColor;
  
  // ARGB formatından renk tespiti
  switch (colorValue) {
    case 0xFFFFFFFF: // Beyaz
      return 'Beyaz kağıt';
    case 0xFFFFFDE7: // Sarı (Light Yellow 50)
    case 0xFFFFF9C4: // Sarı (Light Yellow 100)
      return 'Sarı kağıt';
    case 0xFFF5F5F5: // Gri (Grey 100)
    case 0xFFEEEEEE: // Gri (Grey 200)
      return 'Gri kağıt';
    default:
      // Default olarak beyaz kullan (template'de farklı renk varsa)
      return 'Beyaz kağıt';
  }
}

void _createQuickNote(BuildContext context) async {
  // WidgetsBinding ile context'in hala geçerli olduğundan emin ol
  if (!context.mounted) return;
  
  // ProviderScope'tan ref al
  final container = ProviderScope.containerOf(context);
  final controller = container.read(documentsControllerProvider.notifier);
  final folderId = container.read(currentFolderIdProvider);
  
  // Varsayılan ayarlarla hızlı not oluştur (sarı kağıt + ince çizgili)
  final documentId = await controller.createDocument(
    title: 'Hızlı Not - ${DateTime.now().toString().substring(0, 16)}',
    templateId: 'thin_lined', // Eski template ID (ince çizgili)
    folderId: folderId,
    paperColor: 'Sarı kağıt',
    isPortrait: true,
    documentType: drawing_core.DocumentType.quickNote,
  );
  
  // Doküman oluşturulduysa direkt editor'e git
  if (documentId != null && context.mounted) {
    context.push('/editor/$documentId');
  }
}

void _importPdf(BuildContext context) async {
  // 1. PDF dosyası seç
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  if (file.bytes == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF dosyası okunamadı')),
    );
    return;
  }

  // 2. Kısa loading (sadece PDF parse için - sayfaları DEĞİL)
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

  try {
    // 3. PDF Import Service kullan (lazy loading mode)
    final importService = PDFImportService();
    final importResult = await importService.importFromBytes(
      bytes: file.bytes!,
      config: PDFImportConfig.all(),
    );

    // Loading dialog kapat
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (!importResult.isSuccess) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.errorMessage ?? 'PDF import başarısız'),
        ),
      );
      return;
    }

    // 4. Doküman oluştur
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

    // 5. Editor'e HEMEN git (PREFETCH YOK!)
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
          
          // ❌ PREFETCH KODLARI SİLİNDİ - Editor kendi halledecek
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title açılıyor (${importResult.pages.length} sayfa)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      context.push('/editor/$documentId');
    }
  } catch (e) {
    // Hata durumunda dialog kapat
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
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
    
    debugPrint('🖼️ Image size: ${imageWidth}x$imageHeight');
    
    // Boyut kontrolü (max 4096x4096)
    if (imageWidth > 4096 || imageHeight > 4096) {
      if (context.mounted) {
        Navigator.pop(context); // Loading kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim çok büyük! Maksimum boyut: 4096x4096'),
          ),
        );
      }
      return;
    }
    
    // 4. Sayfa oluştur (Resimler için lazy loading YOK - direkt memory'de tut)
    final page = drawing_core.Page(
      id: 'page_${DateTime.now().millisecondsSinceEpoch}_0',
      index: 0,
      size: drawing_core.PageSize(width: imageWidth, height: imageHeight),
      background: drawing_core.PageBackground(
        type: drawing_core.BackgroundType.pdf, // PDF renderer değil ama aynı display mekanizması
        color: 0xFFFFFFFF,
        pdfData: file.bytes, // Resmi direkt cache'de tut (lazy loading YOK)
        pdfPageIndex: 1,
        // pdfFilePath: null, // CRITICAL: Lazy loading tetiklenmemeli!
      ),
      layers: [drawing_core.Layer.empty('Layer 1')],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 5. Doküman oluştur
    final container = ProviderScope.containerOf(context);
    final controller = container.read(documentsControllerProvider.notifier);
    final folderId = container.read(currentFolderIdProvider);
    
    // Dosya adından başlık oluştur (uzantıyı kaldır)
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
      
      context.push('/editor/$documentId');
    }
    
  } catch (e) {
    debugPrint('❌ Image import error: $e');
    if (context.mounted) {
      Navigator.pop(context); // Loading kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }
}

/// Shows the new document bottom sheet
/// @deprecated Use TemplatePicker.show() instead
@Deprecated('Use TemplatePicker.show() for new template selection')
void showNewDocumentSheet(BuildContext context, {drawing_core.DocumentType? documentType}) {
  // Redirect to new TemplatePicker
  _showTemplatePickerAndCreate(
    context,
    documentType == drawing_core.DocumentType.whiteboard 
        ? NewDocumentOption.whiteboard 
        : NewDocumentOption.notebook,
  );
}

// Keep old class for backward compatibility but redirect
class NewDocumentDialog extends ConsumerStatefulWidget {
  const NewDocumentDialog({super.key});

  @override
  ConsumerState<NewDocumentDialog> createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends ConsumerState<NewDocumentDialog> {
  @override
  void initState() {
    super.initState();
    // Close this dialog and open the new TemplatePicker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      TemplatePicker.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

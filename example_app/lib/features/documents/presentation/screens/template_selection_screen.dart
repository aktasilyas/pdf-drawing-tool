import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends ConsumerState<TemplateSelectionScreen> {
  String title = '';
  bool _hasCover = true;
  PaperSize _selectedPaperSize = PaperSize.a4;
  int _selectedPaperColor = 0xFFFFFFFF; // Beyaz default
  TemplateCategory? _selectedCategory = TemplateCategory.basic;
  Template? _selectedTemplate;
  bool _isSelectingCover = false; // false = Kağıt seçili, true = Kapak seçili
  Cover _selectedCover = CoverRegistry.defaultCover;

  @override
  void initState() {
    super.initState();
    // Default olarak ilk şablonu seç
    _selectedTemplate = TemplateRegistry.getByCategory(TemplateCategory.basic).firstOrNull;
  }

  Future<void> _createDocument() async {
    if (_selectedTemplate == null) return;

    final controller = ref.read(documentsControllerProvider.notifier);
    
    // Renk int'ten String'e çevir
    final paperColorName = _mapColorToName(_selectedPaperColor);
    
    // Doküman oluştur
    final docTitle = title.trim().isEmpty ? 'İsimsiz Not' : title.trim();
    
    final documentId = await controller.createDocument(
      title: docTitle,
      templateId: _selectedTemplate!.id,
      paperColor: paperColorName,
      isPortrait: true,
      documentType: DocumentType.notebook,
    );

    if (mounted && documentId != null) {
      // Çizim ekranına yönlendir
      context.go(RouteNames.editorPath(documentId));
    }
  }

  String _mapColorToName(int color) {
    switch (color) {
      case 0xFFFFFFFF:
        return 'Beyaz kağıt';
      case 0xFF1A1A1A:
        return 'Siyah kağıt';
      case 0xFFFFF8E7:
        return 'Krem kağıt';
      case 0xFFF5F5F5:
        return 'Gri kağıt';
      case 0xFFE8F5E9:
        return 'Yeşil kağıt';
      case 0xFFE3F2FD:
        return 'Mavi kağıt';
      default:
        return 'Beyaz kağıt';
    }
  }

  String _getFormatName(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4:
        return 'A4';
      case PaperSizePreset.a5:
        return 'A5';
      case PaperSizePreset.a6:
        return 'A6';
      case PaperSizePreset.letter:
        return 'Letter';
      case PaperSizePreset.legal:
        return 'Legal';
      case PaperSizePreset.square:
        return 'Kare';
      case PaperSizePreset.widescreen:
        return 'Geniş';
      case PaperSizePreset.custom:
        return 'Özel';
    }
  }

  Future<void> _showFormatPicker(BuildContext context) async {
    print('_showFormatPicker çağrıldı');
    final colorScheme = Theme.of(context).colorScheme;
    
    print('Mevcut: ${_selectedPaperSize.isLandscape ? "Yatay" : "Dikey"}, ${_getFormatName(_selectedPaperSize.preset)}');
    
    final result = await showModalBottomSheet<PaperSize>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format Seç',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Yön seçimi
              Row(
                children: [
                  Text(
                    'Yön:',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _OrientationButton(
                    label: 'Dikey',
                    icon: Icons.crop_portrait,
                    isSelected: !_selectedPaperSize.isLandscape,
                    onTap: () {
                      print('Dikey butonuna tıklandı');
                      Navigator.pop(context, _selectedPaperSize.portrait);
                    },
                  ),
                  const SizedBox(width: 8),
                  _OrientationButton(
                    label: 'Yatay',
                    icon: Icons.crop_landscape,
                    isSelected: _selectedPaperSize.isLandscape,
                    onTap: () {
                      print('Yatay butonuna tıklandı');
                      Navigator.pop(context, _selectedPaperSize.landscape);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Boyut seçimi
              Text(
                'Boyut:',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PaperSizePreset.a4,
                  PaperSizePreset.a5,
                  PaperSizePreset.a6,
                  PaperSizePreset.letter,
                  PaperSizePreset.square,
                ].map((preset) {
                  final isSelected = _selectedPaperSize.preset == preset;
                  return GestureDetector(
                    onTap: () {
                      print('Boyut seçildi: ${_getFormatName(preset)}');
                      final newSize = PaperSize.fromPreset(preset);
                      final result = _selectedPaperSize.isLandscape 
                          ? newSize.landscape 
                          : newSize;
                      print('Döndürülecek: ${result.isLandscape ? "Yatay" : "Dikey"}, ${_getFormatName(result.preset)}');
                      Navigator.pop(context, result);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? colorScheme.primaryContainer 
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? colorScheme.primary 
                              : colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _getFormatName(preset),
                        style: TextStyle(
                          color: isSelected 
                              ? colorScheme.onPrimaryContainer 
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    
    print('Bottom sheet kapandı. Result: $result');
    
    if (result != null && mounted) {
      print('Format değişti: ${result.isLandscape ? "Yatay" : "Dikey"}, ${_getFormatName(result.preset)}');
      setState(() {
        _selectedPaperSize = result;
      });
      print('setState çağrıldı');
    } else {
      print('Result null veya widget unmounted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'Yeni not oluştur',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _selectedTemplate != null ? _createDocument : null,
              child: const Text('Oluştur'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst önizleme alanı
          _buildPreviewSection(context),
          
          const Divider(height: 1),
          
          // Şablon/Kapak başlığı + Renk seçici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _isSelectingCover ? 'Kapak' : 'Şablon',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Renk seçici sadece kağıt sekmesinde
                if (!_isSelectingCover)
                  _ColorPalette(
                    selectedColor: _selectedPaperColor,
                    onColorSelected: (color) => setState(() => _selectedPaperColor = color),
                  ),
              ],
            ),
          ),
          
          // Kategori sekmeleri
          _buildCategoryTabs(context),

          const SizedBox(height: 4),

          // Template Grid
          Expanded(
            child: _isSelectingCover
                ? _buildCoverGrid(context)
                : _buildTemplateGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    // Format'a göre dinamik boyutlar - daha küçük
    final double baseWidth = isTablet ? 85 : 60;
    final double baseHeight = isTablet ? 120 : 85;
    
    // Yatay format için boyutları ters çevir
    final double previewWidth = _selectedPaperSize.isLandscape ? baseHeight : baseWidth;
    final double previewHeight = _selectedPaperSize.isLandscape ? baseWidth : baseHeight;
    
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 12 : 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kapak önizleme
            GestureDetector(
              onTap: () => setState(() => _isSelectingCover = true),
              child: _PreviewCard(
                key: ValueKey('cover_${_selectedPaperSize.isLandscape}'),
                label: 'Kapak',
                isSelected: _isSelectingCover,
                width: previewWidth,
                height: previewHeight,
                child: CoverPreviewWidget(
                  cover: _selectedCover,
                  title: title.isEmpty ? 'Not Başlığı' : title,
                  showBorder: false,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Kağıt önizleme
            GestureDetector(
              onTap: () => setState(() => _isSelectingCover = false),
              child: _PreviewCard(
                key: ValueKey('paper_${_selectedPaperSize.isLandscape}'),
                label: 'Kağıt',
                isSelected: !_isSelectingCover,
                width: previewWidth,
                height: previewHeight,
                child: _selectedTemplate != null
                    ? TemplatePreviewWidget(
                        template: _selectedTemplate!,
                        backgroundColorOverride: Color(_selectedPaperColor),
                        showBorder: false,
                      )
                    : Container(
                        color: Color(_selectedPaperColor),
                      ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Ayarlar paneli - daha kompakt
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık input - daha küçük
                    TextField(
                      onChanged: (value) => setState(() => title = value),
                      decoration: InputDecoration(
                        hintText: 'Başlık',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Kapak toggle - çok daha küçük
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kapak',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: _hasCover,
                            onChanged: (value) => setState(() => _hasCover = value),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    
                    // Format seçici - kompakt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Format',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFormatPicker(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            key: ValueKey('format_${_selectedPaperSize.isLandscape}_${_selectedPaperSize.preset}'),
                            children: [
                              Builder(
                                builder: (context) {
                                  final formatText = '${_selectedPaperSize.isLandscape ? "Yatay" : "Dikey"}, ${_getFormatName(_selectedPaperSize.preset)}';
                                  print('BUILD: Format text = $formatText');
                                  return Text(
                                    formatText,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Kapak seçiliyse kategori sekmeleri gösterme
    if (_isSelectingCover) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: TemplateCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primaryContainer 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  category.displayName,
                  style: TextStyle(
                    color: isSelected 
                        ? colorScheme.onPrimaryContainer 
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    final templates = _selectedCategory != null
        ? TemplateRegistry.getByCategory(_selectedCategory!)
        : TemplateRegistry.all;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 8 : 4;
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            final isSelected = _selectedTemplate?.id == template.id;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedTemplate = template),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          children: [
                            TemplatePreviewWidget(
                              template: template,
                              backgroundColorOverride: Color(_selectedPaperColor),
                              showBorder: false,
                            ),
                            if (isSelected)
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.name,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoverGrid(BuildContext context) {
    final covers = CoverRegistry.all;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 8 : 5;
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: covers.length,
          itemBuilder: (context, index) {
            final cover = covers[index];
            final isSelected = _selectedCover.id == cover.id;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedCover = cover),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CoverPreviewWidget(
                              cover: cover, // Orijinal rengini kullan
                              title: title.isEmpty ? 'Başlık' : title,
                              showBorder: false,
                            ),
                            // Premium kilit ikonu
                            if (cover.isPremium)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            // Seçim işareti
                            if (isSelected)
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cover.name,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double width;
  final double height;
  final Widget child;

  const _PreviewCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: child,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsRow({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
        child,
      ],
    );
  }
}

class _ColorPalette extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const _ColorPalette({
    required this.selectedColor,
    required this.onColorSelected,
  });

  // Kağıt renkleri - makul ve uyumlu
  static const _paperColors = [
    0xFFFFFFFF, // Beyaz
    0xFF1A1A1A, // Siyah (dark mode için)
    0xFFFFF8E7, // Krem
    0xFFF5F5F5, // Açık gri
    0xFFE8F5E9, // Açık yeşil
    0xFFE3F2FD, // Açık mavi
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _paperColors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: color == 0xFFFFFFFF || color == 0xFFF5F5F5
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: color == 0xFF1A1A1A 
                        ? Colors.white 
                        : colorScheme.primary,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrientationButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer 
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

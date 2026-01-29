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
  String _format = 'Dikey, A4';
  int _selectedPaperColor = 0xFFFFFFFF; // Beyaz default
  TemplateCategory? _selectedCategory = TemplateCategory.basic;
  Template? _selectedTemplate;
  bool _isSelectingCover = false; // false = Kağıt seçili, true = Kapak seçili

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
          
          // Şablon başlığı + Renk seçici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Şablon',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Renk',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                _ColorPalette(
                  selectedColor: _selectedPaperColor,
                  onColorSelected: (color) => setState(() => _selectedPaperColor = color),
                ),
              ],
            ),
          ),
          
          // Kategori sekmeleri
          _buildCategoryTabs(context),

          const SizedBox(height: 8),

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
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kapak önizleme
              GestureDetector(
                onTap: () => setState(() => _isSelectingCover = true),
                child: _PreviewCard(
                  label: 'Kapak',
                  isSelected: _isSelectingCover,
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 160 : 110,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    // TODO: Kapak tasarımı
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Kağıt önizleme
              GestureDetector(
                onTap: () => setState(() => _isSelectingCover = false),
                child: _PreviewCard(
                  label: 'Kağıt',
                  isSelected: !_isSelectingCover,
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 160 : 110,
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
              
              const SizedBox(width: 16),
              
              // Ayarlar paneli
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık input
                    TextField(
                      onChanged: (value) => setState(() => title = value),
                      decoration: InputDecoration(
                        hintText: 'Not için bir başlık girin',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Kapak toggle
                    _SettingsRow(
                      label: 'Kapak',
                      child: Switch(
                        value: _hasCover,
                        onChanged: (value) => setState(() => _hasCover = value),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Format seçici
                    _SettingsRow(
                      label: 'Format',
                      child: Text(
                        _format,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Kapak seçiliyse farklı kategoriler göster (şimdilik boş)
    if (_isSelectingCover) {
      return const SizedBox(height: 40);
    }
    
    return SizedBox(
      height: 40,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primaryContainer 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
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
                    fontSize: 13,
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
        final crossAxisCount = isTablet ? 8 : 4; // Artırıldı: 6→8, 3→4
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Text(
        'Kapak seçenekleri yakında eklenecek',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
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
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 12,
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
          style: TextStyle(color: colorScheme.onSurface),
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
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1,
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
                    size: 16,
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

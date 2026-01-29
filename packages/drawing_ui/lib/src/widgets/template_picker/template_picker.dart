import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/category_tabs.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_grid.dart';
import 'package:drawing_ui/src/widgets/template_picker/paper_size_picker.dart';
import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

/// Ana template seçici - responsive (phone: full sheet, tablet: dialog)
class TemplatePicker extends StatefulWidget {
  final Template? initialTemplate;
  final PaperSize initialPaperSize;
  final bool Function(Template)? isLocked;
  final VoidCallback? onPremiumTap;

  const TemplatePicker({
    super.key,
    this.initialTemplate,
    this.initialPaperSize = const PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    this.isLocked,
    this.onPremiumTap,
  });

  /// Bottom sheet olarak göster (phone)
  static Future<TemplatePickerResult?> showAsBottomSheet(
    BuildContext context, {
    Template? initialTemplate,
    PaperSize initialPaperSize = const PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    bool Function(Template)? isLocked,
    VoidCallback? onPremiumTap,
  }) {
    return showModalBottomSheet<TemplatePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => TemplatePicker(
          initialTemplate: initialTemplate,
          initialPaperSize: initialPaperSize,
          isLocked: isLocked,
          onPremiumTap: onPremiumTap,
        ),
      ),
    );
  }

  /// Dialog olarak göster (tablet)
  static Future<TemplatePickerResult?> showAsDialog(
    BuildContext context, {
    Template? initialTemplate,
    PaperSize initialPaperSize = const PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    bool Function(Template)? isLocked,
    VoidCallback? onPremiumTap,
  }) {
    return showDialog<TemplatePickerResult>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 900, // 700 → 900 (daha geniş)
          height: 700, // 600 → 700 (daha yüksek)
          child: TemplatePicker(
            initialTemplate: initialTemplate,
            initialPaperSize: initialPaperSize,
            isLocked: isLocked,
            onPremiumTap: onPremiumTap,
          ),
        ),
      ),
    );
  }

  /// Otomatik seç: phone → bottom sheet, tablet → dialog
  static Future<TemplatePickerResult?> show(
    BuildContext context, {
    Template? initialTemplate,
    PaperSize initialPaperSize = const PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    bool Function(Template)? isLocked,
    VoidCallback? onPremiumTap,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    if (isTablet) {
      return showAsDialog(
        context,
        initialTemplate: initialTemplate,
        initialPaperSize: initialPaperSize,
        isLocked: isLocked,
        onPremiumTap: onPremiumTap,
      );
    } else {
      return showAsBottomSheet(
        context,
        initialTemplate: initialTemplate,
        initialPaperSize: initialPaperSize,
        isLocked: isLocked,
        onPremiumTap: onPremiumTap,
      );
    }
  }

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  TemplateCategory? _selectedCategory;
  late Template _selectedTemplate;
  late PaperSize _selectedPaperSize;
  Color? _lineColor;
  Color? _backgroundColor;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate ?? TemplateRegistry.blank;
    _selectedPaperSize = widget.initialPaperSize;
  }

  List<Template> get _filteredTemplates {
    if (_selectedCategory == null) {
      return TemplateRegistry.all;
    }
    return TemplateRegistry.getByCategory(_selectedCategory!);
  }

  void _handleTemplateSelected(Template template) {
    final isLocked = widget.isLocked?.call(template) ?? template.isPremium;
    
    if (isLocked) {
      widget.onPremiumTap?.call();
      return;
    }
    
    setState(() {
      _selectedTemplate = template;
      // Reset colors when template changes
      _lineColor = null;
      _backgroundColor = null;
    });
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TemplatePickerResult(
      template: _selectedTemplate,
      paperSize: _selectedPaperSize,
      lineColor: _lineColor,
      backgroundColor: _backgroundColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Text(
                'Şablon Seç',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Category tabs
        CategoryTabs(
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),

        const SizedBox(height: 8),

        // Content: Grid + Preview (responsive)
        Expanded(
          child: isTablet
              ? Row(
                  children: [
                    // Sol: Grid
                    Expanded(
                      flex: 3,
                      child: TemplateGrid(
                        templates: _filteredTemplates,
                        selectedTemplate: _selectedTemplate,
                        onTemplateSelected: _handleTemplateSelected,
                        isLocked: widget.isLocked,
                      ),
                    ),
                    // Sağ: Preview
                    Expanded(
                      flex: 2,
                      child: _buildPreviewPanel(theme, colorScheme),
                    ),
                  ],
                )
              : TemplateGrid(
                  templates: _filteredTemplates,
                  selectedTemplate: _selectedTemplate,
                  onTemplateSelected: _handleTemplateSelected,
                  isLocked: widget.isLocked,
                ),
        ),

        // Bottom bar
        _buildBottomBar(colorScheme),
      ],
    );
  }

  Widget _buildPreviewPanel(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Önizleme
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _selectedPaperSize.isLandscape ? 297 / 210 : 210 / 297,
                child: TemplatePreviewWidget(
                  template: _selectedTemplate,
                  lineColorOverride: _lineColor,
                  backgroundColorOverride: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Template adı
          Text(
            _selectedTemplate.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Açıklama
          Text(
            '${_selectedPaperSize.preset.name.toUpperCase()} • ${_selectedPaperSize.isLandscape ? "Yatay" : "Dikey"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Renk seçiciler
            _ColorButton(
              color: _backgroundColor ?? Color(_selectedTemplate.defaultBackgroundColor),
              label: 'Kağıt',
              onColorSelected: (color) {
                setState(() {
                  _backgroundColor = color;
                });
              },
            ),
            const SizedBox(width: 8),
            _ColorButton(
              color: _lineColor ?? Color(_selectedTemplate.defaultLineColor),
              label: 'Çizgi',
              onColorSelected: (color) {
                setState(() {
                  _lineColor = color;
                });
              },
            ),
            const SizedBox(width: 16),
            
            // Kağıt boyutu
            Flexible(
              child: PaperSizePicker(
                selectedSize: _selectedPaperSize,
                onSizeSelected: (size) {
                  setState(() {
                    _selectedPaperSize = size;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Oluştur butonu
            FilledButton.icon(
              onPressed: _handleConfirm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Oluştur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Template picker sonucu
class TemplatePickerResult {
  final Template template;
  final PaperSize paperSize;
  final Color? lineColor;
  final Color? backgroundColor;

  const TemplatePickerResult({
    required this.template,
    required this.paperSize,
    this.lineColor,
    this.backgroundColor,
  });
}

/// Renk seçici butonu
class _ColorButton extends StatelessWidget {
  final Color color;
  final String label;
  final ValueChanged<Color> onColorSelected;

  const _ColorButton({
    required this.color,
    required this.label,
    required this.onColorSelected,
  });

  // Preset renkler
  static const _presetColors = [
    Color(0xFFFFFFFF), // Beyaz
    Color(0xFFFFFDE7), // Sarı
    Color(0xFFF5F5F5), // Gri
    Color(0xFFE3F2FD), // Mavi açık
    Color(0xFFFCE4EC), // Pembe açık
    Color(0xFFF1F8E9), // Yeşil açık
    Color(0xFF000000), // Siyah
    Color(0xFF424242), // Koyu gri
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Rengi Seç'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((presetColor) {
            final isSelected = presetColor == color;
            return GestureDetector(
              onTap: () {
                onColorSelected(presetColor);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: presetColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: presetColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}

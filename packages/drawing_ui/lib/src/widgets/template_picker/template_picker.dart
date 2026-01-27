import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/category_tabs.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_grid.dart';
import 'package:drawing_ui/src/widgets/template_picker/paper_size_picker.dart';

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
          width: 700,
          height: 600,
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

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate ?? TemplateRegistry.getById('blank_white')!;
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
    });
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TemplatePickerResult(
      template: _selectedTemplate,
      paperSize: _selectedPaperSize,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

        // Template grid
        Expanded(
          child: TemplateGrid(
            templates: _filteredTemplates,
            selectedTemplate: _selectedTemplate,
            onTemplateSelected: _handleTemplateSelected,
            isLocked: widget.isLocked,
          ),
        ),

        // Bottom bar
        Container(
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
                FilledButton(
                  onPressed: _handleConfirm,
                  child: const Text('Oluştur'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Template picker sonucu
class TemplatePickerResult {
  final Template template;
  final PaperSize paperSize;

  const TemplatePickerResult({
    required this.template,
    required this.paperSize,
  });
}

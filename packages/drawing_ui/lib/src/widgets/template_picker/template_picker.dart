import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/template_picker/category_tabs.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_grid.dart';
import 'package:drawing_ui/src/widgets/template_picker/paper_size_picker.dart';
import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

/// Paper color presets for the dropdown.
const _paperColorPresets = <String, Color>{
  'Beyaz': Color(0xFFFFFFFF),
  'Krem': Color(0xFFFFFDE7),
  'Siyah': Color(0xFF303030),
};

/// Ana template secici - responsive (phone: full sheet, tablet: dialog)
class TemplatePicker extends StatefulWidget {
  final Template? initialTemplate;
  final PaperSize initialPaperSize;
  final bool Function(Template)? isLocked;
  final VoidCallback? onPremiumTap;

  const TemplatePicker({
    super.key,
    this.initialTemplate,
    this.initialPaperSize = const PaperSize(
        widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    this.isLocked,
    this.onPremiumTap,
  });

  /// Responsive show: phone -> bottom sheet, tablet -> dialog.
  static Future<TemplatePickerResult?> show(
    BuildContext context, {
    Template? initialTemplate,
    PaperSize initialPaperSize = const PaperSize(
        widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    bool Function(Template)? isLocked,
    VoidCallback? onPremiumTap,
  }) {
    final picker = TemplatePicker(
      initialTemplate: initialTemplate,
      initialPaperSize: initialPaperSize,
      isLocked: isLocked,
      onPremiumTap: onPremiumTap,
    );
    if (MediaQuery.of(context).size.width >= 600) {
      return showDialog<TemplatePickerResult>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SizedBox(width: 720, height: 560, child: picker),
        ),
      );
    }
    return showModalBottomSheet<TemplatePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => picker,
      ),
    );
  }

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  TemplateCategory? _selectedCategory;
  late Template _selectedTemplate;
  late PaperSize _selectedPaperSize;
  Color _paperColor = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate ?? TemplateRegistry.blank;
    _selectedPaperSize = widget.initialPaperSize;
  }

  List<Template> get _filteredTemplates {
    final source = _selectedCategory == null
        ? TemplateRegistry.all
        : TemplateRegistry.getByCategory(_selectedCategory!);
    // Keep only first template per unique pattern
    final seen = <TemplatePattern>{};
    return source.where((t) {
      if (seen.contains(t.pattern)) return false;
      seen.add(t.pattern);
      return true;
    }).toList();
  }

  void _handleTemplateSelected(Template template) {
    setState(() => _selectedTemplate = template);
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TemplatePickerResult(
      template: _selectedTemplate,
      paperSize: _selectedPaperSize,
      backgroundColor: _paperColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(children: [
      _buildHeader(theme, cs),
      CategoryTabs(
        selectedCategory: _selectedCategory,
        onCategorySelected: (c) => setState(() => _selectedCategory = c),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: isTablet
            ? Row(children: [
                Expanded(flex: 3, child: _buildGrid()),
                Expanded(flex: 2, child: _buildPreview(theme, cs)),
              ])
            : _buildGrid(),
      ),
      _buildBottomBar(cs),
    ]);
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(children: [
        Text('Şablon Seç',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: PhosphorIcon(StarNoteIcons.close,
              size: 20, color: cs.onSurfaceVariant),
        ),
      ]),
    );
  }

  Widget _buildGrid() => TemplateGrid(
        templates: _filteredTemplates,
        selectedTemplate: _selectedTemplate,
        onTemplateSelected: _handleTemplateSelected,
        isLocked: (_) => false,
      );

  Widget _buildPreview(ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 210 / 297,
              child: TemplatePreviewWidget(
                template: _selectedTemplate,
                backgroundColorOverride: _paperColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_selectedTemplate.name,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(_selectedPaperSize.preset.name.toUpperCase(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    const h = 36.0;
    final border = Border.all(color: cs.outline.withValues(alpha: 0.2));
    final radius = BorderRadius.circular(8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _buildPaperColorDropdown(cs, h, border, radius),
          const SizedBox(width: 8),
          Flexible(
            child: PaperSizePicker(
              selectedSize: _selectedPaperSize,
              onSizeSelected: (s) => setState(() => _selectedPaperSize = s),
              showLandscapeToggle: false,
              dense: true,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: h,
            child: FilledButton(
              onPressed: _handleConfirm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
              child: const Text('Uygula',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPaperColorDropdown(
      ColorScheme cs, double h, Border border, BorderRadius radius) {
    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: cs.surfaceContainerHigh, borderRadius: radius, border: border),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Color>(
          value: _paperColor,
          isDense: true,
          icon: PhosphorIcon(StarNoteIcons.caretDown,
              size: 14, color: cs.onSurfaceVariant),
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          dropdownColor: cs.surfaceContainerHighest,
          items: _paperColorPresets.entries.map((e) {
            return DropdownMenuItem(
              value: e.value,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: e.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: cs.outline.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(e.key),
              ]),
            );
          }).toList(),
          onChanged: (c) {
            if (c != null) setState(() => _paperColor = c);
          },
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

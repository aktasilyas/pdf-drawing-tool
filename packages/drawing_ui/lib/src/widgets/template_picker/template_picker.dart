import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/category_tabs.dart';
import 'package:drawing_ui/src/widgets/template_picker/cover_grid.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_grid.dart';
import 'package:drawing_ui/src/widgets/template_picker/paper_size_picker.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker_helpers.dart';

export 'template_picker_helpers.dart' show TemplatePickerResult;

/// Ana template secici - responsive (phone: full sheet, tablet: dialog)
class TemplatePicker extends StatefulWidget {
  final Template? initialTemplate;
  final PaperSize initialPaperSize;
  final Color initialPaperColor;
  final Cover? initialCover;
  final bool Function(Template)? isLocked;
  final VoidCallback? onPremiumTap;

  const TemplatePicker({
    super.key,
    this.initialTemplate,
    this.initialPaperSize = const PaperSize(
        widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    this.initialPaperColor = const Color(0xFFFFFFFF),
    this.initialCover,
    this.isLocked,
    this.onPremiumTap,
  });

  /// Responsive show: phone -> bottom sheet, tablet -> dialog.
  static Future<TemplatePickerResult?> show(
    BuildContext context, {
    Template? initialTemplate,
    PaperSize initialPaperSize = const PaperSize(
        widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4),
    Color initialPaperColor = const Color(0xFFFFFFFF),
    Cover? initialCover,
    bool Function(Template)? isLocked,
    VoidCallback? onPremiumTap,
  }) {
    final picker = TemplatePicker(
      initialTemplate: initialTemplate,
      initialPaperSize: initialPaperSize,
      initialPaperColor: initialPaperColor,
      initialCover: initialCover,
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
          child: SizedBox(width: 780, height: 620, child: picker),
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
        initialChildSize: 0.90, minChildSize: 0.5, maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => picker,
      ),
    );
  }

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TemplateCategory? _selectedCategory;
  late Template _selectedTemplate;
  late PaperSize _selectedPaperSize;
  late Color _paperColor;
  Cover? _selectedCover;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate ?? TemplateRegistry.blank;
    _selectedPaperSize = widget.initialPaperSize;
    _paperColor = widget.initialPaperColor;
    _selectedCover = widget.initialCover;
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isCoverTab => _tabController.index == 0;

  List<Template> get _filteredTemplates {
    final source = _selectedCategory == null
        ? TemplateRegistry.all
        : TemplateRegistry.getByCategory(_selectedCategory!);
    final seen = <TemplatePattern>{};
    return source.where((t) {
      if (seen.contains(t.pattern)) return false;
      seen.add(t.pattern);
      return true;
    }).toList();
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TemplatePickerResult(
      template: _selectedTemplate,
      paperSize: _selectedPaperSize,
      backgroundColor: _paperColor,
      cover: _selectedCover,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(children: [
      _buildTabBar(theme, cs),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            CoverGrid(
              covers: CoverRegistry.all,
              selectedCover: _selectedCover,
              onCoverSelected: (c) => setState(() => _selectedCover = c),
            ),
            _buildPaperTab(),
          ],
        ),
      ),
      _buildBottomBar(cs),
    ]);
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        indicatorColor: cs.primary,
        indicatorWeight: 2.5,
        tabs: const [Tab(text: 'Kapak'), Tab(text: 'Kâğıt')],
      ),
    );
  }

  Widget _buildPaperTab() {
    return Column(children: [
      const SizedBox(height: 4),
      CategoryTabs(
        selectedCategory: _selectedCategory,
        onCategorySelected: (c) => setState(() => _selectedCategory = c),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: TemplateGrid(
          templates: _filteredTemplates,
          selectedTemplate: _selectedTemplate,
          onTemplateSelected: (t) => setState(() => _selectedTemplate = t),
          isLocked: (_) => false,
        ),
      ),
    ]);
  }

  Widget _buildBottomBar(ColorScheme cs) {
    final radius = BorderRadius.circular(10);
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Options strip (paper color, size, orientation)
          if (!_isCoverTab)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                PaperColorDropdown(
                  selectedColor: _paperColor,
                  onColorChanged: (c) => setState(() => _paperColor = c),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: PaperSizePicker(
                    selectedSize: _selectedPaperSize,
                    onSizeSelected: (s) =>
                        setState(() => _selectedPaperSize = s),
                    showLandscapeToggle: true,
                    dense: true,
                  ),
                ),
              ]),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                  child: Text('İptal',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _handleConfirm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                  child: const Text('Uygula',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

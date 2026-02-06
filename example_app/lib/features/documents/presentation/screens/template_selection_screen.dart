/// StarNote Template Selection Screen - Design system template picker
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_card.dart';
import 'package:example_app/features/documents/presentation/widgets/paper_color_palette.dart';
import 'package:example_app/features/documents/presentation/widgets/template_category_tabs.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/format_picker_sheet.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  String _title = '';
  bool _hasCover = true;
  PaperSize _paperSize = PaperSize.a4;
  int _paperColor = 0xFFFFFFFF;
  TemplateCategory _category = TemplateCategory.basic;
  Template? _template;
  bool _isSelectingCover = false;
  Cover _cover = CoverRegistry.defaultCover;

  @override
  void initState() {
    super.initState();
    _template =
        TemplateRegistry.getByCategory(TemplateCategory.basic).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: AppButton(
          label: 'İptal',
          variant: AppButtonVariant.text,
          onPressed: () => context.pop(),
        ),
        leadingWidth: 80,
        title: Text('Yeni not oluştur',
            style: AppTypography.titleMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            )),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton(
              label: 'Oluştur',
              size: AppButtonSize.small,
              onPressed: _template != null ? _createDocument : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPreviewSection(isTablet),
          const AppDivider(),
          _buildSectionHeader(),
          if (!_isSelectingCover)
            TemplateCategoryTabs(
              selectedCategory: _category,
              onCategorySelected: (c) => setState(() => _category = c),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _isSelectingCover && _hasCover
                ? CoverGridView(
                    selectedCover: _cover,
                    title: _title,
                    onCoverSelected: (c) => setState(() => _cover = c),
                  )
                : TemplateGridView(
                    category: _category,
                    selectedTemplate: _template,
                    paperColor: _paperColor,
                    onTemplateSelected: (t) => setState(() => _template = t),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isTablet) {
    final baseW = isTablet ? 85.0 : 60.0;
    final baseH = isTablet ? 120.0 : 85.0;
    final previewW = _paperSize.isLandscape ? baseH : baseW;
    final previewH = _paperSize.isLandscape ? baseW : baseH;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: isTablet ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasCover) ...[
            TemplatePreviewCard(
              label: 'Kapak',
              isSelected: _isSelectingCover,
              width: previewW,
              height: previewH,
              onTap: () => setState(() => _isSelectingCover = true),
              child: CoverPreviewWidget(
                cover: _cover,
                title: _title.isEmpty ? 'Not Başlığı' : _title,
                showBorder: false,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          TemplatePreviewCard(
            label: 'Kağıt',
            isSelected: !_isSelectingCover,
            width: previewW,
            height: previewH,
            onTap: () => setState(() => _isSelectingCover = false),
            child: _template != null
                ? TemplatePreviewWidget(
                    template: _template!,
                    backgroundColorOverride: Color(_paperColor),
                    showBorder: false,
                  )
                : Container(color: Color(_paperColor)),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _buildSettingsPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title input
        AppTextField(
          hint: 'Başlık',
          onChanged: (v) => setState(() => _title = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Cover toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kapak', style: AppTypography.caption),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _hasCover,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _hasCover = v;
                  if (!v) _isSelectingCover = false;
                }),
              ),
            ),
          ],
        ),
        // Format picker
        Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textSecondary = isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Format', style: AppTypography.caption),
                GestureDetector(
                  onTap: _showFormatPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_paperSize.isLandscape ? "Yatay" : "Dikey"}, ${_getPresetName(_paperSize.preset)}',
                        style: AppTypography.caption
                            .copyWith(color: textSecondary),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(Icons.keyboard_arrow_down,
                          size: AppIconSize.sm, color: textSecondary),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            _isSelectingCover ? 'Kapak' : 'Şablon',
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!_isSelectingCover)
            PaperColorPalette(
              selectedColor: _paperColor,
              onColorSelected: (c) => setState(() => _paperColor = c),
            ),
        ],
      ),
    );
  }

  Future<void> _showFormatPicker() async {
    final result = await FormatPickerSheet.show(context, _paperSize);
    if (result != null && mounted) {
      setState(() => _paperSize = result);
    }
  }

  String _getPresetName(PaperSizePreset preset) {
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

  Future<void> _createDocument() async {
    if (_template == null) return;

    final controller = ref.read(documentsControllerProvider.notifier);
    final docTitle = _title.trim().isEmpty ? 'İsimsiz Not' : _title.trim();

    final documentId = await controller.createDocument(
      title: docTitle,
      templateId: _template!.id,
      paperColor: _mapColorToName(_paperColor),
      isPortrait: !_paperSize.isLandscape,
      documentType: DocumentType.notebook,
      coverId: _hasCover ? _cover.id : null,
      hasCover: _hasCover,
      paperWidthMm: _paperSize.widthMm,
      paperHeightMm: _paperSize.heightMm,
    );

    if (mounted && documentId != null) {
      context.go(RouteNames.editorPath(documentId));
    }
  }
}

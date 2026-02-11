/// StarNote Template Preview Section
///
/// Preview cards and settings panel for template selection screen.
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_card.dart';
import 'package:example_app/features/documents/presentation/widgets/format_picker_sheet.dart';

/// Preview section with cover/paper cards and settings panel.
class TemplatePreviewSection extends StatelessWidget {
  final bool hasCover;
  final bool isSelectingCover;
  final PaperSize paperSize;
  final int paperColor;
  final String title;
  final Cover cover;
  final Template? template;
  final ValueChanged<bool> onCoverToggle;
  final ValueChanged<bool> onSelectingCoverChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<PaperSize> onPaperSizeChanged;

  const TemplatePreviewSection({
    super.key,
    required this.hasCover,
    required this.isSelectingCover,
    required this.paperSize,
    required this.paperColor,
    required this.title,
    required this.cover,
    required this.template,
    required this.onCoverToggle,
    required this.onSelectingCoverChanged,
    required this.onTitleChanged,
    required this.onPaperSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    if (isTablet) return _buildTabletLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildTabletLayout(BuildContext context) {
    const baseW = 85.0;
    const baseH = 120.0;
    final previewW = paperSize.isLandscape ? baseH : baseW;
    final previewH = paperSize.isLandscape ? baseW : baseH;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildPreviewCards(previewW, previewH),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _buildSettingsPanel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    const baseW = 90.0;
    const baseH = 127.0;
    final previewW = paperSize.isLandscape ? baseH : baseW;
    final previewH = paperSize.isLandscape ? baseW : baseH;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPreviewCards(previewW, previewH),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSettingsPanel(context),
        ],
      ),
    );
  }

  List<Widget> _buildPreviewCards(double previewW, double previewH) {
    return [
      if (hasCover) ...[
        TemplatePreviewCard(
          label: 'Kapak',
          isSelected: isSelectingCover,
          width: previewW,
          height: previewH,
          onTap: () => onSelectingCoverChanged(true),
          child: CoverPreviewWidget(
            cover: cover,
            title: title.isEmpty ? 'Not Basligi' : title,
            showBorder: false,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      TemplatePreviewCard(
        label: 'Kagit',
        isSelected: !isSelectingCover,
        width: previewW,
        height: previewH,
        onTap: () => onSelectingCoverChanged(false),
        child: template != null
            ? TemplatePreviewWidget(
                template: template!,
                backgroundColorOverride: Color(paperColor),
                showBorder: false,
              )
            : Container(color: Color(paperColor)),
      ),
    ];
  }

  Widget _buildSettingsPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          hint: 'Baslik',
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kapak', style: AppTypography.caption),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: hasCover,
                activeTrackColor: AppColors.primary,
                onChanged: onCoverToggle,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Format', style: AppTypography.caption),
            GestureDetector(
              onTap: () => _showFormatPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${paperSize.isLandscape ? "Yatay" : "Dikey"}, '
                    '${_getPresetName(paperSize.preset)}',
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
        ),
      ],
    );
  }

  Future<void> _showFormatPicker(BuildContext context) async {
    final result = await FormatPickerSheet.show(context, paperSize);
    if (result != null) {
      onPaperSizeChanged(result);
    }
  }

  String _getPresetName(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4: return 'A4';
      case PaperSizePreset.a5: return 'A5';
      case PaperSizePreset.a6: return 'A6';
      case PaperSizePreset.letter: return 'Letter';
      case PaperSizePreset.legal: return 'Legal';
      case PaperSizePreset.square: return 'Kare';
      case PaperSizePreset.widescreen: return 'Genis';
      case PaperSizePreset.custom: return 'Ozel';
    }
  }
}

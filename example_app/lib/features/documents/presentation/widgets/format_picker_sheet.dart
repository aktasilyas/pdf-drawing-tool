/// StarNote Format Picker Sheet - Bottom sheet for paper format selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';

/// Paper format picker bottom sheet.
///
/// StatefulWidget that holds orientation + size in local state,
/// submitting both on "Tamam" button press.
class FormatPickerSheet extends StatefulWidget {
  final PaperSize currentSize;

  const FormatPickerSheet({super.key, required this.currentSize});

  static Future<PaperSize?> show(BuildContext context, PaperSize currentSize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<PaperSize>(
      context: context,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => FormatPickerSheet(currentSize: currentSize),
    );
  }

  @override
  State<FormatPickerSheet> createState() => _FormatPickerSheetState();
}

class _FormatPickerSheetState extends State<FormatPickerSheet> {
  late PaperSizePreset _selectedPreset;
  late bool _isLandscape;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.currentSize.preset;
    _isLandscape = widget.currentSize.isLandscape;
  }

  PaperSize get _currentSelection {
    final base = PaperSize.fromPreset(_selectedPreset);
    return _isLandscape ? base.landscape : base.portrait;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(isDark),
            const SizedBox(height: AppSpacing.md),
            _buildHeader(textSecondary),
            const SizedBox(height: AppSpacing.lg),
            _buildOrientationSection(textSecondary),
            const SizedBox(height: AppSpacing.lg),
            _buildSizeSection(textSecondary),
            const SizedBox(height: AppSpacing.lg),
            _buildConfirmButton(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.outlineDark.withValues(alpha: 0.3)
              : AppColors.outlineLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Format', style: AppTypography.titleMedium),
        Text(
          '${_currentSelection.widthMm.toInt()} x '
          '${_currentSelection.heightMm.toInt()} mm',
          style: AppTypography.caption.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildOrientationSection(Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yön',
          style: AppTypography.labelMedium.copyWith(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppChip(
              label: 'Dikey',
              icon: Icons.crop_portrait,
              isSelected: !_isLandscape,
              onTap: () => setState(() => _isLandscape = false),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Yatay',
              icon: Icons.crop_landscape,
              isSelected: _isLandscape,
              onTap: () => setState(() => _isLandscape = true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSection(Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boyut',
          style: AppTypography.labelMedium.copyWith(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            PaperSizePreset.a4,
            PaperSizePreset.a5,
            PaperSizePreset.a6,
            PaperSizePreset.letter,
            PaperSizePreset.legal,
            PaperSizePreset.square,
          ].map((preset) {
            return AppChip(
              label: _getPresetName(preset),
              isSelected: _selectedPreset == preset,
              onTap: () => setState(() => _selectedPreset = preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: 'Tamam',
        onPressed: () => Navigator.pop(context, _currentSelection),
      ),
    );
  }

  String _getPresetName(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4: return 'A4';
      case PaperSizePreset.a5: return 'A5';
      case PaperSizePreset.a6: return 'A6';
      case PaperSizePreset.letter: return 'Letter';
      case PaperSizePreset.legal: return 'Legal';
      case PaperSizePreset.square: return 'Kare';
      case PaperSizePreset.widescreen: return 'Geniş';
      case PaperSizePreset.custom: return 'Özel';
    }
  }
}

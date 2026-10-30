/// ElyaNotes Format Picker Sheet - Bottom sheet for paper format selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';

/// Paper format picker bottom sheet.
///
/// StatefulWidget that holds orientation + size in local state,
/// submitting both on the confirm button press.
class FormatPickerSheet extends StatefulWidget {
  final PaperSize currentSize;

  const FormatPickerSheet({super.key, required this.currentSize});

  static Future<PaperSize?> show(BuildContext context, PaperSize currentSize) {
    return showModalBottomSheet<PaperSize>(
      context: context,
      backgroundColor: context.palette.surface,
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
    final textSecondary = context.palette.textMuted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(),
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

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.palette.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(context.l10n.libraryFormat, style: AppTypography.titleMedium),
        Text(
          '${_currentSelection.widthMm.toInt()} x ' // l10n-ignore
          '${_currentSelection.heightMm.toInt()} mm', // l10n-ignore
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
          context.l10n.libraryOrientation,
          style: AppTypography.labelMedium.copyWith(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppChip(
              label: context.l10n.libraryPortrait,
              icon: Icons.crop_portrait,
              isSelected: !_isLandscape,
              onTap: () => setState(() => _isLandscape = false),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: context.l10n.libraryLandscape,
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
          context.l10n.librarySize,
          style: AppTypography.labelMedium.copyWith(color: textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          // Chips carry their own 48dp tap band around a 32dp pill.
          runSpacing: 0,
          children: [
            PaperSizePreset.a4,
            PaperSizePreset.a5,
            PaperSizePreset.a6,
            PaperSizePreset.letter,
            PaperSizePreset.legal,
            PaperSizePreset.square,
          ].map((preset) {
            return AppChip(
              label: preset.label(context.l10n),
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
        label: context.l10n.commonOk,
        onPressed: () => Navigator.pop(context, _currentSelection),
      ),
    );
  }
}

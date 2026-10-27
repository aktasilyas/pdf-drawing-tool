import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/widgets/inline_folder_color_row.dart';

/// Inline "new folder" form of the move dialog (name, colour, create).
class MoveToFolderCreateForm extends StatefulWidget {
  const MoveToFolderCreateForm({
    super.key,
    required this.onCreate,
    required this.onCancel,
  });

  /// Called with the raw name and the chosen colour; validation is the
  /// caller's job.
  final void Function(String name, int colorValue) onCreate;
  final VoidCallback onCancel;

  @override
  State<MoveToFolderCreateForm> createState() => _MoveToFolderCreateFormState();
}

class _MoveToFolderCreateFormState extends State<MoveToFolderCreateForm> {
  final _controller = TextEditingController();
  int _colorValue = AppColors.folderColors.first.toARGB32();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onCreate(_controller.text, _colorValue);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final outline = OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: palette.border));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: palette.surfaceElevated,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.create_new_folder,
                  size: AppIconSize.sm, color: palette.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Text('Yeni Klasör',
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold, color: palette.textPrimary)),
              const Spacer(),
              AppButton(
                  label: 'İptal',
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: widget.onCancel),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Icon(Icons.folder,
                  color: Color(_colorValue), size: AppIconSize.lg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: TextField(
                controller: _controller,
                autofocus: true,
                style: AppTypography.bodyMedium
                    .copyWith(color: palette.textPrimary),
                cursorColor: palette.accent,
                decoration: InputDecoration(
                  hintText: 'Klasör adı girin',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: palette.textMuted),
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: outline.copyWith(
                      borderSide: BorderSide(color: palette.accent, width: 2)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onSubmitted: (_) => _submit(),
              )),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text('Renk',
                style:
                    AppTypography.caption.copyWith(color: palette.textMuted)),
            const SizedBox(height: AppSpacing.xs),
            InlineFolderColorRow(
              selectedColorValue: _colorValue,
              onChanged: (v) => setState(() => _colorValue = v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Oluştur',
                size: AppButtonSize.small,
                isExpanded: true,
                onPressed: _submit),
          ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/document_thumbnail_painter.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_core/drawing_core.dart' as core;

/// List tile for a document row.
class DocumentListTile extends ConsumerWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
  });

  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final isSelected = selectedDocs.contains(document.id);

    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final hoverColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return Material(
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        hoverColor: hoverColor,
        splashColor: hoverColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (isSelectionMode)
                SelectionCheckbox(isSelected: isSelected)
              else
                CompactDocumentThumbnail(document: document),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      document.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      document.pageCount > 1
                          ? '${DocumentDateFormatter.format(document.updatedAt)} · ${document.pageCount} sayfa'
                          : DocumentDateFormatter.format(document.updatedAt),
                      style: AppTypography.caption
                          .copyWith(color: textTertiary),
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode && document.isFavorite)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(documentsControllerProvider.notifier)
                        .toggleFavorite(document.id),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              if (!isSelectionMode)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular selection checkbox.
class SelectionCheckbox extends StatelessWidget {
  const SelectionCheckbox({super.key, required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      width: 36,
      height: 44,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : outlineColor,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.onPrimary,
              )
            : null,
      ),
    );
  }
}

/// Compact thumbnail for list view (40x48).
class CompactDocumentThumbnail extends StatelessWidget {
  const CompactDocumentThumbnail({super.key, required this.document});
  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = DocumentPaperColors.fromName(document.paperColor);
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outlineColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.5),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (document.hasCover && document.coverId != null) {
      final cover = core.CoverRegistry.byId(document.coverId!);
      if (cover != null) {
        return CoverPreviewWidget(
          cover: cover,
          title: '',
          width: 40,
          height: 48,
        );
      }
    }
    if (document.documentType == core.DocumentType.pdf ||
        document.documentType == core.DocumentType.image) {
      return DocumentPreview(document: document);
    }
    return Stack(
      children: [
        CustomPaint(
          painter: DocumentThumbnailPainter(document.templateId),
          size: const Size(40, 48),
        ),
        if (document.documentType == core.DocumentType.notebook)
          const _CompactSpiralBinding(),
      ],
    );
  }
}

class _CompactSpiralBinding extends StatelessWidget {
  const _CompactSpiralBinding();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 4,
      bottom: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          5,
          (i) => Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

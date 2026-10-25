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
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final isSelected = selectedDocs.contains(document.id);

    final textPrimary = context.palette.textPrimary;
    final textTertiary = context.palette.textDisabled;
    final surfaceColor = context.palette.surface;
    final hoverColor = context.palette.surfaceElevated;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardResting(Theme.of(context).brightness),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          hoverColor: hoverColor,
          splashColor: hoverColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
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
                        style:
                            AppTypography.caption.copyWith(color: textTertiary),
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
    final outlineColor = context.palette.textDisabled;

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
    final paperColor = DocumentPaperColors.fromName(document.paperColor);
    final outlineColor = context.palette.border;

    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outlineColor, width: 0.5),
        boxShadow: AppShadows.cardResting(Theme.of(context).brightness),
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
      return SizedBox(
        width: 40,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: DocumentPreview(document: document),
        ),
      );
    }
    if (document.documentType == core.DocumentType.whiteboard) {
      return _CompactWhiteboardThumbnail();
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

class _CompactWhiteboardThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final frameColor = context.palette.border;
    final dotColor = context.palette.textPrimary.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(2),
      color: frameColor,
      child: Container(
        color: context.palette.surfaceElevated,
        child: CustomPaint(
          painter: WhiteboardGridPainter(dotColor: dotColor, spacing: 10),
          size: const Size(36, 44),
        ),
      ),
    );
  }
}

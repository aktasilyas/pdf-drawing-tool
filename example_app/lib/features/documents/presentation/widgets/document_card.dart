/// StarNote Document Card
///
/// Doküman kartı widget'ı. Thumbnail, başlık, tarih gösterir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/document_thumbnail_painter.dart';

class DocumentCard extends ConsumerWidget {
  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMorePressed;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isInTrash;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onMorePressed,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isInTrash = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _handleLongPress(ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildThumbnailCard()),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _buildInfoSection(),
          ),
        ],
      ),
    );
  }

  void _handleLongPress(WidgetRef ref) {
    if (!isSelectionMode) {
      ref.read(selectionModeProvider.notifier).state = true;
      ref.read(selectedDocumentsProvider.notifier).state = {document.id};
    } else {
      onLongPress?.call();
    }
  }

  Widget _buildThumbnailCard() {
    return Container(
      decoration: BoxDecoration(
        color: DocumentPaperColors.fromName(document.paperColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.outlineLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? null : AppShadows.sm,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm - 1),
            child: _buildThumbnail(),
          ),
          if (isSelectionMode && isSelected) _buildSelectionOverlay(),
          if (isSelectionMode)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: DocumentSelectionCheckbox(isSelected: isSelected),
            ),
          if (!isSelectionMode)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: DocumentFavoriteButton(
                isFavorite: document.isFavorite,
                onTap: onFavoriteToggle,
              ),
            ),
          if (document.pageCount > 1)
            Positioned(
              bottom: AppSpacing.sm,
              right: AppSpacing.sm,
              child: DocumentPageCountBadge(count: document.pageCount),
            ),
          if (isInTrash && document.deletedAt != null)
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              child: DocumentDaysLeftBadge(deletedAt: document.deletedAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm - 1),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return GestureDetector(
      onTap: onMorePressed,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DocumentDateFormatter.format(document.updatedAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (onMorePressed != null)
            const Icon(
              Icons.keyboard_arrow_down,
              size: AppIconSize.md,
              color: AppColors.textTertiaryLight,
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (document.hasCover && document.coverId != null) {
      final cover = core.CoverRegistry.byId(document.coverId!);
      if (cover != null) {
        return CoverPreviewWidget(
          cover: cover,
          title: document.title,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    if (document.documentType == core.DocumentType.pdf ||
        document.documentType == core.DocumentType.image) {
      return DocumentPreview(document: document);
    }
    return _buildTemplatePlaceholder();
  }

  Widget _buildTemplatePlaceholder() {
    if (document.documentType == core.DocumentType.notebook) {
      return Stack(
        children: [
          CustomPaint(
            painter: DocumentThumbnailPainter(document.templateId),
            size: Size.infinite,
          ),
          _buildSpiralBinding(),
        ],
      );
    }
    return CustomPaint(
      painter: DocumentThumbnailPainter(document.templateId),
      size: Size.infinite,
    );
  }

  Widget _buildSpiralBinding() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 16,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.textPrimaryLight.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (_) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(left: 3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

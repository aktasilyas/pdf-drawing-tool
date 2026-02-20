import 'dart:typed_data';
import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:drawing_ui/drawing_ui.dart' show ThumbnailGenerator;
import 'package:flutter/material.dart' hide Page;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';

/// Card widget for a trashed page, displayed in the trash view.
/// Renders the actual page content (strokes, shapes, background) as thumbnail.
class TrashedPageCard extends StatefulWidget {
  final TrashedPage trashedPage;
  final VoidCallback onTap;

  const TrashedPageCard({
    super.key,
    required this.trashedPage,
    required this.onTap,
  });

  @override
  State<TrashedPageCard> createState() => _TrashedPageCardState();
}

class _TrashedPageCardState extends State<TrashedPageCard> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final page = Page.fromJson(widget.trashedPage.pageData);
      final data = await ThumbnailGenerator.generate(
        page,
        width: 150,
        height: 200,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildThumbnailCard(context)),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: _buildInfoSection(context),
        ),
      ],
    );
  }

  Widget _buildThumbnailCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: outlineColor),
          boxShadow: AppShadows.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Page thumbnail
            Positioned.fill(child: _buildThumbnailContent(isDark)),
            // Page number badge
            _buildPageBadge(isDark),
            // Days left badge
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              child: DocumentDaysLeftBadge(
                deletedAt: widget.trashedPage.deletedAt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
      );
    }

    if (_thumbnailData != null) {
      return Image.memory(
        _thumbnailData!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(isDark),
      );
    }

    return _buildFallbackIcon(isDark);
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.description_outlined,
        size: 40,
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
    );
  }

  Widget _buildPageBadge(bool isDark) {
    return Positioned(
      top: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          'Sayfa ${widget.trashedPage.originalPageIndex + 1}',
          style: AppTypography.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return GestureDetector(
      onTap: widget.onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trashedPage.sourceDocumentTitle,
                  style:
                      AppTypography.titleMedium.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Sayfa ${widget.trashedPage.originalPageIndex + 1}  •  ${DocumentDateFormatter.format(widget.trashedPage.deletedAt)}',
                  style: AppTypography.caption.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: AppIconSize.md,
            color: textTertiary,
          ),
        ],
      ),
    );
  }
}

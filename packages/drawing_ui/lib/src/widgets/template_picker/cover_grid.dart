import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/cover_preview_widget.dart';

/// Kapak seçim grid'i — Kapak tab'ında kullanılır.
class CoverGrid extends StatelessWidget {
  final List<Cover> covers;
  final Cover? selectedCover;
  final ValueChanged<Cover> onCoverSelected;

  const CoverGrid({
    super.key,
    required this.covers,
    this.selectedCover,
    required this.onCoverSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 6 : 4;
        const spacing = 8.0;
        final childAspectRatio = isTablet ? 0.7 : 0.68;

        return GridView.builder(
          padding: const EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: covers.length,
          itemBuilder: (context, index) {
            final cover = covers[index];
            final isSelected = selectedCover?.id == cover.id;

            return _CoverCard(
              cover: cover,
              isSelected: isSelected,
              onTap: () => onCoverSelected(cover),
            );
          },
        );
      },
    );
  }
}

class _CoverCard extends StatelessWidget {
  final Cover cover;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CoverCard({
    required this.cover,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CoverPreviewWidget(
                cover: cover,
                showBorder: false,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            if (cover.isPremium)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: PhosphorIcon(StarNoteIcons.lock,
                      size: 12, color: cs.onSurfaceVariant),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      cs.surface.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(7)),
                ),
                child: Text(
                  cover.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: cs.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(StarNoteIcons.check,
                      size: 10, color: cs.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
